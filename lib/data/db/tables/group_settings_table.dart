import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for group_settings rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body so the model can
/// grow new keys without a schema migration for every field.
///
/// `name` is denormalized so the list view can sort/search without
/// deserializing the payload per row.
@DataClassName('GroupSettingRow')
class GroupSettings extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
