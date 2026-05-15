import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for PurchaseOrder rows. Mirrors `quotes_table.dart` shape;
/// vendor-centric (`vendor_id` is the meaningful foreign key) and carries
/// `expense_id` for receipt → expense linkage.
@DataClassName('PurchaseOrderRow')
class PurchaseOrders extends Table
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
  TextColumn get expenseId =>
      text().named('expense_id').withDefault(const Constant(''))();
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

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
