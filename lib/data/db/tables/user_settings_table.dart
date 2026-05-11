import 'package:drift/drift.dart';

/// Per-(user, company) settings persisted from the login response and updated
/// via the outbox.
///
/// `tableColumnsJson` is the raw `Map<String, List<String>>` blob the old
/// admin-portal stores at `userCompany.settings.table_columns` — keys are
/// the literal `'$EntityType.x'` strings (e.g. `"EntityType.client"`),
/// values are the snake_case column ids. We preserve unknown keys / ids
/// verbatim so a round-trip through this app doesn't drop choices the new
/// app can't yet render.
///
/// `extraJson` carries every other field from `uc.settings` (accent color,
/// number_years_active, dashboard_fields, …) so when we PUT back to
/// `/api/v1/company_users/{userId}` we don't accidentally clobber settings
/// the new app doesn't know about.
///
/// Single row per company; `companyId` is the primary key.
@DataClassName('UserSettingsRow')
class UserSettings extends Table {
  TextColumn get companyId => text().named('company_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get tableColumnsJson =>
      text().named('table_columns_json').withDefault(const Constant('{}'))();
  TextColumn get extraJson =>
      text().named('extra_json').withDefault(const Constant('{}'))();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {companyId};
}
