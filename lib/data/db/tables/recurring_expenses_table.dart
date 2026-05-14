import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for RecurringExpense rows.
///
/// Superset of `Expenses`: same identity / amount / vendor-client-project-
/// category / currency columns, plus the recurring schedule columns
/// (`frequency_id`, `remaining_cycles`, `next_send_date`, `last_sent_date`,
/// `status_id`) the list page's status chips filter on.
///
/// `id` may be a `tmp_<uuid>` until the server assigns one. `payload`
/// carries the full JSON body so we can extend the model without a schema
/// migration. `documents` lives in its own JSON column (mixin).
@DataClassName('RecurringExpenseRow')
class RecurringExpenses extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
  TextColumn get number =>
      text().named('number').withDefault(const Constant(''))();

  /// `YYYY-MM-DD` calendar date the recurring expense logs as. Stored as
  /// text to match the API's tolerant string shape.
  TextColumn get date => text().named('date').withDefault(const Constant(''))();

  /// `YYYY-MM-DD` payment date. Non-empty alongside `payment_type_id` /
  /// `transaction_reference` indicates the cycle has been "paid" — rare
  /// for recurring rows but the column exists for parity with Expense.
  TextColumn get paymentDate =>
      text().named('payment_date').withDefault(const Constant(''))();

  /// Decimal stored as TEXT — round-trips precisely without IEEE-754 loss.
  TextColumn get amount =>
      text().named('amount').withDefault(const Constant('0'))();

  TextColumn get vendorId =>
      text().named('vendor_id').withDefault(const Constant(''))();
  TextColumn get clientId =>
      text().named('client_id').withDefault(const Constant(''))();
  TextColumn get projectId =>
      text().named('project_id').withDefault(const Constant(''))();
  TextColumn get categoryId =>
      text().named('category_id').withDefault(const Constant(''))();
  TextColumn get invoiceId =>
      text().named('invoice_id').withDefault(const Constant(''))();
  TextColumn get currencyId =>
      text().named('currency_id').withDefault(const Constant(''))();

  BoolColumn get shouldBeInvoiced => boolean()
      .named('should_be_invoiced')
      .withDefault(const Constant(false))();

  // ── Recurring schedule columns ──────────────────────────────────────

  /// `'1'..'12'` — frequency discriminator. Defaults to monthly (`'5'`)
  /// to match the server's default.
  TextColumn get frequencyId =>
      text().named('frequency_id').withDefault(const Constant('5'))();

  /// `-1` is the legacy "endless" sentinel.
  IntColumn get remainingCycles =>
      integer().named('remaining_cycles').withDefault(const Constant(-1))();

  /// `YYYY-MM-DD` — next scheduled send date.
  TextColumn get nextSendDate =>
      text().named('next_send_date').withDefault(const Constant(''))();

  /// `YYYY-MM-DD` — last fired send date. Empty until the first cycle
  /// runs; the list page's "Pending" chip filters on this column.
  TextColumn get lastSentDate =>
      text().named('last_sent_date').withDefault(const Constant(''))();

  /// `'1'..'4'` — Draft / Active / Paused / Completed. Nullable: the server
  /// omits the field on a freshly-created row.
  TextColumn get statusId =>
      text().named('status_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
