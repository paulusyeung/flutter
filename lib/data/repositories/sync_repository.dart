import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_event.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/api_exception.dart';

final _log = Logger('SyncRepository');

/// Exponential backoff for transient failures. After the last entry, one
/// more attempt past the schedule's tail before the row is marked dead.
const List<Duration> kBackoffSchedule = [
  Duration(seconds: 5),
  Duration(seconds: 30),
  Duration(minutes: 2),
  Duration(minutes: 10),
];

/// Total attempts (initial + retries) before a row is marked dead.
const int kMaxAttempts = 5;

/// Terminal state observed by [SyncRepository.awaitRow] for one outbox row.
enum SyncRowOutcome {
  /// Row was successfully drained (server returned 2xx; the row was deleted).
  success,

  /// Row was rejected by the server with a 422 — caller should surface the
  /// returned `fieldErrors` inline on the edit form.
  validationFailed,

  /// Row hit a non-validation failure (5xx, network, dead row with a non-422
  /// status). Caller surfaces [SyncRowResult.message] as a submit-level error
  /// and keeps the form open.
  serverError,

  /// [SyncRepository.awaitRow] hit its caller-supplied timeout while the row
  /// was still pending / in-flight. Caller pops the form optimistically and
  /// lets the outbox keep draining in the background.
  timeout,
}

/// Result of [SyncRepository.awaitRow]. [fieldErrors] is populated only for
/// [SyncRowOutcome.validationFailed]; [message] / [statusCode] are surfaced
/// on transient and validation failures so the form can show an error.
class SyncRowResult {
  const SyncRowResult({
    required this.outcome,
    this.fieldErrors = const <String, List<String>>{},
    this.message,
    this.statusCode,
  });

  final SyncRowOutcome outcome;
  final Map<String, List<String>> fieldErrors;
  final String? message;
  final int? statusCode;
}

/// Long-running consumer of the outbox. Drains rows in FIFO order per
/// `(company, entity_type)`, dispatches them via the [EntityRegistry], and
/// emits typed [SyncEvent]s for the UI shell to react to.
///
/// In M1 we expose [drainOnce] for direct invocation; the long-running
/// scheduling (connectivity, foreground-resume, due-time timers) is wired
/// up in `app/di.dart` once `AuthRepository` lands in M1.8.
class SyncRepository {
  SyncRepository({
    required this.db,
    required this.registry,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final EntityRegistry registry;
  final DateTime Function() _now;

  final StreamController<SyncEvent> _events =
      StreamController<SyncEvent>.broadcast();

  Stream<SyncEvent> get events => _events.stream;

  /// Drains currently in flight, keyed by `companyId`. A second
  /// [drainOnce] call for the same company while a drain is running
  /// returns the existing future instead of starting a parallel one —
  /// otherwise the five auto-drain triggers (onEnqueued, connectivity,
  /// lifecycle, auth, dialog flush) would double-dispatch rows because
  /// `nextReady` filters by `state='pending'` only AFTER `markInFlight`
  /// is awaited. The Idempotency-Key header makes double-dispatch
  /// server-safe, but it's still wasted work we'd rather not do.
  final Map<String, Future<int>> _inFlight = {};

  /// Signal checked between outbox rows. [cancel] sets it; [drainOnce]
  /// clears it on entry so the next drain starts fresh.
  bool _cancelRequested = false;

  /// Outbox rows whose caller is synchronously surfacing the failure itself
  /// (an open edit form via [awaitRow], or any `awaitRow(callerWillDisplayFailure:
  /// true)` caller). [_markDead] tags such rows' [DeadEvent] with
  /// `handledByCaller: true` so the shell shows the error inline rather than
  /// popping a duplicate modal. A row drops out of the set the moment its
  /// `awaitRow` returns, so a *later* background death (e.g. after the form's
  /// online-save timeout popped the screen) is correctly treated as unhandled
  /// and does surface a modal.
  final Set<int> _callerDisplayedRows = {};

  Future<void> dispose() => _events.close();

  /// Stop a running [drainOnce] (between rows — an in-flight HTTP request is
  /// allowed to settle so the server's view doesn't diverge from ours) and
  /// await the iteration. Safe to call when no drain is active.
  ///
  /// Used by [AuthRepository.logout] so the local DB wipe doesn't race a
  /// pending mutation that's still using the soon-to-be-revoked credentials.
  Future<void> cancel() async {
    _cancelRequested = true;
    // Snapshot before awaiting — entries clean themselves up via the
    // `whenComplete` hook in [drainOnce], which would mutate the map
    // while we iterate.
    final pending = _inFlight.values.toList(growable: false);
    for (final f in pending) {
      try {
        await f;
      } catch (_) {
        // Errors are reported via events on the SyncEvent stream; here we
        // only care that the iteration has settled.
      }
    }
  }

  /// Count of non-`dead` outbox rows for [companyId]. Wraps the DAO so the
  /// UI shell doesn't reach into the database layer directly.
  Future<int> pendingCountFor(String companyId) =>
      db.outboxDao.pendingCountForCompany(companyId);

  /// Discard one outbox row. If it's a never-synced offline `create`
  /// (`tmp_` id, no `id_remap` entry yet) the orphaned local Drift record
  /// is also hard-deleted — with no outbox row it could never reach the
  /// server, so it would otherwise linger forever as a ghost. A row that's
  /// currently `in_flight` only has its outbox row dropped: its network
  /// attempt may be landing concurrently and would re-create the local row
  /// + write an `id_remap`, so ghost-deleting it would race that (TOCTOU).
  ///
  /// Returns `true` when the ghost path was taken (the local record was
  /// hard-deleted), so a caller showing that entity can navigate away.
  Future<bool> discardOutboxRow(int id) async {
    final row = await db.outboxDao.byId(id);
    if (row == null) return false;
    if (row.state == 'in_flight') {
      await db.outboxDao.deleteRow(id);
      return false;
    }
    final isGhostCreate =
        MutationKind.tryParse(row.mutationKind) == MutationKind.create &&
        row.entityId.startsWith('tmp_') &&
        await db.idRemapDao.resolve(
              entityType: row.entityType,
              tempId: row.entityId,
            ) ==
            null;
    if (!isGhostCreate) {
      await db.outboxDao.deleteRow(id);
      return false;
    }
    // Never synced: drop the ghost local row, then every outbox row for
    // that tmp entity (queued follow-up update/delete rows are meaningless
    // once the entity is gone). `deleteAllForEntity` also removes `row`.
    await registry
        .byWireName(row.entityType)
        ?.dispatcher
        .deleteLocalRecord(companyId: row.companyId, id: row.entityId);
    await db.outboxDao.deleteAllForEntity(
      companyId: row.companyId,
      entityType: row.entityType,
      entityId: row.entityId,
    );
    return true;
  }

  /// Discard every `pending` outbox row for [companyId] — the "Discard"
  /// branch of the confirm-before-switch / logout dialog and the 409
  /// "discard mine" path. Each row routes through [discardOutboxRow] so a
  /// never-synced offline `create` also removes its orphaned local record;
  /// non-ghost rows behave exactly as the old blanket delete (dead /
  /// in_flight rows are untouched, matching `deletePendingForCompany`).
  Future<void> discardPendingFor(String companyId) async {
    final rows = await db.outboxDao.pendingRowsForCompany(companyId);
    for (final row in rows) {
      await discardOutboxRow(row.id);
    }
  }

  /// Synchronous-ish entry point for the shell: drain whatever is due now
  /// for [companyId]. Returns the number of rows successfully dispatched.
  /// Errors propagate so the caller can show a SnackBar.
  Future<int> flushNow({required String companyId}) =>
      drainOnce(companyId: companyId);

  /// Wait for one specific outbox row to reach a terminal state, kicking the
  /// drain as needed so the row actually gets dispatched. Used by
  /// `GenericEditViewModel.save()` when the device is online to flip the form
  /// into a synchronous UX: a 422 lands inline on the still-open form
  /// instead of via the dead-row banner after the route popped.
  ///
  /// The poll loop (default 200 ms) is the contract; events are nice-to-have.
  /// On every tick where the row is still `pending` and due, [drainOnce] is
  /// re-kicked — the single-flight `_inFlight` guard makes that idempotent.
  /// This closes the drain race where a prior in-flight drain snapshotted
  /// `nextReady` before our row was enqueued and finished without seeing it.
  ///
  /// Returns:
  ///   * [SyncRowOutcome.success] — row was deleted (server 2xx).
  ///   * [SyncRowOutcome.validationFailed] — row is `dead` with status 422.
  ///   * [SyncRowOutcome.serverError] — row is `dead` with a non-422 status,
  ///     or row is `pending` with a future `nextAttemptAt` (a backoff was
  ///     scheduled; surface the `lastError`).
  ///   * [SyncRowOutcome.timeout] — [timeout] elapsed with the row still
  ///     pending or in_flight; caller should fall back to background sync.
  Future<SyncRowResult> awaitRow({
    required int rowId,
    required String companyId,
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(milliseconds: 200),
    bool callerWillDisplayFailure = true,
  }) async {
    // Use a real wall-clock Stopwatch for the deadline — the injected `_now`
    // is fixed in unit tests (deterministic backoff math) so checking it
    // would never trip the timeout branch. The poll loop's `Future.delayed`
    // is already real-wall-time, so this just matches what the user actually
    // experiences.
    final stopwatch = Stopwatch()..start();
    // Claim the row so a death observed while we're actively polling is shown
    // by *this* caller (inline on the form / at the tap site) rather than also
    // by a duplicate shell modal. Released in the `finally` the instant we
    // return, so a *later* background death (e.g. after the online-save timeout
    // popped the screen) is treated as unhandled and does surface a modal.
    if (callerWillDisplayFailure) _callerDisplayedRows.add(rowId);
    // Kick the drain right away so an idle company starts processing without
    // waiting for the first poll. Subsequent kicks happen inside the loop.
    unawaited(drainOnce(companyId: companyId));
    try {
      while (true) {
        final row = await db.outboxDao.byId(rowId);
        if (row == null) {
          return const SyncRowResult(outcome: SyncRowOutcome.success);
        }
        if (row.state == 'dead') {
          if (row.lastStatusCode == 422) {
            return SyncRowResult(
              outcome: SyncRowOutcome.validationFailed,
              fieldErrors: _decodeFieldErrors(row.fieldErrorsJson),
              message: row.lastError,
              statusCode: row.lastStatusCode,
            );
          }
          return SyncRowResult(
            outcome: SyncRowOutcome.serverError,
            message: row.lastError ?? 'Save failed',
            statusCode: row.lastStatusCode,
          );
        }
        final nowMs = _now().millisecondsSinceEpoch;
        if (row.state == 'pending' && row.nextAttemptAt > nowMs) {
          // A retry has been scheduled into the future — this is a transient
          // server/network failure. Surface inline; the outbox will keep
          // retrying in the background per its backoff if the user navigates
          // away, but for now the form stays open with the error.
          return SyncRowResult(
            outcome: SyncRowOutcome.serverError,
            message: row.lastError ?? 'Connection lost',
            statusCode: row.lastStatusCode,
          );
        }
        if (stopwatch.elapsed >= timeout) {
          return const SyncRowResult(outcome: SyncRowOutcome.timeout);
        }
        // Pending and due, or in_flight. Re-kick drainOnce — if a prior drain
        // missed this row (it snapshotted nextReady before our enqueue), the
        // next pass picks it up. If a drain is already running, single-flight
        // makes this a no-op.
        if (row.state == 'pending') {
          unawaited(drainOnce(companyId: companyId));
        }
        await Future<void>.delayed(pollInterval);
      }
    } finally {
      _callerDisplayedRows.remove(rowId);
    }
  }

  Map<String, List<String>> _decodeFieldErrors(String? json) {
    if (json == null || json.isEmpty) return const <String, List<String>>{};
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) {
        return decoded.map(
          (k, v) => MapEntry(
            k.toString(),
            v is List ? v.map((e) => e.toString()).toList() : <String>[],
          ),
        );
      }
    } catch (_) {}
    return const <String, List<String>>{};
  }

  /// Drain all due `pending` rows for [companyId] in one pass. Returns the
  /// number of rows successfully dispatched (200-class result). Stops early
  /// if [cancel] is invoked mid-iteration.
  ///
  /// Single-flight per company: a second call while a drain is already
  /// running for the same company returns the existing future instead of
  /// starting a parallel one.
  Future<int> drainOnce({required String companyId}) {
    final existing = _inFlight[companyId];
    if (existing != null) return existing;
    _cancelRequested = false;
    final future = _drainOnceImpl(companyId);
    _inFlight[companyId] = future;
    // Use `whenComplete` so the slot is cleared whether the drain succeeded
    // or threw. The `identical` guard protects against a hypothetical
    // re-entrant overwrite (none today, but cheap insurance).
    future.whenComplete(() {
      if (identical(_inFlight[companyId], future)) {
        _inFlight.remove(companyId);
      }
    });
    return future;
  }

  /// Re-arm parked password-required rows for [companyId], then kick a drain.
  /// Called by the shell's password sheet after the user enters their password
  /// so the just-parked mutation retries immediately instead of waiting out
  /// its +1 min park (see the `PasswordRequiredException` handler).
  Future<void> retryPasswordRows({required String companyId}) async {
    await db.outboxDao.readyPasswordRows(
      companyId: companyId,
      now: _now().millisecondsSinceEpoch,
    );
    await drainOnce(companyId: companyId);
  }

  Future<int> _drainOnceImpl(String companyId) async {
    // Re-arm rows orphaned in `in_flight` by a prior interrupted pass (app
    // killed / process death between `markInFlight` and the catch handler).
    // `nextReady` only selects `pending`, so without this an orphaned row is
    // invisible forever. Safe here: `drainOnce` is single-flight per company
    // and rows are processed sequentially, so at drain-start no `in_flight`
    // row for this company is a live request — and the idempotency key makes a
    // re-send harmless regardless.
    await db.outboxDao.resetInFlightForCompany(companyId);
    final nowMs = _now().millisecondsSinceEpoch;
    final rows = await db.outboxDao.nextReady(companyId: companyId, now: nowMs);
    var successes = 0;
    for (final snapshot in rows) {
      if (_cancelRequested) break;
      // Re-read the row immediately before dispatch. An earlier CREATE in THIS
      // same pass may have remapped a tmp_ id -> real id inside this row's
      // payload/entityId (OutboxDao.rewriteTempIdInPayloads runs from
      // applyCreateResponse). Our `nextReady` snapshot predates that write, so
      // dispatching it as-is would send the stale tmp_ id — e.g. an offline
      // create + edit drained together would `PUT /invoices/tmp_xxx` -> 404 and
      // park the edit as a bogus conflict. byId() returns the post-remap row.
      final row = await db.outboxDao.byId(snapshot.id);
      if (row == null) continue; // deleted / superseded mid-pass
      final dispatched = await _attempt(row);
      if (dispatched) successes++;
    }
    return successes;
  }

  Future<bool> _attempt(OutboxRow row) async {
    final handlers = registry.byWireName(row.entityType);
    if (handlers == null) {
      _log.warning('No registry entry for ${row.entityType}; marking dead.');
      await _markDead(row, 'No dispatcher for entity type', null);
      return false;
    }
    final kind = MutationKind.tryParse(row.mutationKind);
    if (kind == null) {
      // Open-ended actions (e.g. `action:send_email`) aren't part of M1;
      // when M2 introduces them, this branch will route to a dedicated
      // action handler. For now, fail closed.
      _log.warning('Unknown mutation kind ${row.mutationKind}; marking dead.');
      await _markDead(row, 'Unknown mutation kind', null);
      return false;
    }

    await db.outboxDao.markInFlight(row.id);
    try {
      await handlers.dispatcher.dispatch(row: row, kind: kind);
      await db.outboxDao.deleteRow(row.id);
      return true;
    } on ValidationException catch (e) {
      _log.info('422 on ${row.entityType}/${row.entityId}: ${e.message}');
      await db.outboxDao.markDead(
        id: row.id,
        error: e.message,
        statusCode: 422,
        fieldErrorsJson: e.fieldErrors.isEmpty
            ? null
            : jsonEncode(e.fieldErrors),
      );
      _events.add(
        ValidationFailedEvent(
          entityType: _entityTypeFrom(handlers.type),
          entityId: row.entityId,
          fieldErrors: e.fieldErrors,
          message: e.message,
        ),
      );
      return false;
    } on ConflictException catch (e) {
      _log.info('409 on ${row.entityType}/${row.entityId}: ${e.message}');
      // Leave the row pending but parked far in the future. Auto-retrying
      // a 409 just re-hits the same conflict; the user has to resolve it
      // via the ConflictResolutionSheet, which either re-enqueues a fresh
      // mutation (and discards this row) or discards this row outright.
      // The 1-year delay is a safety valve in case the UI never resolves;
      // we don't want a stuck row to silently burn API quota.
      await db.outboxDao.scheduleRetry(
        id: row.id,
        attempts: row.attempts,
        nextAttemptAt:
            _now().millisecondsSinceEpoch +
            const Duration(days: 365).inMilliseconds,
        error: e.message,
        statusCode: 409,
      );
      _events.add(
        ConflictEvent(
          entityType: handlers.type,
          entityId: row.entityId,
          message: e.message,
        ),
      );
      return false;
    } on PlanRequiredException catch (e) {
      _log.info(
        'Plan upgrade required for ${row.entityType}/${row.entityId}: '
        '${e.message}',
      );
      // No amount of retrying upgrades the account. Mark dead so the
      // user sees the failure in the outbox screen and resolves it by
      // upgrading + re-enqueuing or discarding the row.
      await _markDead(row, e.message, 402);
      return false;
    } on PasswordRequiredException {
      _log.info('Password required for ${row.entityType}/${row.entityId}');
      // The server gates this mutation behind a password (e.g. a plain user
      // PUT). Upgrade the row so that once the user enters their password the
      // retry attaches X-API-PASSWORD-BASE64 — the dispatcher forwards
      // `row.requiresPassword`, and `api_client.mutate` only reads the cache
      // when it's true. Without this, a row enqueued with
      // requiresPassword=false would 412 forever.
      await db.outboxDao.updateRequiresPassword(id: row.id, value: true);
      // Leave the row pending; the UI prompts the user and the sync engine
      // retries once the password cache is populated.
      await db.outboxDao.scheduleRetry(
        id: row.id,
        attempts: row.attempts,
        nextAttemptAt:
            _now().millisecondsSinceEpoch +
            const Duration(minutes: 1).inMilliseconds,
        error: 'Password required',
        statusCode: 403,
      );
      _events.add(
        PasswordRequiredEvent(
          entityType: handlers.type,
          entityId: row.entityId,
        ),
      );
      return false;
    } on RateLimitedException catch (e) {
      final delay = e.retryAfter ?? const Duration(seconds: 30);
      await db.outboxDao.scheduleRetry(
        id: row.id,
        attempts: row.attempts,
        nextAttemptAt: _now().millisecondsSinceEpoch + delay.inMilliseconds,
        error: e.message,
        statusCode: 429,
      );
      return false;
    } on UnauthorizedException {
      // Auth layer is already handling logout — leave the row, it will
      // resume after re-login.
      await db.outboxDao.scheduleRetry(
        id: row.id,
        attempts: row.attempts,
        nextAttemptAt:
            _now().millisecondsSinceEpoch +
            const Duration(minutes: 1).inMilliseconds,
        error: 'Unauthorized',
        statusCode: 401,
      );
      return false;
    } on NetworkException catch (e) {
      await _retryWithBackoff(row, e.message, null);
      return false;
    } on ServerException catch (e) {
      // 4xx client errors are permanent: the identical request will keep
      // failing, so don't burn the full retry budget (≈13 min of backoff)
      // before the user hears about it — mark dead immediately so a `DeadEvent`
      // fires on the first attempt. 5xx (and anything else) stays on transient
      // backoff. The retry-worthy 4xx (401/403/412/404/409/422/429/402) are all
      // caught above; only genuinely-permanent codes (400, 405, 410, 415, …)
      // reach here.
      if (e.statusCode >= 400 && e.statusCode < 500) {
        await _markDead(row, e.message, e.statusCode);
      } else {
        await _retryWithBackoff(row, e.message, e.statusCode);
      }
      return false;
    } on ClientTooOldException catch (e) {
      // The UI surfaces a "please update" screen elsewhere; sync stops.
      await db.outboxDao.scheduleRetry(
        id: row.id,
        attempts: row.attempts,
        nextAttemptAt:
            _now().millisecondsSinceEpoch +
            const Duration(hours: 1).inMilliseconds,
        error: 'Client too old: needs ${e.minRequiredVersion}',
        statusCode: null,
      );
      return false;
    } on Object catch (e, st) {
      // Catch-all: anything not matched above (DemoModeException, a future
      // exception type, a non-API throw from inside a customAction) routes
      // to backoff. Without this, an unhandled throw leaves the row in
      // `in_flight` forever — `nextReady` only picks up `pending`, so the
      // row is invisible to subsequent drains.
      _log.warning(
        'Unhandled exception on ${row.entityType}/${row.entityId}',
        e,
        st,
      );
      await _retryWithBackoff(row, e.toString(), null);
      return false;
    }
  }

  Future<void> _retryWithBackoff(OutboxRow row, String error, int? code) async {
    final nextAttempt = row.attempts + 1;
    if (nextAttempt >= kMaxAttempts) {
      await _markDead(row, error, code);
      return;
    }
    // `nextAttempt` is the count of attempts including this one (1, 2, 3, …);
    // the schedule is the wait BEFORE attempt N+1, so index by `nextAttempt - 1`
    // — first failure (nextAttempt=1) uses kBackoffSchedule[0] = 5s, etc.
    final delay =
        kBackoffSchedule[(nextAttempt - 1).clamp(
          0,
          kBackoffSchedule.length - 1,
        )];
    await db.outboxDao.scheduleRetry(
      id: row.id,
      attempts: nextAttempt,
      nextAttemptAt: _now().millisecondsSinceEpoch + delay.inMilliseconds,
      error: error,
      statusCode: code,
    );
  }

  Future<void> _markDead(OutboxRow row, String error, int? code) async {
    await db.outboxDao.markDead(id: row.id, error: error, statusCode: code);
    final handlers = registry.byWireName(row.entityType);
    if (handlers != null) {
      _events.add(
        DeadEvent(
          entityType: handlers.type,
          entityId: row.entityId,
          message: error,
          statusCode: code,
          handledByCaller: _callerDisplayedRows.contains(row.id),
        ),
      );
    }
  }

  EntityType _entityTypeFrom(EntityType t) => t;
}
