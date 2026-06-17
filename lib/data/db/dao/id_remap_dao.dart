import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/tables/id_remap_table.dart';

part 'id_remap_dao.g.dart';

@DriftAccessor(tables: [IdRemap])
class IdRemapDao extends DatabaseAccessor<AppDatabase> with _$IdRemapDaoMixin {
  IdRemapDao(super.db);

  Future<void> remember({
    required String entityType,
    required String tempId,
    required String realId,
    required int now,
  }) => into(idRemap).insertOnConflictUpdate(
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
    final row =
        await (select(idRemap)
              ..where(
                (r) =>
                    r.entityType.equals(entityType) & r.tempId.equals(tempId),
              )
              ..limit(1))
            .getSingleOrNull();
    return row?.realId;
  }

  /// Resolve a `tmp_` id to its real id WITHOUT knowing the entity type.
  /// `tmp_` ids are uuid-v4 (globally unique across entity types), so a bare
  /// tempId lookup is unambiguous. Used by the sync drain to heal a payload
  /// `tmp_` token whose owning entity already synced — the token may belong to
  /// a different entity type than the row carrying it (e.g. a `tmp_` tag id
  /// embedded in a task's `tags` array, whose tag create already round-tripped
  /// and was deleted before the task row was even enqueued).
  Future<String?> resolveAnyType(String tempId) async {
    final row =
        await (select(idRemap)
              ..where((r) => r.tempId.equals(tempId))
              ..limit(1))
            .getSingleOrNull();
    return row?.realId;
  }

  /// Emits the real id whenever a remap row appears for
  /// `(entityType, tempId)`. Used by `ClientRepository.watch` so an open
  /// detail screen survives an in-flight tmp→real swap without going blank.
  /// Emits null when no remap row exists yet.
  Stream<String?> watchRealId({
    required String entityType,
    required String tempId,
  }) {
    final q = select(idRemap)
      ..where((r) => r.entityType.equals(entityType) & r.tempId.equals(tempId))
      ..limit(1);
    return q.watchSingleOrNull().map((row) => row?.realId);
  }
}
