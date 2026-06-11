import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

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
class Tasks extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
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

  /// Denormalized, lowercased, comma-joined attached tag names — populated on
  /// network ingest (the response carries names) so the list can sort by tags
  /// locally. A deliberate approximation of the server's `task_tag_ids|asc`
  /// (GROUP_CONCAT) sort; may briefly lag a tag rename until the task
  /// re-syncs.
  TextColumn get tagNames =>
      text().named('tag_names').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
