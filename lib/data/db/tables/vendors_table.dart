import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Vendor rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body — including the
/// `contacts[]` array — so we can extend the model in M2+ without a schema
/// migration for every new field. Contacts intentionally live inside
/// `payload`, NOT in a separate `vendor_contacts` Drift table — matches the
/// Client / Contact layout.
///
/// `@DataClassName('VendorRow')` keeps the generated row class from
/// colliding with the domain `Vendor` in `lib/data/models/domain/vendor.dart`.
@DataClassName('VendorRow')
class Vendors extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
  TextColumn get name => text()();
  TextColumn get number => text()();
  TextColumn get idNumber => text().named('id_number')();
  TextColumn get vatNumber => text().named('vat_number')();
  TextColumn get city => text()();
  TextColumn get countryId => text().named('country_id')();
  TextColumn get currencyId => text().named('currency_id')();

  /// Decimal stored as TEXT — round-trips precisely without IEEE-754 loss.
  /// Sort the column numerically via `CAST(balance AS REAL)` in the DAO.
  TextColumn get balance => text()();
  TextColumn get paidToDate => text().named('paid_to_date')();
  TextColumn get phone => text()();

  /// Pre-resolved display string: vendor `name` (falls back to the first
  /// contact's name when the vendor name is empty). Computed at write time
  /// in `_apiToCompanion` / `_domainToCompanion` so list rows don't have
  /// to walk the contacts array per render.
  TextColumn get displayName => text().named('display_name')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
