import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/tables/saved_views_table.dart';

part 'saved_views_dao.g.dart';

@DriftAccessor(tables: [SavedViews])
class SavedViewsDao extends DatabaseAccessor<AppDatabase>
    with _$SavedViewsDaoMixin {
  SavedViewsDao(super.db);

  /// All saved views for [companyId], any entity type. Ordered by name.
  /// The sidebar consumes this and groups by entity at the UI layer.
  Stream<List<SavedViewRow>> watchAll(String companyId) =>
      (select(savedViews)
            ..where((v) => v.companyId.equals(companyId))
            ..orderBy([(v) => OrderingTerm.asc(v.name)]))
          .watch();

  /// Saved views for a single `(companyId, entityType)`. Drives the bookmark
  /// sheet's existing-views list.
  Stream<List<SavedViewRow>> watchForEntity(
    String companyId,
    String entityType,
  ) =>
      (select(savedViews)
            ..where(
              (v) =>
                  v.companyId.equals(companyId) &
                  v.entityType.equals(entityType),
            )
            ..orderBy([(v) => OrderingTerm.asc(v.name)]))
          .watch();

  Future<SavedViewRow?> byId(String id) =>
      (select(savedViews)..where((v) => v.id.equals(id))).getSingleOrNull();

  Future<void> insertView(SavedViewsCompanion row) =>
      into(savedViews).insert(row);

  /// Single helper for both rename and snapshot updates — pass either or
  /// both. `updatedAt` is always written.
  Future<int> updateById({
    required String id,
    String? name,
    String? payloadJson,
    required int now,
  }) => (update(savedViews)..where((v) => v.id.equals(id))).write(
    SavedViewsCompanion(
      name: name == null ? const Value.absent() : Value(name),
      payloadJson: payloadJson == null
          ? const Value.absent()
          : Value(payloadJson),
      updatedAt: Value(now),
    ),
  );

  Future<int> deleteById(String id) =>
      (delete(savedViews)..where((v) => v.id.equals(id))).go();
}
