import 'dart:async';

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

  /// True while a [drainOnce] is mid-flight. Read via the [_activeDrain]
  /// future so [cancel] can await whatever's in progress.
  Future<void>? _activeDrain;

  /// Signal checked between outbox rows. [cancel] sets it; [drainOnce]
  /// clears it on entry so the next drain starts fresh.
  bool _cancelRequested = false;

  Future<void> dispose() => _events.close();

  /// Stop a running [drainOnce] (between rows — an in-flight HTTP request is
  /// allowed to settle so the server's view doesn't diverge from ours) and
  /// await the iteration. Safe to call when no drain is active.
  ///
  /// Used by [AuthRepository.logout] so the local DB wipe doesn't race a
  /// pending mutation that's still using the soon-to-be-revoked credentials.
  Future<void> cancel() async {
    _cancelRequested = true;
    final f = _activeDrain;
    if (f != null) {
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

  /// Delete every non-`dead` outbox row for [companyId]. Used by the
  /// "Discard" branch of the confirm-before-switch dialog.
  Future<int> discardPendingFor(String companyId) =>
      db.outboxDao.deletePendingForCompany(companyId);

  /// Synchronous-ish entry point for the shell: drain whatever is due now
  /// for [companyId]. Returns the number of rows successfully dispatched.
  /// Errors propagate so the caller can show a SnackBar.
  Future<int> flushNow({required String companyId}) =>
      drainOnce(companyId: companyId);

  /// Drain all due `pending` rows for [companyId] in one pass. Returns the
  /// number of rows successfully dispatched (200-class result). Stops early
  /// if [cancel] is invoked mid-iteration.
  Future<int> drainOnce({required String companyId}) {
    _cancelRequested = false;
    final future = _drainOnceImpl(companyId);
    // Track as void/error-swallowing so [cancel] can await without caring
    // about the int result or which exception (if any) was raised.
    _activeDrain = future.then((_) => null, onError: (_) => null);
    return future;
  }

  Future<int> _drainOnceImpl(String companyId) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final rows = await db.outboxDao.nextReady(companyId: companyId, now: nowMs);
    var successes = 0;
    for (final row in rows) {
      if (_cancelRequested) break;
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
    } on PasswordRequiredException {
      _log.info('Password required for ${row.entityType}/${row.entityId}');
      // Leave the row pending; the UI prompts the user and the sync engine
      // retries once the password cache is populated.
      await db.outboxDao.scheduleRetry(
        id: row.id,
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
      await _retryWithBackoff(row, e.message, e.statusCode);
      return false;
    } on ClientTooOldException catch (e) {
      // The UI surfaces a "please update" screen elsewhere; sync stops.
      await db.outboxDao.scheduleRetry(
        id: row.id,
        nextAttemptAt:
            _now().millisecondsSinceEpoch +
            const Duration(hours: 1).inMilliseconds,
        error: 'Client too old: needs ${e.minRequiredVersion}',
        statusCode: null,
      );
      return false;
    }
  }

  Future<void> _retryWithBackoff(OutboxRow row, String error, int? code) async {
    final nextAttempt = row.attempts + 1;
    if (nextAttempt >= kMaxAttempts) {
      await _markDead(row, error, code);
      return;
    }
    final delay =
        kBackoffSchedule[nextAttempt.clamp(0, kBackoffSchedule.length - 1)];
    await db.outboxDao.scheduleRetry(
      id: row.id,
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
        ),
      );
    }
  }

  EntityType _entityTypeFrom(EntityType t) => t;
}
