import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/drafts_table.dart';

part 'drafts_dao.g.dart';

@DriftAccessor(tables: [Drafts])
class DraftsDao extends DatabaseAccessor<AppDatabase> with _$DraftsDaoMixin {
  DraftsDao(super.db);

  Future<DraftRow?> read({
    required String entityType,
    required String entityId,
  }) =>
      (select(drafts)
            ..where(
              (d) =>
                  d.entityType.equals(entityType) & d.entityId.equals(entityId),
            )
            ..limit(1))
          .getSingleOrNull();

  Future<void> write({
    required String entityType,
    required String entityId,
    required String payload,
    required int now,
  }) => into(drafts).insertOnConflictUpdate(
    DraftsCompanion.insert(
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      updatedAt: now,
    ),
  );

  Future<void> clear({required String entityType, required String entityId}) =>
      (delete(drafts)..where(
            (d) =>
                d.entityType.equals(entityType) & d.entityId.equals(entityId),
          ))
          .go();
}
