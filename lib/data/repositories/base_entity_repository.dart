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
  }) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final EntityType entityType;
  final Uuid uuid;
  final DateTime Function() _now;

  /// Invoked fire-and-forget after [enqueueMutation] writes an outbox row.
  /// Wired by DI to `SyncRepository.drainOnce` so the row gets drained
  /// immediately when online instead of sitting until the next explicit
  /// trigger (company switch, app resume, etc.). Tests leave it null.
  final void Function(String companyId)? onEnqueued;

  OutboxDao get _outbox => db.outboxDao;
  IdRemapDao get _idRemap => db.idRemapDao;
  SyncStateDao get _syncState => db.syncStateDao;

  /// API path segment in the EntityType registry sense, used by the sync
  /// engine to know which API to call. Concrete repos override.
  String get entityTypeName => entityType.name;

  /// Whether the given mutation requires the user's password (forces the
  /// outbox row's `requiresPassword=true`). Defaults to false; override
  /// per-entity (Client defaults `delete` to true to match server policy).
  bool requiresPasswordFor(MutationKind kind) => false;

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
    onEnqueued?.call(companyId);
    return id;
  }

  /// Generate a fresh `tmp_<uuid>` id for an offline-created entity.
  String mintTempId() => 'tmp_${uuid.v4()}';

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
}
