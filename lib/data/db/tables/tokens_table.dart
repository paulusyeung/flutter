import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Token rows (wire entity: `token` / `company_token`).
///
/// Denormalized columns surface the fields the list page filters / sorts on:
/// `name`, `user_id`, `is_system`. The masked `token` value lives on its
/// own column for quick row-rendering. The full payload blob stays in
/// `payload`.
@DataClassName('TokenRow')
class Tokens extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityFlagColumns,
        EntityPayloadColumn {
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  TextColumn get userId =>
      text().named('user_id').withDefault(const Constant(''))();
  TextColumn get token =>
      text().named('token').withDefault(const Constant(''))();
  BoolColumn get isSystem =>
      boolean().named('is_system').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
