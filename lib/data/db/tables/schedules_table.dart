import 'package:drift/drift.dart';

/// Drift table for Schedule (task scheduler) rows. Powers the list under
/// Settings → Advanced → Schedules.
///
/// The shape mirrors [PaymentTerms] — a bundled settings entity with the
/// standard outbox flags. The complex `parameters` field round-trips
/// through `payload` because its shape branches by `template`.
@DataClassName('ScheduleRow')
class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get tempId => text().named('temp_id').nullable()();
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  TextColumn get template =>
      text().named('template').withDefault(const Constant(''))();
  TextColumn get frequencyId =>
      text().named('frequency_id').withDefault(const Constant(''))();
  // ISO-formatted YYYY-MM-DD; empty string when null. `Date` semantics —
  // never compared as an integer day-count. Sorts lexicographically same as
  // calendar order.
  TextColumn get nextRun =>
      text().named('next_run').withDefault(const Constant(''))();
  BoolColumn get isPaused =>
      boolean().named('is_paused').withDefault(const Constant(false))();
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
