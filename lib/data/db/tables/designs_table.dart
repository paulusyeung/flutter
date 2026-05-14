import 'package:drift/drift.dart';

/// Drift table for Design rows. Powers the design pickers on Settings →
/// Invoice Design and the upcoming Custom Designs CRUD list.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). The six raw HTML strings live inside `payload` (JSON-encoded
/// `DesignApi`) — denormalizing them as separate columns would bloat the row
/// without benefit (no UI sorts/filters by template content).
///
/// Denormalized columns are the ones the list filters / searches / sorts by:
/// `name` (search + sort), `is_custom` + `is_template` (badges / filters),
/// `is_active` (state), `entities` (per-entity-type filter on the picker).
@DataClassName('DesignRow')
class Designs extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  BoolColumn get isCustom =>
      boolean().named('is_custom').withDefault(const Constant(false))();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();
  BoolColumn get isTemplate =>
      boolean().named('is_template').withDefault(const Constant(false))();
  BoolColumn get isFree =>
      boolean().named('is_free').withDefault(const Constant(true))();
  // Stored as the wire shape (comma-separated; matches the server contract).
  TextColumn get entities =>
      text().named('entities').withDefault(const Constant(''))();
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
