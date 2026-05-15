import 'package:drift/drift.dart';

/// Drift table for system log rows fetched from `/api/v1/system_logs`.
/// Read-only cache — no outbox / dirty flag (the server is the only writer).
/// `fetched_at` is the local clock when the page was pulled; powers the
/// "Last refreshed N min ago" hint and the stale-cache (>1 h) auto-refresh.
@DataClassName('SystemLogRow')
class SystemLogs extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get userId =>
      text().named('user_id').withDefault(const Constant(''))();
  TextColumn get clientId =>
      text().named('client_id').withDefault(const Constant(''))();
  IntColumn get eventId => integer().named('event_id')();
  IntColumn get categoryId => integer().named('category_id')();
  IntColumn get typeId => integer().named('type_id')();
  TextColumn get log => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get fetchedAt => integer().named('fetched_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
