import 'package:drift/drift.dart';

/// Single-row table that persists "where the user was" so app restart lands
/// them right back where they left off.
///
/// `filtersJson` is keyed by entity type — each entity's list VM serializes
/// its filter/sort/search state into the same blob to keep the schema small.
class NavState extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get currentRoute => text().named('current_route').nullable()();
  TextColumn get selectedCompanyId =>
      text().named('selected_company_id').nullable()();
  TextColumn get locale => text().nullable()();
  TextColumn get themeMode => text().named('theme_mode').nullable()();
  TextColumn get lightVariant => text().named('light_variant').nullable()();
  TextColumn get darkVariant => text().named('dark_variant').nullable()();
  TextColumn get filtersJson => text().named('filters_json').nullable()();
  BoolColumn get sidebarCollapsed =>
      boolean().named('sidebar_collapsed').withDefault(const Constant(false))();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
