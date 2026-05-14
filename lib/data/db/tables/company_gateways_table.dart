import 'package:drift/drift.dart';

/// Drift table for CompanyGateway rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body so we can extend the
/// model without a schema migration per new field.
///
/// Denormalized columns are the ones the list filters / searches / sorts by:
/// `gateway_key` (group by provider), `label` (search), `test_mode` (badge),
/// `archived_at` (state). Everything else lives in the payload.
@DataClassName('CompanyGatewayRow')
class CompanyGateways extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get gatewayKey =>
      text().named('gateway_key').withDefault(const Constant(''))();
  TextColumn get label =>
      text().named('label').withDefault(const Constant(''))();
  BoolColumn get testMode =>
      boolean().named('test_mode').withDefault(const Constant(false))();
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
