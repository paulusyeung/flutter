import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Bank Account rows (wire entity: `bank_integration`).
///
/// Denormalized columns surface the fields the settings list filters /
/// searches / sorts by: `name`, `type`, `provider`, `balance` (TEXT for
/// Decimal), `currency_code`, `auto_sync`, `disabled_upstream`,
/// `integration_type`. The full server payload lives in `payload` so a new
/// field doesn't force a migration.
@DataClassName('BankAccountRow')
class BankAccounts extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityFlagColumns,
        EntityPayloadColumn {
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  TextColumn get status =>
      text().named('status').withDefault(const Constant(''))();
  TextColumn get type => text().named('type').withDefault(const Constant(''))();
  TextColumn get provider =>
      text().named('provider').withDefault(const Constant(''))();

  /// Decimal stored as TEXT — round-trips precisely without IEEE-754 loss.
  /// Sort the column numerically via `CAST(balance AS REAL)` in the DAO.
  TextColumn get balance =>
      text().named('balance').withDefault(const Constant('0'))();

  TextColumn get currencyCode =>
      text().named('currency_code').withDefault(const Constant(''))();

  /// `YYYY-MM-DD` sync-from date. Empty string when not set.
  TextColumn get fromDate =>
      text().named('from_date').withDefault(const Constant(''))();

  BoolColumn get autoSync =>
      boolean().named('auto_sync').withDefault(const Constant(false))();
  BoolColumn get disabledUpstream =>
      boolean().named('disabled_upstream').withDefault(const Constant(false))();

  /// `YODLEE` | `NORDIGEN` | empty (manual).
  TextColumn get integrationType =>
      text().named('integration_type').withDefault(const Constant(''))();
  TextColumn get nordigenInstitutionId =>
      text().named('nordigen_institution_id').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
