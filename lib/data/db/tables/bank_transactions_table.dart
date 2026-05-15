import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Bank Transaction rows (wire entity: `bank_transaction`).
///
/// Denormalized columns cover the fields the list page filters / sorts on:
/// `amount`, `currency_id`, `base_type` (CREDIT|DEBIT), `date`,
/// `bank_account_id`, `description`, `status_id`, plus linked entity ids so
/// the chips render without a payload parse.
@DataClassName('BankTransactionRow')
class BankTransactions extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityFlagColumns,
        EntityPayloadColumn {
  /// Decimal stored as TEXT (see [BankAccounts.balance]).
  TextColumn get amount =>
      text().named('amount').withDefault(const Constant('0'))();

  TextColumn get currencyId =>
      text().named('currency_id').withDefault(const Constant(''))();

  TextColumn get category =>
      text().named('category').withDefault(const Constant(''))();

  /// `CREDIT` (deposit) or `DEBIT` (withdrawal).
  TextColumn get baseType =>
      text().named('base_type').withDefault(const Constant(''))();

  /// `YYYY-MM-DD` transaction date. Empty string when not set.
  TextColumn get date => text().named('date').withDefault(const Constant(''))();

  TextColumn get bankAccountId =>
      text().named('bank_account_id').withDefault(const Constant(''))();
  TextColumn get description =>
      text().named('description').withDefault(const Constant(''))();

  /// Match state. `1`=Unmatched, `2`=Matched, `3`=Converted. Stored as TEXT
  /// to mirror the wire `status_id`.
  TextColumn get statusId =>
      text().named('status_id').withDefault(const Constant('1'))();

  /// Linked expense category (wire `ninja_category_id`). Empty when not
  /// matched.
  TextColumn get categoryId =>
      text().named('category_id').withDefault(const Constant(''))();

  /// Comma-separated invoice ids for matched CREDIT rows.
  TextColumn get invoiceIds =>
      text().named('invoice_ids').withDefault(const Constant(''))();

  TextColumn get paymentId =>
      text().named('payment_id').withDefault(const Constant(''))();
  TextColumn get expenseId =>
      text().named('expense_id').withDefault(const Constant(''))();
  TextColumn get vendorId =>
      text().named('vendor_id').withDefault(const Constant(''))();

  /// Provider's transaction id (int) cast to text.
  TextColumn get transactionId =>
      text().named('transaction_id').withDefault(const Constant(''))();
  TextColumn get transactionRuleId => text()
      .named('transaction_rule_id')
      .withDefault(const Constant(''))();

  TextColumn get participantName => text()
      .named('participant_name')
      .withDefault(const Constant(''))();
  TextColumn get participant =>
      text().named('participant').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
