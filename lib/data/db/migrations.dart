import 'package:drift/drift.dart';

import 'app_database.dart';

/// Schema migration switchboard.
///
/// Every release that changes a table bumps [AppDatabase.schemaVersion] and
/// adds a case to this switch. The accompanying test
/// (`test/data/db/migration_test.dart`) exercises the matrix from every prior
/// schema to the current one.
Future<void> runMigrations(AppDatabase db, Migrator m, int from, int to) async {
  if (from < 2) {
    // Add filter/sort columns. Every new column has a default so `addColumn`
    // can populate existing rows in-place; the backfill below then pulls the
    // real values out of the `payload` blob so existing local DBs survive
    // the upgrade without re-syncing from the server.
    await m.addColumn(db.clients, db.clients.createdAt);
    await m.addColumn(db.clients, db.clients.customValue1);
    await m.addColumn(db.clients, db.clients.customValue2);
    await m.addColumn(db.clients, db.clients.customValue3);
    await m.addColumn(db.clients, db.clients.customValue4);
    // COALESCE guards against payloads with missing keys or malformed JSON —
    // json_extract returns NULL in those cases, which would otherwise violate
    // the columns' non-null constraint.
    await db.customStatement(
      r'''
      UPDATE clients SET
        created_at    = COALESCE(json_extract(payload, '$.created_at'), 0),
        custom_value1 = COALESCE(json_extract(payload, '$.custom_value1'), ''),
        custom_value2 = COALESCE(json_extract(payload, '$.custom_value2'), ''),
        custom_value3 = COALESCE(json_extract(payload, '$.custom_value3'), ''),
        custom_value4 = COALESCE(json_extract(payload, '$.custom_value4'), '')
      ''',
    );
  }
  if (from < 3) {
    // Per-(user, company) settings cache. Single row per company; populated
    // on login and updated through the outbox.
    await m.createTable(db.userSettings);
  }
}
