import 'package:drift/drift.dart';

/// Drift table for TaxRate rows. Loaded bundled via `/refresh?first_load=true`
/// and consumed by the default-tax pickers on Settings → Tax Settings.
@DataClassName('TaxRateRow')
class TaxRates extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  RealColumn get rate =>
      real().named('rate').withDefault(const Constant(0.0))();
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
