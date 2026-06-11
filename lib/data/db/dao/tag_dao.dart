import 'package:drift/drift.dart';

import 'package:admin/data/db/dao/_distinct_stream.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/company_scoped_dao.dart';
import 'package:admin/data/db/tables/tags_table.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase>
    with _$TagDaoMixin, CompanyScopedDao {
  TagDao(super.db);

  /// Watch tags for a company, scoped to a single [entityType] (`task` /
  /// `project`) when provided. Used by the picker, the list filter
  /// suggestions, and the Settings → Tags list. Tags are a small set, so
  /// there is no pagination — the full (filtered) set is returned in name
  /// order.
  Stream<List<TagRow>> watchAll({
    required String companyId,
    String? entityType,
    bool includeArchived = false,
  }) {
    final q = select(tags)
      ..where((t) => t.companyId.equals(companyId) & t.isDeleted.equals(false));
    if (entityType != null) {
      q.where((t) => t.entityType.equals(entityType));
    }
    if (!includeArchived) {
      q.where((t) => t.archivedAt.isNull());
    }
    q.orderBy([(t) => OrderingTerm(expression: t.name.lower())]);
    return q.watch().distinctRows();
  }

  Stream<TagRow?> watchById({required String companyId, required String id}) {
    final q = select(tags)
      ..where((t) => t.companyId.equals(companyId) & t.id.equals(id))
      ..limit(1);
    return q.watchSingleOrNull();
  }

  /// One-shot batch read by id — mirrors `TaskStatusDao.getByIds`.
  Future<List<TagRow>> getByIds({
    required String companyId,
    required Iterable<String> ids,
  }) {
    final list = ids.toList(growable: false);
    if (list.isEmpty) return Future.value(const <TagRow>[]);
    final q = select(tags)
      ..where((t) => t.companyId.equals(companyId) & t.id.isIn(list));
    return q.get();
  }

  Future<void> upsert(TagsCompanion row) =>
      into(tags).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<TagsCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(tags, rows));
  }

  /// Server-refresh upsert that preserves the user's in-flight edits.
  /// Mirrors [BaseEntityDao.upsertAllPreservingDirty]; used by `refreshAll`
  /// so a queued offline edit isn't clobbered by a stale server payload.
  Future<void> upsertAllPreservingDirty({
    required String companyId,
    required Map<String, TagsCompanion> byId,
  }) async {
    if (byId.isEmpty) return;
    final candidateIds = byId.keys.toList(growable: false);
    final dirtyQ = selectOnly(tags)
      ..addColumns([tags.id])
      ..where(
        tags.companyId.equals(companyId) &
            tags.id.isIn(candidateIds) &
            tags.isDirty.equals(true),
      );
    final dirty = {for (final r in await dirtyQ.get()) r.read(tags.id)!};
    final filtered = [
      for (final entry in byId.entries)
        if (!dirty.contains(entry.key)) entry.value,
    ];
    await upsertAll(filtered);
  }

  Future<int> deleteById({required String companyId, required String id}) {
    return (delete(
      tags,
    )..where((t) => t.companyId.equals(companyId) & t.id.equals(id))).go();
  }
}
