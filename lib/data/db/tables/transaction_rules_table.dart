import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Transaction Rule rows (wire entity:
/// `bank_transaction_rule`).
///
/// Denormalized columns surface the fields the list page filters / sorts on:
/// `name`, `applies_to`, `vendor_id`, `category_id`, `auto_convert`. The
/// `rules` nested array of [RuleCriterion] objects lives in the JSON
/// `payload` blob — no separate table because rule criteria are tiny and
/// never queried independently.
@DataClassName('TransactionRuleRow')
class TransactionRules extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityFlagColumns,
        EntityPayloadColumn {
  TextColumn get name => text().named('name').withDefault(const Constant(''))();

  /// `DEBIT` (withdrawal — match to expense) or `CREDIT` (deposit — match
  /// to payment/invoice).
  TextColumn get appliesTo =>
      text().named('applies_to').withDefault(const Constant('DEBIT'))();

  BoolColumn get matchesOnAll =>
      boolean().named('matches_on_all').withDefault(const Constant(true))();
  BoolColumn get autoConvert =>
      boolean().named('auto_convert').withDefault(const Constant(false))();

  TextColumn get vendorId =>
      text().named('vendor_id').withDefault(const Constant(''))();
  TextColumn get categoryId =>
      text().named('category_id').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
