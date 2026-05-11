import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../domain/entity_type.dart';
import '../../domain/sync/mutation.dart';
import '../db/app_database.dart';
import '../db/dao/id_remap_dao.dart';
import '../db/dao/outbox_dao.dart';
import '../db/dao/sync_state_dao.dart';

/// Shared outbox + id-remap + cursor mechanics. Concrete repositories
/// (`ClientRepository`, `InvoiceRepository`, ...) extend this with their
/// entity-specific data movement (API → Drift → domain).
///
/// The base class deliberately stays small — the value here is making
/// every entity's outbox semantics identical so the sync engine can drive
/// them all without entity-specific code paths.
abstract class BaseEntityRepository {
  BaseEntityRepository({
    required this.db,
    required this.entityType,
    this.uuid = const Uuid(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final EntityType entityType;
  final Uuid uuid;
  final DateTime Function() _now;

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
  }) {
    final nowMs = _now().millisecondsSinceEpoch;
    return _outbox.enqueue(
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
