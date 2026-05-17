import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Client rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body so we can extend the
/// model in M2+ without a schema migration for every new field.
///
/// `@DataClassName('ClientRow')` keeps the generated row class from
/// colliding with the domain `Client` in `lib/data/models/domain/client.dart`.
@DataClassName('ClientRow')
class Clients extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
  TextColumn get name => text()();
  TextColumn get number => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text().named('display_name')();
  TextColumn get balance => text()();

  /// JSON-encoded `List<LocationApi>`. Client-only (no shared mixin —
  /// only clients carry locations). Nullable so the v52→v53 ALTER lands
  /// without a backfill; reads back as `const <Location>[]` via
  /// `decodeLocationsColumn` in the repository's `_fromRow` overlay.
  /// Locations are written via the standalone `/api/v1/locations` resource
  /// and read-embedded on the client — the domain `Client.toApiJson`
  /// deliberately omits them from the outbound wire, so (exactly like
  /// `documents`) they need their own column to survive a local
  /// `repo.save` round-trip.
  TextColumn get locations => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
