import 'package:drift/drift.dart';

/// Identity columns every per-entity table carries: `id` (which may be a
/// `tmp_<uuid>` until the server assigns one, see `id_remap`), `company_id`
/// (every list query scopes by it — enforced by `CompanyScopedDao`), and
/// `temp_id` to remember the original temp id after the tmp→real swap.
mixin EntityIdColumns on Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
}

/// Server-side timestamps. `archived_at` is nullable (server uses 0 for
/// "not archived"; `epochSecondsToUtcOrNull` in `value/parsing.dart`
/// handles the mapping on the way in).
mixin EntityTimestampColumns on Table {
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get createdAt =>
      integer().named('created_at').withDefault(const Constant(0))();
  IntColumn get archivedAt => integer().named('archived_at').nullable()();
}

/// User-defined custom field slots. Mirror Invoice Ninja's universal
/// `custom_value1..4` columns. All five entities carry them in this order.
mixin EntityCustomValueColumns on Table {
  TextColumn get customValue1 =>
      text().named('custom_value1').withDefault(const Constant(''))();
  TextColumn get customValue2 =>
      text().named('custom_value2').withDefault(const Constant(''))();
  TextColumn get customValue3 =>
      text().named('custom_value3').withDefault(const Constant(''))();
  TextColumn get customValue4 =>
      text().named('custom_value4').withDefault(const Constant(''))();
}

/// Local-only flags: `is_dirty` is overlaid onto the domain model by the
/// repository so the UI can render an "Unsynced" chip; `is_deleted` is the
/// soft-delete marker (rows persist; list queries filter them out unless
/// the user toggles "Show deleted").
mixin EntityFlagColumns on Table {
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
}

/// JSON-encoded `List<DocumentApi>`. Nullable so v15→v16 ALTER could land
/// without a backfill; reads back as `const <Document>[]` in the
/// repository's `_fromRow` overlay. Opt-in: only entities with attachable
/// documents include this mixin (Clients, Products, Projects today; not
/// Tasks or GroupSettings).
mixin EntityDocumentsColumn on Table {
  TextColumn get documents => text().nullable()();
}

/// Wire envelope. Every entity carries the full JSON payload so a new
/// field on the server doesn't require a schema migration; the
/// denormalized columns are the ones the list view filters and sorts by.
mixin EntityPayloadColumn on Table {
  TextColumn get payload => text()();
}
