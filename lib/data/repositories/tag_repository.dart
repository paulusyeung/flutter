import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/tag_api_model.dart';
import 'package:admin/data/models/domain/tag.dart';
import 'package:admin/data/models/value/parsing.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/tags_api.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Repository for Tags — a small, admin-managed, name+color reference entity
/// scoped per `(company_id, entity_type)`. Unlike most reference data tags are
/// NOT bundled into the login envelope; [refreshAll] fetches both entity types
/// on demand (company-activate + Settings pull-to-refresh). Mutations flow
/// through the standard outbox via the generic `wire<>()`.
class TagRepository extends BaseEntityRepository<Tag, TagApi> {
  TagRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
  }) : super(
         entityType: EntityType.tag,
         requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
       );

  final TagsApi api;

  @override
  String get entityTypeName => 'tag';

  /// Watch tags for a company, optionally scoped to one [entityType]
  /// (`task` / `project`). Used by the picker, the list-filter suggestions,
  /// and the Settings → Tags list.
  Stream<List<Tag>> watchAll({
    required String companyId,
    String? entityType,
    bool includeArchived = false,
  }) {
    return db.tagDao
        .watchAll(
          companyId: companyId,
          entityType: entityType,
          includeArchived: includeArchived,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  @override
  Stream<Tag?> watchByRealId({required String companyId, required String id}) =>
      db.tagDao
          .watchById(companyId: companyId, id: id)
          .map((row) => row == null ? null : _fromRow(row));

  /// Fetch every tag for the company. Tags require an `entity_type` filter on
  /// the index, so we fetch `task` and `project` separately and upsert both —
  /// the sets are disjoint (a tag belongs to exactly one entity_type per the
  /// server's `UNIQUE(company_id, entity_type, name)`). Bypasses the keyset
  /// cursor entirely; tags are a small set, so we just page until exhausted.
  Future<void> refreshAll({required String companyId}) async {
    for (final entityType in const ['task', 'project']) {
      var page = 1;
      while (true) {
        final result = await api.list(
          page: page,
          perPage: 200,
          filters: {'entity_type': entityType},
        );
        final items = result.data.data;
        if (items.isEmpty) break;
        final byId = <String, TagsCompanion>{
          for (final a in items)
            a.id: _apiToCompanion(a, companyId, entityType: entityType),
        };
        await db.tagDao.upsertAllPreservingDirty(
          companyId: companyId,
          byId: byId,
        );
        if (items.length < 200) break;
        page++;
        if (page > 50) break; // safety cap (~10k tags per type)
      }
    }
  }

  Future<SaveResult<Tag>> create({
    required String companyId,
    required Tag draft,
    String? existingTempId,
  }) async {
    final tmpId = existingTempId ?? mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);
    var rowId = 0;
    await db.transaction(() async {
      await db.tagDao.upsert(companion);
      await dedupPendingMutations(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
      );
      rowId = await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: stored.toApiJson(),
      );
    });
    return SaveResult(entity: stored, outboxRowId: rowId);
  }

  Future<SaveResult<Tag>> save({
    required String companyId,
    required Tag tag,
  }) async {
    final companion = _domainToCompanion(tag, companyId, isDirty: true);
    var rowId = 0;
    await db.transaction(() async {
      await db.tagDao.upsert(companion);
      await dedupPendingMutations(
        companyId: companyId,
        entityId: tag.id,
        kind: MutationKind.update,
      );
      rowId = await enqueueMutation(
        companyId: companyId,
        entityId: tag.id,
        kind: MutationKind.update,
        payload: tag.toApiJson(preserveTempId: true),
      );
    });
    return SaveResult(entity: tag, outboxRowId: rowId);
  }

  @override
  Future<void> deleteLocalById({
    required String companyId,
    required String id,
  }) => db.tagDao.deleteById(companyId: companyId, id: id);

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required TagApi serverResponse,
  }) => applyCreateResponseTemplate(
    companyId: companyId,
    tempId: tempId,
    realId: serverResponse.id,
    companion: _apiToCompanion(serverResponse, companyId),
    upsert: db.tagDao.upsert,
    deleteById: (id) => db.tagDao.deleteById(companyId: companyId, id: id),
  );

  @override
  Future<void> applyUpdateResponse({
    required String companyId,
    required TagApi serverResponse,
  }) async {
    await db.tagDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.tagDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.tagDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  // -------------------- conversions --------------------

  TagsCompanion _apiToCompanion(
    TagApi a,
    String companyId, {
    String? entityType,
  }) {
    final normalized = entityType ?? normalizeTagEntityType(a.entityType);
    // Store the payload with the normalized (short) entity_type so a later
    // `_fromRow` round-trip stays consistent with the column.
    final stored = a.copyWith(entityType: normalized);
    return TagsCompanion.insert(
      id: a.id,
      companyId: companyId,
      entityType: Value(normalized),
      name: Value(a.name),
      color: Value(a.color ?? ''),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value(null),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(stored.toJson()),
    );
  }

  TagsCompanion _domainToCompanion(
    Tag t,
    String companyId, {
    required bool isDirty,
  }) {
    return TagsCompanion.insert(
      id: t.id,
      companyId: companyId,
      entityType: Value(t.entityType),
      name: Value(t.name),
      color: Value(t.color),
      updatedAt: _secs(t.updatedAt),
      createdAt: Value(_secs(t.createdAt)),
      archivedAt: t.archivedAt == null
          ? const Value.absent()
          : Value(_secs(t.archivedAt!)),
      isDirty: Value(isDirty),
      isDeleted: Value(t.isDeleted),
      payload: jsonEncode(t.toApiJson(preserveTempId: true)),
    );
  }

  // Every Tag field maps to a column, and a local `toApiJson` payload omits
  // timestamps — so build straight from the (authoritative) columns rather
  // than decoding the payload.
  Tag _fromRow(TagRow row) => Tag(
    id: row.id,
    entityType: row.entityType,
    name: row.name,
    color: row.color,
    updatedAt: epochSecondsToUtc(row.updatedAt),
    createdAt: epochSecondsToUtc(row.createdAt),
    archivedAt: row.archivedAt == null
        ? null
        : epochSecondsToUtc(row.archivedAt!),
    isDeleted: row.isDeleted,
    isDirty: row.isDirty,
  );
}

int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
