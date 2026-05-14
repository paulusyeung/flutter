import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for ExpenseCategory rows.
///
/// Bundled via `/refresh?first_load=true` (`company.expense_categories`) AND
/// paginated through `/api/v1/expense_categories` — same shape as
/// `task_statuses`. Denormalized columns are `name` and `color`; everything
/// else rides in the JSON `payload` blob so a new server field never forces
/// a schema migration.
@DataClassName('ExpenseCategoryRow')
class ExpenseCategories extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityFlagColumns,
        EntityPayloadColumn {
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  TextColumn get color =>
      text().named('color').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
