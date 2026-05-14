import 'package:drift/drift.dart';

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
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get productKey => text().named('product_key')();
  TextColumn get notes => text()();
  TextColumn get price => text()();
  TextColumn get cost => text()();
  TextColumn get quantity => text()();
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

  /// JSON-encoded `List<DocumentApi>`. Nullable for v15→v16 ALTER without a
  /// backfill. Null is read as `const <Document>[]` in `_fromRow`.
  TextColumn get documents => text().nullable()();
  TextColumn get payload => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
