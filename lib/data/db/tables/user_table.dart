import 'package:drift/drift.dart';

/// Drift table for User rows — the authenticated user's profile, one row per
/// company. Unlike paginated entities this table tops out at the number of
/// companies the user has access to (≤ [kMaxCompaniesPerAccount]), so we
/// don't need indexes beyond the company-scoped lookup.
///
/// `payload` carries the full server JSON so future fields (custom value
/// editors, OAuth refresh metadata, …) can land without a schema migration.
@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get firstName => text().named('first_name')();
  TextColumn get lastName => text().named('last_name')();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get languageId => text().named('language_id')();
  TextColumn get signature => text()();
  IntColumn get updatedAt => integer().named('updated_at')();
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();
  TextColumn get payload => text()();

  @override
  Set<Column> get primaryKey => {companyId, id};
}
