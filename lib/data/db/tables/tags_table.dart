import 'package:drift/drift.dart';

/// Drift table for Tag rows. Tags are scoped to a single `entity_type`
/// (`task` / `project`) and powers the tag picker on Task/Project edit, the
/// list `tag_ids` filter, and the Settings → Tags management screen.
@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get entityType =>
      text().named('entity_type').withDefault(const Constant(''))();
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  TextColumn get color =>
      text().named('color').withDefault(const Constant(''))();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get createdAt =>
      integer().named('created_at').withDefault(const Constant(0))();
  IntColumn get archivedAt => integer().named('archived_at').nullable()();
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
