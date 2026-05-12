import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../generated/schema.dart';
import '../../generated/schema_v7.dart' as v7;
import '../../generated/schema_v8.dart' as v8;
import '../../generated/schema_v10.dart' as v10;
import '../../generated/schema_v11.dart' as v11;

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

  group('current schemaVersion is captured', () {
    test('the latest schema matches the generated Dart schema', () async {
      // Builds the DB at v11 from the dumped JSON, opens AppDatabase against
      // it, and runs drift's schema validator. Fails if a developer bumped
      // `schemaVersion` (or added/removed a column) without re-dumping
      // `drift_schemas/drift_schema_v11.json`.
      final connection = await verifier.startAt(11);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, 11);
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
      'v7 → current upgrade adds sidebar_collapsed defaulting to false',
      () async {
        // Start at v7, seed a nav_state row, run the migration to the current
        // schemaVersion, and confirm the new column is present and reads
        // back as false for existing installs.
        final schema = await verifier.schemaAt(7);
        final v7Db = v7.DatabaseAtV7(schema.newConnection());
        await v7Db.customStatement(
          'INSERT INTO nav_state (id, current_route, updated_at) '
          "VALUES (0, '/clients', 1)",
        );
        await v7Db.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 11);
        final row = await db.navStateDao.current();
        expect(row?.currentRoute, '/clients');
        expect(row?.sidebarCollapsed, isFalse);
        // v11 adds light_variant + dark_variant; legacy rows read back null
        // (the controller falls through to its defaults).
        expect(row?.lightVariant, isNull);
        expect(row?.darkVariant, isNull);
        await db.close();
      },
    );

    test(
      'v8 → v10 upgrade adds outbox.field_errors_json (null by default for '
      'pre-existing dead rows so the schema-drift backstop accepts them)',
      () async {
        final schema = await verifier.schemaAt(8);
        final v8Db = v8.DatabaseAtV8(schema.newConnection());
        // Seed a dead outbox row at v8 (no field_errors_json column yet).
        await v8Db.customStatement(
          'INSERT INTO outbox (company_id, entity_type, entity_id, '
          'mutation_kind, payload, idempotency_key, attempts, '
          'next_attempt_at, state, last_error, created_at) '
          "VALUES ('co', 'client', 'c1', 'update', '{}', 'k', 1, 0, "
          "'dead', 'oops', 0)",
        );
        await v8Db.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 11);
        final outboxCols = await db
            .customSelect('PRAGMA table_info(outbox)')
            .get();
        expect(
          outboxCols.map((r) => r.data['name']).toSet(),
          contains('field_errors_json'),
        );
        // The legacy dead row survives — last_error stays put, the new
        // column reads back null.
        final rows = await db
            .customSelect('SELECT last_error, field_errors_json FROM outbox')
            .get();
        expect(rows.single.data['last_error'], 'oops');
        expect(rows.single.data['field_errors_json'], isNull);
        await db.close();
      },
    );

    test('a fresh v10 database has the field_errors_json column', () async {
      final db = v10.DatabaseAtV10(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();
      final outboxCols = await db
          .customSelect('PRAGMA table_info(outbox)')
          .get();
      expect(
        outboxCols.map((r) => r.data['name']).toSet(),
        contains('field_errors_json'),
      );
      await db.close();
    });

    test('v10 → v11 upgrade adds nav_state.light_variant + dark_variant '
        '(null for legacy rows so existing theme_mode is preserved)', () async {
      final schema = await verifier.schemaAt(10);
      final v10Db = v10.DatabaseAtV10(schema.newConnection());
      // Seed a v10 nav_state row that picked dark mode but never saw the
      // new variant columns — represents an existing install.
      await v10Db.customStatement(
        'INSERT INTO nav_state (id, theme_mode, updated_at) '
        "VALUES (0, 'dark', 1)",
      );
      await v10Db.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 11);
      final navCols = await db
          .customSelect('PRAGMA table_info(nav_state)')
          .get();
      final cols = navCols.map((r) => r.data['name']).toSet();
      expect(cols, contains('light_variant'));
      expect(cols, contains('dark_variant'));

      final row = await db.navStateDao.current();
      expect(row?.themeMode, 'dark');
      expect(row?.lightVariant, isNull);
      expect(row?.darkVariant, isNull);
      await db.close();
    });

    test('a fresh v11 database has the variant columns', () async {
      final db = v11.DatabaseAtV11(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();
      final navCols = await db
          .customSelect('PRAGMA table_info(nav_state)')
          .get();
      final cols = navCols.map((r) => r.data['name']).toSet();
      expect(cols, contains('light_variant'));
      expect(cols, contains('dark_variant'));
      await db.close();
    });
  });
}
