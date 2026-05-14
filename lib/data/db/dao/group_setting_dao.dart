import 'package:drift/drift.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/company_scoped_dao.dart';
import 'package:admin/data/db/dao/entity_query_helpers.dart';
import 'package:admin/data/db/tables/group_settings_table.dart';

part 'group_setting_dao.g.dart';

/// Stable field-id constants for sort selection. Mirrors `ProductFieldIds`.
class GroupSettingFieldIds {
  static const String name = 'name';
  static const String updatedAt = 'updated_at';
}

@DriftAccessor(tables: [GroupSettings])
class GroupSettingDao extends DatabaseAccessor<AppDatabase>
    with _$GroupSettingDaoMixin, CompanyScopedDao {
  GroupSettingDao(super.db);

  /// Watch a windowed slice of group_settings rows. Filters: state (active /
  /// archived / deleted), free-text search across `name`.
  Stream<List<GroupSettingRow>> watchPage({
    required String companyId,
    required int offset,
    required int limit,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = GroupSettingFieldIds.name,
    bool sortAscending = true,
  }) {
    final q = select(groupSettings)
      ..where((g) => g.companyId.equals(companyId));

    if (states.isNotEmpty) {
      q.where(
        (g) => entityStateFilter(
          states: states,
          archivedAt: g.archivedAt,
          isDeleted: g.isDeleted,
        ),
      );
    }

    if (search != null && search.isNotEmpty) {
      final needle = '%${search.toLowerCase()}%';
      q.where((g) => g.name.lower().like(needle));
    }

    q.orderBy([
      (g) => OrderingTerm(
        expression: _sortExpression(g, sortField),
        mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
      ),
      (g) => OrderingTerm(expression: g.id),
    ]);

    q.limit(limit, offset: offset);
    return q.watch();
  }

  Expression _sortExpression(GroupSettings g, String field) {
    switch (field) {
      case GroupSettingFieldIds.updatedAt:
        return g.updatedAt;
      case GroupSettingFieldIds.name:
      default:
        return g.name.lower();
    }
  }

  /// Watch every active row for [companyId], sorted by name ascending.
  /// Safe — small dataset, watches local Drift only, never expands into a
  /// large network page request. Drives the settings list and the Assign
  /// Group dialog dropdown.
  Stream<List<GroupSettingRow>> watchAll({required String companyId}) {
    final q = select(groupSettings)
      ..where(
        (g) =>
            g.companyId.equals(companyId) &
            g.isDeleted.equals(false) &
            g.archivedAt.isNull(),
      )
      ..orderBy([(g) => OrderingTerm(expression: g.name.lower())]);
    return q.watch();
  }

  Stream<int> watchCount({required String companyId}) {
    final q = selectOnly(groupSettings)
      ..addColumns([groupSettings.id.count()])
      ..where(
        groupSettings.companyId.equals(companyId) &
            groupSettings.isDeleted.equals(false),
      );
    return q
        .map((row) => row.read<int>(groupSettings.id.count()) ?? 0)
        .watchSingle();
  }

  Stream<GroupSettingRow?> watchById({
    required String companyId,
    required String id,
  }) {
    final q = select(groupSettings)
      ..where((g) => g.companyId.equals(companyId) & g.id.equals(id))
      ..limit(1);
    return q.watchSingleOrNull();
  }

  Future<void> upsert(GroupSettingsCompanion row) =>
      into(groupSettings).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<GroupSettingsCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(groupSettings, rows));
  }

  Future<int> deleteById({required String companyId, required String id}) {
    return (delete(
      groupSettings,
    )..where((g) => g.companyId.equals(companyId) & g.id.equals(id))).go();
  }
}
