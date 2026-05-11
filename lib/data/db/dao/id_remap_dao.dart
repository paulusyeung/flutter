import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/id_remap_table.dart';

part 'id_remap_dao.g.dart';

@DriftAccessor(tables: [IdRemap])
class IdRemapDao extends DatabaseAccessor<AppDatabase>
    with _$IdRemapDaoMixin {
  IdRemapDao(super.db);

  Future<void> remember({
    required String entityType,
    required String tempId,
    required String realId,
    required int now,
  }) =>
      into(idRemap).insertOnConflictUpdate(
        IdRemapCompanion.insert(
          entityType: entityType,
          tempId: tempId,
          realId: realId,
          createdAt: now,
        ),
      );

  Future<String?> resolve({
    required String entityType,
    required String tempId,
  }) async {
    final row = await (select(idRemap)
          ..where(
            (r) =>
                r.entityType.equals(entityType) & r.tempId.equals(tempId),
          )
          ..limit(1))
        .getSingleOrNull();
    return row?.realId;
  }
}
