import 'package:drift/drift.dart';

/// Single-row cache of `/api/v1/statics` (currencies, countries, payment
/// types, gateways, timezones, date formats, languages, industries, sizes).
///
/// Refreshed after login and on app start when older than 7 days.
@DataClassName('StaticsRow')
class Statics extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get payload => text()();
  IntColumn get fetchedAt => integer().named('fetched_at')();

  @override
  Set<Column> get primaryKey => {id};
}
