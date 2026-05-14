import 'package:drift/drift.dart';

/// Drift table for group_settings rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body so the model can
/// grow new keys without a schema migration for every field.
///
/// `name` is denormalized so the list view can sort/search without
/// deserializing the payload per row.
@DataClassName('GroupSettingRow')
class GroupSettings extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get name => text()();
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
