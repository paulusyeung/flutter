import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Expense rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body so we can extend the
/// model without a schema migration for every new field.
///
/// Denormalized columns are the ones the list filters, searches, and sorts
/// by: `number`, `date`, `payment_date`, `amount` (TEXT for Decimal),
/// `vendor_id`, `client_id`, `project_id`, `category_id`, `invoice_id`,
/// `currency_id`, `is_paid` (bool — derived from payment metadata at write
/// time), `should_be_invoiced` (bool). Cast `amount` as REAL for numeric
/// ORDER BY (mirrors `projects.task_rate`).
@DataClassName('ExpenseRow')
class Expenses extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
  TextColumn get number =>
      text().named('number').withDefault(const Constant(''))();

  /// `YYYY-MM-DD` calendar date the expense was incurred. Empty string when
  /// the user hasn't set one (matches the API's tolerant `String` shape).
  TextColumn get date => text().named('date').withDefault(const Constant(''))();

  /// `YYYY-MM-DD` payment date. Non-empty alongside `payment_type_id` /
  /// `transaction_reference` indicates the expense has been paid.
  TextColumn get paymentDate =>
      text().named('payment_date').withDefault(const Constant(''))();

  /// Decimal stored as TEXT — round-trips precisely without IEEE-754 loss.
  /// Sort the column numerically via `CAST(amount AS REAL)` in the DAO.
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

  /// Pre-computed at write time so the list page's "Paid" chip can filter
  /// with a single boolean index instead of OR-ing three columns.
  BoolColumn get isPaid =>
      boolean().named('is_paid').withDefault(const Constant(false))();
  BoolColumn get shouldBeInvoiced => boolean()
      .named('should_be_invoiced')
      .withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
