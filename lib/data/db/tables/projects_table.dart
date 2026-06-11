import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

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
class Projects extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
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

  /// Denormalized, lowercased, comma-joined attached tag names — for local
  /// sort by tags. See `Tasks.tagNames`.
  TextColumn get tagNames =>
      text().named('tag_names').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
