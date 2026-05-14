import 'package:drift/drift.dart';

/// Named snapshots of a list-screen's filter+sort+search state plus the
/// user's current column selection. Local-only — no API endpoint exists
/// yet. Each row belongs to a single `(company_id, entity_type)` and is
/// surfaced by name in the sidebar's "Saved" section.
///
/// `payload_json` is a JSON-encoded `{"v": 1, "data": {...filters...}}`. The
/// `data` map mirrors the per-entity slot the list ViewModels already write
/// to `nav_state.filters_json`. The `v` envelope lets the snapshot shape
/// evolve later (e.g. capture column choices) without breaking on-device rows.
@DataClassName('SavedViewRow')
class SavedViews extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get name => text()();
  TextColumn get payloadJson => text().named('payload_json')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
