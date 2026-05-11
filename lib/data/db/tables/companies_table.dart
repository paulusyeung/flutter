import 'package:drift/drift.dart';

/// Per-company envelope cached locally. The auth response (`LoginResponse`)
/// returns one of these per company the user has access to.
///
/// `settings` is the company settings blob; `permissions` is the per-company
/// permissions map; the rest is metadata shown in the company switcher.
@DataClassName('CompanyRow')
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get displayName => text().named('display_name').nullable()();
  TextColumn get settings => text()();
  TextColumn get permissions => text()();
  TextColumn get accountId => text().named('account_id')();
  TextColumn get token => text()();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Account-level info (one row per logged-in user). Stores hosted-vs-self
/// hosted, plan, trial info, feature flags, etc. — anything that's per-user
/// rather than per-company.
@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get plan => text()();
  IntColumn get numTrialDays => integer().named('num_trial_days')();
  BoolColumn get isHosted =>
      boolean().named('is_hosted').withDefault(const Constant(false))();
  TextColumn get defaultCompanyId =>
      text().named('default_company_id').nullable()();
  TextColumn get featuresJson =>
      text().named('features_json').nullable()();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
