import 'package:drift/drift.dart';

/// Maps a temp id (assigned offline) to the real server-assigned id once the
/// `create` mutation lands. The sync engine writes here; the repository
/// `watch(id)` method reads here so an open detail screen survives the swap.
@DataClassName('IdRemapRow')
class IdRemap extends Table {
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get tempId => text().named('temp_id')();
  TextColumn get realId => text().named('real_id')();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {entityType, tempId};
}
