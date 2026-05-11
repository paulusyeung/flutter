import 'package:drift/drift.dart';

/// Per-(company, entity_type) pagination + freshness state.
///
/// [lastUpdatedAt] + [lastUpdatedId] is the keyset cursor we send as
/// `since_updated_at` + `since_id` on list requests. The pair-based cursor
/// avoids duplicates and dropouts when multiple records share an updated_at.
@DataClassName('SyncStateRow')
class SyncStateRows extends Table {
  TextColumn get companyId => text().named('company_id')();
  TextColumn get entityType => text().named('entity_type')();
  IntColumn get lastUpdatedAt =>
      integer().named('last_updated_at').nullable()();
  TextColumn get lastUpdatedId => text().named('last_updated_id').nullable()();
  IntColumn get lastFullSyncAt =>
      integer().named('last_full_sync_at').nullable()();
  IntColumn get lastDeltaSyncAt =>
      integer().named('last_delta_sync_at').nullable()();

  @override
  Set<Column> get primaryKey => {companyId, entityType};
}
