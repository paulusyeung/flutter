import 'package:drift/drift.dart';

import 'app_database.dart';

/// Schema migration switchboard.
///
/// Every release that changes a table bumps [AppDatabase.schemaVersion] and
/// adds a case to this switch. The accompanying test
/// (`test/data/db/migration_test.dart`) exercises the matrix from every prior
/// schema to the current one.
Future<void> runMigrations(AppDatabase db, Migrator m, int from, int to) async {
  // No upgrades yet — schemaVersion is 1.
  // When you add one, the pattern is:
  //   if (from < 2) {
  //     await m.addColumn(db.clients, db.clients.newColumn);
  //   }
}
