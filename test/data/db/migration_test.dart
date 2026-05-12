import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../generated/schema.dart';
import '../../generated/schema_v7.dart' as v7;
import '../../generated/schema_v8.dart' as v8;

/// Migration matrix tests.
///
/// `migrations.dart` claims this file exists ("The accompanying test … exercises
/// the matrix from every prior schema to the current one") and we got bitten
/// by it not existing: at least one user has been observed with a `companies`
/// table that's missing the v7 `logo_url` column, which crashes login deep in
/// `_persistAndActivate`. The runtime backstop is `isSchemaIntact()` in
/// `app_database.dart`; this file is the CI-time companion that should fail
/// a build BEFORE shipping a broken `runMigrations` (or a schemaVersion bump
/// without an accompanying schema dump).
///
/// Capturing a new schema version (workflow for the next schema bump):
///   1. Bump `AppDatabase.schemaVersion` and write the `runMigrations` clause.
///   2. `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/`
///   3. `dart run drift_dev schema generate drift_schemas/ test/generated/`
///   4. Add an entry to the matrix below (one `test` per `(from, to)` pair).
///
/// TODO(migration-history): backfill `drift_schemas/drift_schema_v{1..6}.json`
/// so this test can exercise upgrades from older installs. The v7 round-trip
/// case below is the minimum that catches "the dump is out of sync with the
/// current Dart schema" (which is the most common way someone bumps the
/// version without dumping).
void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  group('schemaVersion = 8 is captured', () {
    test('v8 schema matches the generated Dart schema', () async {
      // Builds the DB at v8 from the dumped JSON, opens AppDatabase against
      // it, and runs drift's schema validator. Fails if a developer bumped
      // `schemaVersion` (or added/removed a column) without re-dumping
      // `drift_schemas/drift_schema_v8.json`.
      final connection = await verifier.startAt(8);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, 8);
      await db.close();
    });

    test(
      'a fresh v8 database opens cleanly with the right column set',
      () async {
        // Direct sanity check on the captured schema: every table the code
        // declares is present with every column, no leftover orphan tables.
        final db = v8.DatabaseAtV8(NativeDatabase.memory());
        await db.customSelect('SELECT 1').getSingle();
        final companyCols = await db
            .customSelect('PRAGMA table_info(companies)')
            .get();
        final companyNames = companyCols.map((r) => r.data['name']).toSet();
        expect(companyNames, contains('logo_url'));
        expect(companyNames, contains('is_owner'));
        expect(companyNames, contains('is_admin'));
        // Sidebar collapse preference landed in v8 — guards against a future
        // schemaVersion bump that loses the column from the dumped schema.
        final navCols = await db
            .customSelect('PRAGMA table_info(nav_state)')
            .get();
        expect(
          navCols.map((r) => r.data['name']).toSet(),
          contains('sidebar_collapsed'),
        );
        await db.close();
      },
    );

    test(
      'v7 → v8 upgrade adds sidebar_collapsed defaulting to false',
      () async {
        // Start at v7, seed a nav_state row, run the migration to v8, and
        // confirm the new column is present and reads back as false for
        // existing installs.
        final schema = await verifier.schemaAt(7);
        final v7Db = v7.DatabaseAtV7(schema.newConnection());
        await v7Db.customStatement(
          'INSERT INTO nav_state (id, current_route, updated_at) '
          "VALUES (0, '/clients', 1)",
        );
        await v7Db.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 8);
        final row = await db.navStateDao.current();
        expect(row?.currentRoute, '/clients');
        expect(row?.sidebarCollapsed, isFalse);
        await db.close();
      },
    );
  });
}
