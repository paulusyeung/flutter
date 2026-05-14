import 'package:drift/drift.dart';

/// Drift table for Project rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body so we can extend the
/// model without a schema migration for every new field.
///
/// Denormalized columns are the ones the list filters, searches, and sorts
/// by: `name`, `number`, `client_id`, `assigned_user_id`, `due_date`,
/// `task_rate`, `budgeted_hours`, `current_hours`, `color`. `task_rate` is
/// stored as TEXT for Decimal round-trip precision (cast to REAL for
/// numeric ORDER BY, mirroring Tasks/Products).
@DataClassName('ProjectRow')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  TextColumn get number =>
      text().named('number').withDefault(const Constant(''))();
  TextColumn get clientId =>
      text().named('client_id').withDefault(const Constant(''))();
  TextColumn get assignedUserId =>
      text().named('assigned_user_id').withDefault(const Constant(''))();
  TextColumn get dueDate =>
      text().named('due_date').withDefault(const Constant(''))();
  TextColumn get taskRate =>
      text().named('task_rate').withDefault(const Constant('0'))();
  RealColumn get budgetedHours =>
      real().named('budgeted_hours').withDefault(const Constant(0))();
  RealColumn get currentHours =>
      real().named('current_hours').withDefault(const Constant(0))();
  TextColumn get color =>
      text().named('color').withDefault(const Constant(''))();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get createdAt =>
      integer().named('created_at').withDefault(const Constant(0))();
  IntColumn get archivedAt => integer().named('archived_at').nullable()();
  TextColumn get customValue1 =>
      text().named('custom_value1').withDefault(const Constant(''))();
  TextColumn get customValue2 =>
      text().named('custom_value2').withDefault(const Constant(''))();
  TextColumn get customValue3 =>
      text().named('custom_value3').withDefault(const Constant(''))();
  TextColumn get customValue4 =>
      text().named('custom_value4').withDefault(const Constant(''))();
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  // Nullable JSON column mirroring the same shape Client/Product use for
  // their per-entity document arrays. Reads back as `const <Document>[]`
  // when null.
  TextColumn get documents => text().nullable()();
  TextColumn get payload => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
