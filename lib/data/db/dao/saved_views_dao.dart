import 'package:drift/drift.dart';

import 'package:admin/data/db/dao/_distinct_stream.dart';

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
          .watch()
          .distinctRows();

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
          .watch()
          .distinctRows();

  Future<SavedViewRow?> byId(String id) =>
      (select(savedViews)..where((v) => v.id.equals(id))).getSingleOrNull();

  Future<void> insertView(SavedViewsCompanion row) =>
      into(savedViews).insert(row);

  /// Single helper for rename / snapshot / icon updates — pass any subset.
  /// `updatedAt` is always written.
  ///
  /// [icon] is a `Value<String?>` (not a bare `String?`) on purpose: `null`
  /// is a meaningful value here ("reset to the default bookmark"), so the
  /// `String?`→`Value.absent()` sentinel used by [name] / [payloadJson]
  /// can't express it. Default `Value.absent()` = leave the column untouched.
  Future<int> updateById({
    required String id,
    String? name,
    String? payloadJson,
    Value<String?> icon = const Value.absent(),
    required int now,
  }) => (update(savedViews)..where((v) => v.id.equals(id))).write(
    SavedViewsCompanion(
      name: name == null ? const Value.absent() : Value(name),
      payloadJson: payloadJson == null
          ? const Value.absent()
          : Value(payloadJson),
      icon: icon,
      updatedAt: Value(now),
    ),
  );

  Future<int> deleteById(String id) =>
      (delete(savedViews)..where((v) => v.id.equals(id))).go();
}
