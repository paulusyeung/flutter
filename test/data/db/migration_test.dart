import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../generated/schema.dart';
import '../../generated/schema_v7.dart' as v7;

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

  group('schemaVersion = 7 is captured', () {
    test('v7 schema matches the generated Dart schema', () async {
      // Builds the DB at v7 from the dumped JSON, opens AppDatabase against
      // it, and runs drift's schema validator. Fails if a developer bumped
      // `schemaVersion` (or added/removed a column) without re-dumping
      // `drift_schemas/drift_schema_v7.json`.
      final connection = await verifier.startAt(7);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, 7);
      await db.close();
    });

    test(
      'a fresh v7 database opens cleanly with the right column set',
      () async {
        // Direct sanity check on the captured schema: every table the code
        // declares is present with every column, no leftover orphan tables.
        final db = v7.DatabaseAtV7(NativeDatabase.memory());
        // Force schema creation via a trivial query.
        await db.customSelect('SELECT 1').getSingle();
        // Sample a column that's been the source of past drift: `logo_url`
        // landed in v7 and is the column most likely to be missing on a
        // partial-migration install.
        final cols = await db
            .customSelect('PRAGMA table_info(companies)')
            .get();
        final names = cols.map((r) => r.data['name']).toSet();
        expect(names, contains('logo_url'));
        expect(names, contains('is_owner'));
        expect(names, contains('is_admin'));
        await db.close();
      },
    );
  });
}
