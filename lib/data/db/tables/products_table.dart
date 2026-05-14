import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Product rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body so we can extend the
/// model without a schema migration for every new field.
///
/// Denormalized columns (`product_key`, `notes`, `price`, `cost`,
/// `updated_at`, `archived_at`) are the ones the list view filters and
/// sorts by. Money columns are stored as TEXT so `Decimal` round-trips
/// don't lose precision — the DAO casts to REAL for numeric ORDER BY.
@DataClassName('ProductRow')
class Products extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
  TextColumn get productKey => text().named('product_key')();
  TextColumn get notes => text()();
  TextColumn get price => text()();
  TextColumn get cost => text()();
  TextColumn get quantity => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
