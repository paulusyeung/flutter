import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for RecurringInvoice rows. Mirrors `invoices_table.dart`
/// plus the recurring-specific columns (`frequency_id`, `next_send_date`,
/// `remaining_cycles`, `auto_bill`).
@DataClassName('RecurringInvoiceRow')
class RecurringInvoices extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
  TextColumn get number =>
      text().named('number').withDefault(const Constant(''))();
  TextColumn get statusId =>
      text().named('status_id').withDefault(const Constant('1'))();
  TextColumn get clientId =>
      text().named('client_id').withDefault(const Constant(''))();
  TextColumn get vendorId =>
      text().named('vendor_id').withDefault(const Constant(''))();
  TextColumn get projectId =>
      text().named('project_id').withDefault(const Constant(''))();

  /// Set when the recurring invoice belongs to a payment link
  /// (subscription). Denormalized so the Payment Link detail screen can
  /// list its recurring invoices via a cheap `subscription_id` filter.
  TextColumn get subscriptionId =>
      text().named('subscription_id').withDefault(const Constant(''))();
  TextColumn get date => text().named('date').withDefault(const Constant(''))();
  TextColumn get dueDate =>
      text().named('due_date').withDefault(const Constant(''))();

  /// Denormalized for parity with `invoices_table` (the recurring template can
  /// carry a partial). Read path reconstructs from `payload`; these columns
  /// exist only so list sort/filter can reach them without JSON parsing.
  TextColumn get partialDueDate =>
      text().named('partial_due_date').withDefault(const Constant(''))();
  TextColumn get amount =>
      text().named('amount').withDefault(const Constant('0'))();
  TextColumn get balance =>
      text().named('balance').withDefault(const Constant('0'))();
  TextColumn get partial =>
      text().named('partial').withDefault(const Constant('0'))();
  TextColumn get poNumber =>
      text().named('po_number').withDefault(const Constant(''))();
  TextColumn get designId =>
      text().named('design_id').withDefault(const Constant(''))();
  TextColumn get assignedUserId =>
      text().named('assigned_user_id').withDefault(const Constant(''))();
  TextColumn get frequencyId =>
      text().named('frequency_id').withDefault(const Constant(''))();
  TextColumn get nextSendDate =>
      text().named('next_send_date').withDefault(const Constant(''))();
  IntColumn get remainingCycles =>
      integer().named('remaining_cycles').withDefault(const Constant(0))();
  TextColumn get autoBill =>
      text().named('auto_bill').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
