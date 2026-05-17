import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show protected;
import 'package:uuid/uuid.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/id_remap_dao.dart';
import 'package:admin/data/db/dao/outbox_dao.dart';
import 'package:admin/data/db/dao/sync_state_dao.dart';

/// Shared outbox + id-remap + cursor mechanics. Concrete repositories
/// (`ClientRepository`, `ProductRepository`, ...) extend this with their
/// entity-specific data movement (API → Drift → domain).
///
/// `TDomain` is the clean domain model the UI consumes (`Client`,
/// `Product`, …). `TApi` is the API DTO returned by the server endpoint
/// for this entity (`ClientApi`, `ProductApi`, …). Generics let the sync
/// dispatcher pass typed responses into [applyCreateResponse] /
/// [applyUpdateResponse] without per-entity casts.
///
/// The `is_dirty` flag is local-only — `<Entity>.fromApi(...)` defaults
/// it to `false`, so concrete repos must overlay the row's value when
/// reading from Drift (see `ClientRepository._fromRow`). Without that
/// overlay an unsaved edit looks clean after app restart.
abstract class BaseEntityRepository<TDomain, TApi> {
  BaseEntityRepository({
    required this.db,
    required this.entityType,
    this.uuid = const Uuid(),
    DateTime Function()? now,
    this.onEnqueued,
    Set<MutationKind> requiresPasswordFor = const {},
  }) : _now = now ?? DateTime.now,
       _passwordRequiredKinds = requiresPasswordFor;

  final AppDatabase db;
  final EntityType entityType;
  final Uuid uuid;
  final DateTime Function() _now;
  final Set<MutationKind> _passwordRequiredKinds;

  /// Invoked fire-and-forget after [enqueueMutation] writes an outbox row.
  /// Wired by DI to `SyncRepository.drainOnce` so the row gets drained
  /// immediately when online instead of sitting until the next explicit
  /// trigger (company switch, app resume, etc.). Tests leave it null.
  final void Function(String companyId)? onEnqueued;

  OutboxDao get _outbox => db.outboxDao;
  IdRemapDao get _idRemap => db.idRemapDao;
  SyncStateDao get _syncState => db.syncStateDao;

  /// In-flight + negative-result guards for [ensureLoadedTemplate], so the
  /// N rows referencing the same uncached entity issue one network fetch
  /// and a 404 / deleted id isn't re-fetched on every rebuild this session.
  final Map<String, Future<void>> _ensureInFlight = {};
  final Set<String> _ensureMissing = {};

  /// API path segment in the EntityType registry sense, used by the sync
  /// engine to know which API to call. Concrete repos override.
  String get entityTypeName => entityType.name;

  /// Whether the given mutation requires the user's password (forces the
  /// outbox row's `requiresPassword=true`). Read from the set passed to
  /// the constructor — pass `requiresPasswordFor: const {MutationKind.delete,
  /// MutationKind.purge, ...}` in the concrete repo's `super(...)` call.
  /// Settings-only / read-only entities can omit it (defaults to empty).
  bool requiresPasswordFor(MutationKind kind) =>
      _passwordRequiredKinds.contains(kind);

  /// Resolve `maybeTempId` through `id_remap`. If the id isn't a tmp id (or
  /// no remap exists), the input is returned unchanged. Used by `watch(id)`
  /// so an open detail screen survives a tmp→real swap.
  Future<String> resolveId(String maybeTempId) async {
    if (!maybeTempId.startsWith('tmp_')) return maybeTempId;
    final real = await _idRemap.resolve(
      entityType: entityTypeName,
      tempId: maybeTempId,
    );
    return real ?? maybeTempId;
  }

  /// Enqueue an outbox row. The caller has already written the local
  /// optimistic state to Drift; this just registers the pending sync.
  ///
  /// The drain kick (`onEnqueued`, typically `sync.drainOnce`) is scheduled
  /// on the next event-loop iteration via `Future(() => ...)` so it runs
  /// *after* any `db.transaction(...)` wrapping this call has committed —
  /// otherwise `nextReady`'s SELECT either races the commit or queues
  /// behind the still-open transaction, and the row we just INSERTed sits
  /// at `state=pending, attempts=0` until the next user-driven drain
  /// trigger. `Future.microtask` / `scheduleMicrotask` aren't enough:
  /// microtasks run before timers and can fire while the transaction is
  /// mid-commit.
  ///
  /// The schedule call is wrapped in `Zone.root.run(...)` so the deferred
  /// callback runs in the root zone — without this, a transactional caller
  /// would propagate Drift's `#drift_transaction` zone value into the
  /// timer callback, and the drain's `nextReady` would route through the
  /// now-closed transaction executor and silently return no rows.
  Future<int> enqueueMutation({
    required String companyId,
    required String entityId,
    required MutationKind kind,
    required Map<String, dynamic> payload,
    String? batchId,
  }) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final id = await _outbox.enqueue(
      OutboxCompanion.insert(
        companyId: companyId,
        entityType: entityTypeName,
        entityId: entityId,
        mutationKind: kind.wireName,
        payload: jsonEncode(payload),
        idempotencyKey: uuid.v4(),
        nextAttemptAt: nowMs,
        createdAt: nowMs,
        requiresPassword: requiresPasswordFor(kind)
            ? const Value(true)
            : const Value.absent(),
      ),
    );
    final kick = onEnqueued;
    if (kick != null) {
      // Escape any wrapping db.transaction() zone — see the method doc.
      Zone.root.run(() {
        unawaited(Future(() => kick(companyId)));
      });
    }
    return id;
  }

  /// Generate a fresh `tmp_<uuid>` id for an offline-created entity.
  String mintTempId() => 'tmp_${uuid.v4()}';

  /// Enqueue an `archive` mutation. The optimistic local state is set
  /// when the user invokes the action — typically via a
  /// `services.<entity>.archive(...)` call from a list-row popup or
  /// detail-screen action. The dispatcher hits `DELETE /entity/{id}?action=archive`
  /// on drain.
  Future<void> archive({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.archive,
        payload: {'id': id},
      );

  /// Enqueue a `restore` mutation. Inverse of [archive] — un-archives a row.
  Future<void> restore({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.restore,
        payload: {'id': id},
      );

  /// Enqueue a `delete` mutation. Password-gated for entities that opted
  /// into it via the constructor's `requiresPasswordFor:` set — the outbox
  /// row gets `requiresPassword=true` and the sync engine prompts via
  /// `ConfirmPasswordSheet`.
  Future<void> delete({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.delete,
        payload: {'id': id},
      );

  /// Enqueue a `purge` mutation. Irreversible — the dispatcher hard-deletes
  /// the local row via `applyPurgeResponse` after the server confirms.
  /// Password-gated for entities that opted in.
  Future<void> purge({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.purge,
        payload: {'id': id},
      );

  /// Called by the sync engine after a successful `create` round-trip:
  /// remember the temp → real id remap and rewrite any pending outbox
  /// payloads that referenced the temp id.
  Future<void> recordCreateSuccess({
    required String companyId,
    required String tempId,
    required String realId,
  }) async {
    if (tempId == realId) return;
    final nowMs = _now().millisecondsSinceEpoch;
    await db.transaction(() async {
      await _idRemap.remember(
        entityType: entityTypeName,
        tempId: tempId,
        realId: realId,
        now: nowMs,
      );
      await _outbox.rewriteTempIdInPayloads(
        companyId: companyId,
        entityType: entityTypeName,
        tempId: tempId,
        realId: realId,
      );
    });
  }

  /// Shared shape for `applyCreateResponse` implementations. Mirrors the
  /// three-step contract every CRUD repo (Client / Product / Task / …) shares:
  ///   1. Upsert the new row under the real id (via the [upsert] callback).
  ///   2. Delete the tmp row (if `realId != tempId`) via [deleteById].
  ///   3. Call [recordCreateSuccess] so the id-remap is recorded and pending
  ///      outbox payloads referencing the tmp id are rewritten.
  ///
  /// All three steps run inside a single transaction. Concrete repos call
  /// this from their [applyCreateResponse] override, supplying the typed
  /// dao calls and the per-entity `_apiToCompanion` projection.
  @protected
  Future<void> applyCreateResponseTemplate<TCompanion>({
    required String companyId,
    required String tempId,
    required String realId,
    required TCompanion companion,
    required Future<void> Function(TCompanion) upsert,
    required Future<void> Function(String id) deleteById,
  }) async {
    await db.transaction(() async {
      await upsert(companion);
      if (realId != tempId) {
        await deleteById(tempId);
      }
      await recordCreateSuccess(
        companyId: companyId,
        tempId: tempId,
        realId: realId,
      );
    });
  }

  /// Sync engine entry point for "the server accepted our `create` and
  /// returned the real entity." Concrete repos override and:
  ///   1. Upsert the new row under the real id.
  ///   2. Delete the tmp row (if `realId != tempId`).
  ///   3. Call [recordCreateSuccess] to remap and rewrite pending payloads.
  /// All three steps run inside a single transaction.
  ///
  /// Settings-only entities (e.g. company) that have no create flow can
  /// leave this as the default — the dispatcher never calls it.
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required TApi serverResponse,
  }) => throw UnsupportedError(
    '$runtimeType does not support create — entity $entityTypeName is '
    'settings-only or read-only.',
  );

  /// Sync engine entry point for "the server accepted our `update` /
  /// `archive` / `restore` and returned the canonical entity." Concrete
  /// repos upsert the row with `is_dirty=false`.
  Future<void> applyUpdateResponse({
    required String companyId,
    required TApi serverResponse,
  }) => throw UnsupportedError(
    '$runtimeType does not implement applyUpdateResponse — every CRUD '
    'entity must override this.',
  );

  /// Sync engine entry point for "the server accepted our `delete`."
  /// Concrete repos mark the local row as `is_deleted=true` so the list
  /// hides it immediately, without waiting for a pull-to-refresh.
  ///
  /// Settings-only entities that have no delete flow can leave this as
  /// the default — the dispatcher never calls it.
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) => throw UnsupportedError(
    '$runtimeType does not support delete — entity $entityTypeName is '
    'settings-only or read-only.',
  );

  /// Sync engine entry point for "the server accepted our `purge`."
  /// Concrete repos hard-delete the local row — purge is irreversible
  /// and the server has forgotten the entity, so the local copy should
  /// be gone too (not just flagged `is_deleted=true` the way
  /// [applyDeleteResponse] does).
  ///
  /// Entities that haven't wired purge can leave this as the default —
  /// the dispatcher only reaches here when an outbox row of kind
  /// [MutationKind.purge] exists, which their UI can't enqueue today.
  Future<void> applyPurgeResponse({
    required String companyId,
    required String id,
  }) => throw UnsupportedError(
    '$runtimeType does not support purge — entity $entityTypeName has '
    'not wired the purge flow.',
  );

  /// Translate the requested UI [EntityState]s into server query params for
  /// the list endpoint (e.g. `{'client_status': 'archived,deleted'}`).
  /// Default returns empty — the server's defaults already include active
  /// rows, so override only when archived/deleted need explicit opt-in.
  @protected
  Map<String, String> stateQueryParams(Set<EntityState> states) => const {};

  /// Watch a single row by a *real* (non-tmp) id, mapping Drift rows to the
  /// domain model. Concrete repos implement this with their DAO and the
  /// private `_fromRow` overlay that re-applies local-only flags like
  /// `is_dirty`. Called by [watch] and [watchByTempId].
  @protected
  Stream<TDomain?> watchByRealId({
    required String companyId,
    required String id,
  });

  /// Watch a single row by id. The id may be a tmp id; we transparently
  /// resolve through `id_remap` so an open detail screen survives the swap
  /// the sync engine makes after a successful create — even when the swap
  /// happens **while** the screen is open.
  Stream<TDomain?> watch({required String companyId, required String id}) {
    if (!id.startsWith('tmp_')) {
      return watchByRealId(companyId: companyId, id: id);
    }
    return watchByTempId(companyId: companyId, tempId: id);
  }

  /// Drift's `watchById(tempId)` goes blank when the sync engine deletes the
  /// tmp row mid-swap. To keep the detail screen alive, we listen to
  /// `id_remap` in parallel and re-subscribe to the new id when it lands.
  @protected
  Stream<TDomain?> watchByTempId({
    required String companyId,
    required String tempId,
  }) {
    final controller = StreamController<TDomain?>();
    StreamSubscription<TDomain?>? rowSub;
    StreamSubscription<String?>? remapSub;
    String? currentId;

    void subscribeToRow(String resolved) {
      if (resolved == currentId) return;
      currentId = resolved;
      rowSub?.cancel();
      rowSub = watchByRealId(
        companyId: companyId,
        id: resolved,
      ).listen(controller.add, onError: controller.addError);
    }

    controller.onListen = () async {
      final initial = await resolveId(tempId);
      subscribeToRow(initial);
      remapSub = _idRemap
          .watchRealId(entityType: entityTypeName, tempId: tempId)
          .listen((realId) {
            if (realId != null) subscribeToRow(realId);
          });
    };
    controller.onCancel = () async {
      await rowSub?.cancel();
      await remapSub?.cancel();
    };

    return controller.stream;
  }

  /// Advance the keyset cursor after upserting a page.
  Future<void> advanceCursor({
    required String companyId,
    required int updatedAt,
    required String id,
    bool wasFullSync = false,
  }) {
    return _syncState.writeCursor(
      companyId: companyId,
      entityType: entityTypeName,
      updatedAt: updatedAt,
      id: id,
      now: _now().millisecondsSinceEpoch,
      wasFullSync: wasFullSync,
    );
  }

  /// Shared shape for `ensurePageLoaded` across every paginated repo (CRUD
  /// + bundled). Encodes the contract every list-fetching repo has shared
  /// independently:
  ///   1. Read cursor (or skip when `ignoreCursor`).
  ///   2. Merge `stateQueryParams(states)` + per-call [staticFilters] + the
  ///      open-ended [extraFilters] map (each set comma-joined, keys sorted
  ///      deterministically) into a flat `Map<String, String>`.
  ///   3. Call [listCall] with cursor + filters.
  ///   4. Empty page → return false (no more rows).
  ///   5. Upsert via [upsert] with `{id → companion}` projected via [idOf] +
  ///      [toCompanion].
  ///   6. Advance the cursor when the server returned a non-null
  ///      `(cursorUpdatedAt, cursorId)`. `wasFullSync` mirrors the
  ///      established convention: true only when this call ignored the
  ///      cursor AND we're on page 1 (a fresh full-sync sweep).
  ///   7. Return `apiRows.length >= pageSize` — more pages remain when the
  ///      server filled the page.
  ///
  /// [listCall] accepts the typed `*Api.list` tear-off directly (the
  /// signature matches `BaseEntityApi.list`). [itemsOf] projects the inner
  /// array out of the `*ListApi` wrapper (typically `(l) => l.data`). The
  /// extra `TList` generic lets call sites pass `api.list` without a
  /// wrapping closure.
  @protected
  Future<bool> ensurePageLoadedTemplate<TList, TItem, TCompanion>({
    required String companyId,
    required int page,
    required int pageSize,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    Map<String, Set<String>> extraFilters = const {},
    Map<String, String> staticFilters = const {},
    bool ignoreCursor = false,
    required Future<({TList data, int? cursorUpdatedAt, String? cursorId})>
    Function({
      required int page,
      int perPage,
      String? search,
      int? sinceUpdatedAt,
      String? sinceId,
      Map<String, String> filters,
    })
    listCall,
    required List<TItem> Function(TList) itemsOf,
    required String Function(TItem) idOf,
    required TCompanion Function(TItem) toCompanion,
    required Future<void> Function(Map<String, TCompanion> byId) upsert,
  }) async {
    final cursor = ignoreCursor
        ? null
        : await _syncState.read(
            companyId: companyId,
            entityType: entityTypeName,
          );

    final filters = <String, String>{
      ...stateQueryParams(states),
      ...staticFilters,
      for (final entry in extraFilters.entries)
        if (entry.value.isNotEmpty)
          entry.key: (entry.value.toList()..sort()).join(','),
    };

    final result = await listCall(
      page: page,
      perPage: pageSize,
      search: search,
      sinceUpdatedAt: cursor?.updatedAt,
      sinceId: cursor?.id,
      filters: filters,
    );

    final apiRows = itemsOf(result.data);
    if (apiRows.isEmpty) return false;

    // Server-refresh: skip ids whose existing local row has is_dirty=true,
    // so a paged refresh doesn't clobber the user's pending offline edit.
    await upsert({for (final a in apiRows) idOf(a): toCompanion(a)});

    if (result.cursorUpdatedAt != null && result.cursorId != null) {
      await advanceCursor(
        companyId: companyId,
        updatedAt: result.cursorUpdatedAt!,
        id: result.cursorId!,
        wasFullSync: ignoreCursor && page == 1,
      );
    }
    return apiRows.length >= pageSize;
  }

  /// Lazily hydrate a single referenced row into Drift on a cache miss —
  /// e.g. a `*NameLabel` watch yielded null because the vendor an expense
  /// references isn't on the prefetched first page. Network-fetch by id
  /// via [fetch] (`api.get`), then upsert via the **same** projection the
  /// repo's `ensurePageLoaded` uses ([idOf] + [toCompanion] + [upsert]).
  ///
  /// Safe to call from many rows / every rebuild: short-circuits when the
  /// row is already cached, coalesces concurrent calls for the same id,
  /// skips empty / `tmp_` (local-only) ids, and negative-caches ids that
  /// fail so a deleted/unknown reference doesn't hammer the network. This
  /// is a read-only hydrate — no outbox / `is_dirty` semantics.
  @protected
  Future<void> ensureLoadedTemplate<TItem, TCompanion>({
    required String companyId,
    required String id,
    required Future<TItem> Function(String id) fetch,
    required String Function(TItem) idOf,
    required TCompanion Function(TItem) toCompanion,
    required Future<void> Function(Map<String, TCompanion> byId) upsert,
  }) {
    if (id.isEmpty || id.startsWith('tmp_') || _ensureMissing.contains(id)) {
      return Future<void>.value();
    }
    return _ensureInFlight[id] ??= () async {
      try {
        final cached = await watch(companyId: companyId, id: id).first;
        if (cached != null) return;
        final item = await fetch(id);
        await upsert({idOf(item): toCompanion(item)});
      } catch (_) {
        _ensureMissing.add(id);
      } finally {
        // `remove` returns the in-flight future itself; awaiting it here
        // would deadlock, so explicitly mark it unawaited.
        unawaited(_ensureInFlight.remove(id));
      }
    }();
  }

  /// Shared shape for bundled-entity `applyBundle` implementations. Encodes
  /// the contract every bundled repo (task_statuses, payment_terms,
  /// company_gateways, tax_rates, expense_categories, designs, payment_links)
  /// shares:
  ///   1. Empty bundle → no-op (preserves the existing cursor).
  ///   2. Project each API item to a Drift companion via [toCompanion].
  ///   3. Inside one transaction: invoke [upsert] with the projected map,
  ///      then advance the keyset cursor to the bundle's max `updated_at`
  ///      and the corresponding id.
  ///
  /// [wasFullSync] (default true — login / forced / first refresh) marks the
  /// cursor as a complete snapshot so a later `ensurePageLoaded`
  /// short-circuits its first page fetch. On a *delta* refresh
  /// (`current_company=true`, `wasFullSync: false`) the bundle is **partial**:
  ///   * the cursor is advanced but **not** marked full (so pagination still
  ///     back-fills rows the delta didn't carry), and
  ///   * it is never *regressed* — a delta whose max `updated_at` is behind
  ///     the cursor we already hold leaves the cursor untouched (the upsert
  ///     still runs, so archived/deleted flags from the delta still land).
  ///
  /// Soft-delete note: this is upsert-only and never deletes. A delta returns
  /// archived/deleted rows with their flags set; bundled-entity `watchAll`
  /// DAOs already filter `archived_at`/`is_deleted`, so display stays correct
  /// while tombstones accumulate locally — matching legacy admin-portal
  /// behavior (it keeps them too, filtered by `isActive`). If local growth
  /// ever matters, prune in a separate maintenance pass, never here.
  ///
  /// Why a callback for [upsert] instead of a DAO reference: bundled DAOs
  /// disagree on the upsert signature today — most take `(companyId:, byId:
  /// {String: Companion})` and use `upsertAllPreservingDirty` so pending
  /// offline edits survive a refresh, while a couple take a flat companion
  /// list via plain `upsertAll`. Pass-through preserves the existing
  /// per-entity choice without forcing alignment here.
  @protected
  Future<void> applyBundleUpsertOnly<TItem, TCompanion>({
    required String companyId,
    required List<TItem> bundle,
    required String Function(TItem) idOf,
    required int Function(TItem) updatedAtOf,
    required TCompanion Function(TItem) toCompanion,
    required Future<void> Function(Map<String, TCompanion> byId) upsert,
    bool wasFullSync = true,
  }) async {
    if (bundle.isEmpty) return;
    final byId = <String, TCompanion>{
      for (final a in bundle) idOf(a): toCompanion(a),
    };
    var maxUpdatedAt = 0;
    String? lastId;
    for (final a in bundle) {
      final updatedAt = updatedAtOf(a);
      if (updatedAt > maxUpdatedAt) {
        maxUpdatedAt = updatedAt;
        lastId = idOf(a);
      }
    }
    await db.transaction(() async {
      // Always upsert (preserving dirty) — even when we skip the cursor
      // write below, the rows (incl. archived/deleted flags) must land.
      await upsert(byId);
      if (lastId == null) return;
      if (wasFullSync) {
        await advanceCursor(
          companyId: companyId,
          updatedAt: maxUpdatedAt,
          id: lastId,
          wasFullSync: true,
        );
        return;
      }
      // Delta: never regress the keyset cursor and never claim a full sync.
      final existing = await _syncState.read(
        companyId: companyId,
        entityType: entityTypeName,
      );
      if (maxUpdatedAt < (existing.updatedAt ?? 0)) return;
      await advanceCursor(
        companyId: companyId,
        updatedAt: maxUpdatedAt,
        id: lastId,
        wasFullSync: false,
      );
    });
  }
}
