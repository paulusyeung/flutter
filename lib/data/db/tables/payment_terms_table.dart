import 'package:drift/drift.dart';

/// Drift table for PaymentTerm rows. Powers the payment-term dropdown on
/// Online Payments → Defaults and the list under Settings → Advanced →
/// Payment Terms.
@DataClassName('PaymentTermRow')
class PaymentTerms extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  IntColumn get numDays =>
      integer().named('num_days').withDefault(const Constant(0))();
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
