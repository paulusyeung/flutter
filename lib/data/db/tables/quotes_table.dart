import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Quote rows.
///
/// Mirrors `invoices_table.dart` exactly — quotes share the same shape
/// (line items + invitations nested in `payload`, denormalized columns
/// for list filter/sort). The status enum domain is different (`'1'..'4'`
/// for Draft/Sent/Approved/Converted) but stored as plain text just like
/// invoice status.
@DataClassName('QuoteRow')
class Quotes extends Table
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
  TextColumn get date => text().named('date').withDefault(const Constant(''))();
  TextColumn get dueDate =>
      text().named('due_date').withDefault(const Constant(''))();
  TextColumn get amount =>
      text().named('amount').withDefault(const Constant('0'))();
  TextColumn get balance =>
      text().named('balance').withDefault(const Constant('0'))();
  TextColumn get poNumber =>
      text().named('po_number').withDefault(const Constant(''))();
  TextColumn get designId =>
      text().named('design_id').withDefault(const Constant(''))();
  TextColumn get assignedUserId =>
      text().named('assigned_user_id').withDefault(const Constant(''))();
  // Linkage to the invoice that this quote was converted to (empty until
  // status flips to Converted).
  TextColumn get invoiceId =>
      text().named('invoice_id').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
