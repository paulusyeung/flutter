import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/nav_state_table.dart';

part 'nav_state_dao.g.dart';

@DriftAccessor(tables: [NavState])
class NavStateDao extends DatabaseAccessor<AppDatabase>
    with _$NavStateDaoMixin {
  NavStateDao(super.db);

  Future<NavStateData?> current() =>
      (select(navState)
            ..where((n) => n.id.equals(0))
            ..limit(1))
          .getSingleOrNull();

  Future<void> save({
    required String? currentRoute,
    required String? selectedCompanyId,
    required String? locale,
    required String? themeMode,
    required String? filtersJson,
    required int now,
  }) => into(navState).insertOnConflictUpdate(
    NavStateCompanion.insert(
      // Single-row table: pin the primary key so insertOnConflictUpdate
      // actually detects the conflict against the prior row.
      id: const Value(0),
      currentRoute: Value(currentRoute),
      selectedCompanyId: Value(selectedCompanyId),
      locale: Value(locale),
      themeMode: Value(themeMode),
      filtersJson: Value(filtersJson),
      updatedAt: now,
    ),
  );

  /// Route-only update — used by the router observer on every navigation.
  /// Cheaper than [save] when only the route changed.
  Future<void> saveRoute({required String route, required int now}) async {
    await into(navState).insertOnConflictUpdate(
      NavStateCompanion.insert(
        id: const Value(0),
        currentRoute: Value(route),
        updatedAt: now,
      ),
    );
  }

  /// Filters-only update — list ViewModels call this whenever their search /
  /// state / sort / custom filters change. Leaves the other fields
  /// (`currentRoute`, `selectedCompanyId`, etc.) untouched.
  Future<void> saveFilters({
    required String filtersJson,
    required int now,
  }) async {
    await into(navState).insertOnConflictUpdate(
      NavStateCompanion.insert(
        id: const Value(0),
        filtersJson: Value(filtersJson),
        updatedAt: now,
      ),
    );
  }

  Future<void> clear() => (delete(navState)..where((n) => n.id.equals(0))).go();
}
