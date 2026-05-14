import 'package:drift/drift.dart';

/// Drift table for Task rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body — including the raw
/// `time_log` string — so we can extend the model without a schema
/// migration for every new field.
///
/// Denormalized columns are the ones the list, kanban, and global-timer
/// pill filter / sort by:
///   * `task_number`, `description`, `client_id` — list + search.
///   * `task_status_id`, `status_order` — kanban ordering.
///   * `is_running` — denormalized at write time so the global timer pill's
///     `watchRunning()` is an O(1) indexed lookup instead of payload parse.
///   * `rate`, stored as TEXT for `Decimal` round-trip precision (cast to
///     REAL for numeric ORDER BY, mirroring the Products pattern).
@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get taskNumber =>
      text().named('task_number').withDefault(const Constant(''))();
  TextColumn get description =>
      text().named('description').withDefault(const Constant(''))();
  TextColumn get rate =>
      text().named('rate').withDefault(const Constant('0'))();
  TextColumn get clientId =>
      text().named('client_id').withDefault(const Constant(''))();
  TextColumn get projectId =>
      text().named('project_id').withDefault(const Constant(''))();
  TextColumn get invoiceId =>
      text().named('invoice_id').withDefault(const Constant(''))();
  TextColumn get taskStatusId =>
      text().named('task_status_id').withDefault(const Constant(''))();
  IntColumn get statusOrder =>
      integer().named('status_order').withDefault(const Constant(0))();
  BoolColumn get isRunning =>
      boolean().named('is_running').withDefault(const Constant(false))();
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
  TextColumn get payload => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
