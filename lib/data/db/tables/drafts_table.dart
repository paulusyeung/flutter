import 'package:drift/drift.dart';

/// In-progress edits. The edit screen writes here on every field change
/// (debounced) so a crash mid-edit doesn't lose work.
///
/// Cleared on successful save or explicit discard.
@DataClassName('DraftRow')
class Drafts extends Table {
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get payload => text()();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {entityType, entityId};
}
