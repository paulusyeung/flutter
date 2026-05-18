import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../generated/schema.dart';
import '../../generated/schema_v7.dart' as v7;
import '../../generated/schema_v8.dart' as v8;
import '../../generated/schema_v10.dart' as v10;
import '../../generated/schema_v11.dart' as v11;
import '../../generated/schema_v12.dart' as v12;
import '../../generated/schema_v13.dart' as v13;
import '../../generated/schema_v19.dart' as v19;
import '../../generated/schema_v20.dart' as v20schema;
import '../../generated/schema_v26.dart' as v26schema;
import '../../generated/schema_v31.dart' as v31schema;
import '../../generated/schema_v51.dart' as v51schema;

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
/// The v7 round-trip case below is the minimum that catches "the dump is out
/// of sync with the current Dart schema" — schemas for v1–v6 predate the
/// dump workflow and aren't reconstructed.
void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  group('current schemaVersion is captured', () {
    test('the latest schema matches the generated Dart schema', () async {
      // Builds the DB at v32 from the dumped JSON, opens AppDatabase against
      // it (migrating through to the current `schemaVersion`), and runs
      // drift's schema validator against the current dumped schema. Fails if
      // a developer bumped `schemaVersion` (or added/removed a column)
      // without re-dumping `drift_schemas/` + regenerating `test/generated/`.
      final connection = await verifier.startAt(32);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, db.schemaVersion);
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
        await verifier.migrateAndValidate(db, db.schemaVersion);
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
        await verifier.migrateAndValidate(db, db.schemaVersion);
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
      await verifier.migrateAndValidate(db, db.schemaVersion);
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

    // Belt-and-suspenders fresh-DB presence check for the v49 column, kept
    // alongside the full-chain matrix above (which now validates against
    // `db.schemaVersion`) — same idiom as the v11 test above.
    test('a fresh current database has nav_state.custom_theme_json', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final navCols = await db
          .customSelect('PRAGMA table_info(nav_state)')
          .get();
      final cols = navCols.map((r) => r.data['name']).toSet();
      expect(cols, contains('custom_theme_json'));
      // Recently-viewed list landed in v56 (command palette "Recent" group)
      // — same guard against a future schema dump losing the column.
      expect(cols, contains('recent_entities_json'));
      // A row written without the custom palette reads back null (legacy
      // installs upgrading via the v49 addColumn land here).
      await db.navStateDao.save(
        currentRoute: null,
        selectedCompanyId: null,
        locale: null,
        themeMode: 'light',
        lightVariant: null,
        darkVariant: null,
        filtersJson: null,
        sidebarCollapsed: null,
        now: 1,
      );
      final row = await db.navStateDao.current();
      expect(row?.customThemeJson, isNull);
      await db.close();
    });

    // v52 adds saved_views.icon. Belt-and-suspenders fresh-DB presence
    // check (same idiom as the v49 custom_theme_json test above).
    test('a fresh current database has saved_views.icon', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final cols = await db
          .customSelect('PRAGMA table_info(saved_views)')
          .get();
      expect(cols.map((r) => r.data['name']).toSet(), contains('icon'));
      await db.close();
    });

    test('v51 → v52 upgrade adds saved_views.icon (null for legacy rows)',
        () async {
      final schema = await verifier.schemaAt(51);
      // Seed a v51 saved_views row via the typed v51 schema so the row is
      // written at the old shape (no icon column) without triggering the
      // current-schema migration.
      final v51Db = v51schema.DatabaseAtV51(schema.newConnection());
      await v51Db.customStatement(
        'INSERT INTO saved_views (id, company_id, entity_type, name, '
        'payload_json, created_at, updated_at) '
        "VALUES ('sv1', 'co', 'invoice', 'Deleted', '{}', 1, 1)",
      );
      await v51Db.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final cols = await db
          .customSelect('PRAGMA table_info(saved_views)')
          .get();
      expect(cols.map((r) => r.data['name']).toSet(), contains('icon'));
      final rows = await db
          .customSelect('SELECT id, icon FROM saved_views')
          .get();
      expect(rows.single.data['id'], 'sv1');
      expect(rows.single.data['icon'], isNull);
      await db.close();
    });

    test('v11 → v12 upgrade adds companies.documents (null for legacy '
        'rows so the next applyUpdateResponse repopulates)', () async {
      final schema = await verifier.schemaAt(11);
      final v11Db = v11.DatabaseAtV11(schema.newConnection());
      // Seed a v11 company row without the documents column.
      await v11Db.customStatement(
        'INSERT INTO companies (id, name, settings, permissions, '
        'account_id, token, updated_at) '
        "VALUES ('co', 'Acme', '{}', '{}', 'acct', 'tok', 1)",
      );
      await v11Db.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final companyCols = await db
          .customSelect('PRAGMA table_info(companies)')
          .get();
      expect(
        companyCols.map((r) => r.data['name']).toSet(),
        contains('documents'),
      );
      final rows = await db
          .customSelect('SELECT documents FROM companies')
          .get();
      expect(rows.single.data['documents'], isNull);
      await db.close();
    });

    test('a fresh v12 database has the documents column', () async {
      final db = v12.DatabaseAtV12(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();
      final companyCols = await db
          .customSelect('PRAGMA table_info(companies)')
          .get();
      expect(
        companyCols.map((r) => r.data['name']).toSet(),
        contains('documents'),
      );
      await db.close();
    });

    test('v12 → v13 upgrade adds the saved_views table (empty for legacy '
        'installs since this is a fresh local-only feature)', () async {
      final schema = await verifier.schemaAt(12);
      // Seed a v12 nav_state row so we can verify it survives the migration.
      final v12Db = v12.DatabaseAtV12(schema.newConnection());
      await v12Db.customStatement(
        'INSERT INTO nav_state (id, current_route, updated_at) '
        "VALUES (0, '/clients', 1)",
      );
      await v12Db.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      // saved_views exists with the expected column set.
      final cols = await db
          .customSelect('PRAGMA table_info(saved_views)')
          .get();
      final names = cols.map((r) => r.data['name'] as String).toSet();
      expect(
        names,
        containsAll(<String>{
          'id',
          'company_id',
          'entity_type',
          'name',
          'payload_json',
          'created_at',
          'updated_at',
        }),
      );
      // Empty by default.
      final count = await db
          .customSelect('SELECT count(*) AS c FROM saved_views')
          .getSingle();
      expect(count.data['c'], 0);
      // Pre-existing nav_state row survives.
      final nav = await db.navStateDao.current();
      expect(nav?.currentRoute, '/clients');
      await db.close();
    });

    test('a fresh v13 database has the saved_views table', () async {
      final db = v13.DatabaseAtV13(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();
      final cols = await db
          .customSelect('PRAGMA table_info(saved_views)')
          .get();
      expect(
        cols.map((r) => r.data['name'] as String).toSet(),
        containsAll(<String>{
          'id',
          'company_id',
          'entity_type',
          'name',
          'payload_json',
        }),
      );
      await db.close();
    });

    test(
      'v20 → v21 upgrade adds 5 tax columns to companies + creates the '
      'tax_rates table (defaults: counts=0, calculate_taxes=false, '
      'tax_data_json=null; tax_rates empty until the next bundled refresh)',
      () async {
        final schema = await verifier.schemaAt(20);
        // Seed a v20 company row so we can confirm the migration backfills
        // the new columns to their defaults without losing the existing row.
        final v20Db = v20schema.DatabaseAtV20(schema.newConnection());
        await v20Db.customStatement(
          'INSERT INTO companies (id, name, settings, permissions, '
          'account_id, token, updated_at) '
          "VALUES ('co', 'Acme', '{}', '{}', 'acct', 'tok', 1)",
        );
        await v20Db.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, db.schemaVersion);

        // companies grew 5 new columns with the right defaults.
        final companyCols = await db
            .customSelect('PRAGMA table_info(companies)')
            .get();
        final companyNames = companyCols
            .map((r) => r.data['name'] as String)
            .toSet();
        expect(
          companyNames,
          containsAll(<String>{
            'enabled_tax_rates',
            'enabled_item_tax_rates',
            'enabled_expense_tax_rates',
            'calculate_taxes',
            'tax_data_json',
          }),
        );
        final company = await db
            .customSelect(
              'SELECT enabled_tax_rates, enabled_item_tax_rates, '
              'enabled_expense_tax_rates, calculate_taxes, tax_data_json '
              "FROM companies WHERE id = 'co'",
            )
            .getSingle();
        expect(company.data['enabled_tax_rates'], 0);
        expect(company.data['enabled_item_tax_rates'], 0);
        expect(company.data['enabled_expense_tax_rates'], 0);
        // SQLite stores bool as 0/1 — confirm the default landed as false.
        expect(company.data['calculate_taxes'], 0);
        expect(company.data['tax_data_json'], isNull);

        // tax_rates exists with the expected column set.
        final taxRateCols = await db
            .customSelect('PRAGMA table_info(tax_rates)')
            .get();
        expect(
          taxRateCols.map((r) => r.data['name'] as String).toSet(),
          containsAll(<String>{
            'id',
            'company_id',
            'temp_id',
            'name',
            'rate',
            'updated_at',
            'created_at',
            'archived_at',
            'is_dirty',
            'is_deleted',
            'payload',
          }),
        );
        final taxRateCount = await db
            .customSelect('SELECT count(*) AS c FROM tax_rates')
            .getSingle();
        expect(taxRateCount.data['c'], 0);
        await db.close();
      },
    );

    test('v19 → v20 upgrade adds the payment_terms table (empty for legacy '
        'installs since this is a fresh bundled-entity feature)', () async {
      final schema = await verifier.schemaAt(19);
      // Seed a v19 nav_state row so we can verify it survives the migration.
      final v19Db = v19.DatabaseAtV19(schema.newConnection());
      await v19Db.customStatement(
        'INSERT INTO nav_state (id, current_route, updated_at) '
        "VALUES (0, '/clients', 1)",
      );
      await v19Db.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      // payment_terms exists with the expected column set.
      final cols = await db
          .customSelect('PRAGMA table_info(payment_terms)')
          .get();
      expect(
        cols.map((r) => r.data['name'] as String).toSet(),
        containsAll(<String>{
          'id',
          'company_id',
          'temp_id',
          'name',
          'num_days',
          'updated_at',
          'created_at',
          'archived_at',
          'is_dirty',
          'is_deleted',
          'payload',
        }),
      );
      // Empty by default — `applyBundle` seeds rows from the next /refresh.
      final count = await db
          .customSelect('SELECT count(*) AS c FROM payment_terms')
          .getSingle();
      expect(count.data['c'], 0);
      // Pre-existing nav_state row survives.
      final nav = await db.navStateDao.current();
      expect(nav?.currentRoute, '/clients');
      await db.close();
    });

    test(
      'v26 → current upgrade adds the 12 Account Management columns plus '
      'quickbooks_json (Phase 4) to companies — defaults are 0 / "" / false '
      '/ null; legacy rows survive with backfilled values',
      () async {
        final schema = await verifier.schemaAt(26);
        final v26Db = v26schema.DatabaseAtV26(schema.newConnection());
        await v26Db.customStatement(
          'INSERT INTO companies (id, name, settings, permissions, account_id, '
          "token, updated_at) VALUES ('co1', 'Acme', '{}', '', 'a', 't', 1)",
        );
        await v26Db.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, db.schemaVersion);
        final cols = await db
            .customSelect('PRAGMA table_info(companies)')
            .get();
        final names = cols.map((r) => r.data['name'] as String).toSet();
        // v29 (Account Management Phase 1) adds these 12.
        expect(names, contains('enabled_modules'));
        expect(names, contains('google_analytics_key'));
        expect(names, contains('matomo_id'));
        expect(names, contains('matomo_url'));
        expect(names, contains('session_timeout'));
        expect(names, contains('default_password_timeout'));
        expect(names, contains('oauth_password_required'));
        expect(names, contains('is_disabled'));
        expect(names, contains('markdown_enabled'));
        expect(names, contains('markdown_email_enabled'));
        expect(names, contains('report_include_drafts'));
        expect(names, contains('report_include_deleted'));
        // v30 (Account Management Phase 4 — QuickBooks) adds the
        // nullable JSON blob.
        expect(names, contains('quickbooks_json'));

        // The seeded legacy row gets backfilled with the defaults — int / text
        // / bool columns return 0 / '' / 0 in SQLite respectively.
        // `quickbooks_json` is nullable with no default; existing rows get
        // NULL on the ALTER TABLE.
        final rows = await db
            .customSelect(
              'SELECT enabled_modules, google_analytics_key, session_timeout, '
              'oauth_password_required, is_disabled, markdown_enabled, '
              'report_include_drafts, quickbooks_json '
              "FROM companies WHERE id = 'co1'",
            )
            .get();
        final row = rows.single.data;
        expect(row['enabled_modules'], 0);
        expect(row['google_analytics_key'], '');
        expect(row['session_timeout'], 0);
        expect(row['oauth_password_required'], 0);
        expect(row['is_disabled'], 0);
        expect(row['markdown_enabled'], 0);
        expect(row['report_include_drafts'], 0);
        expect(row['quickbooks_json'], isNull);
        await db.close();
      },
    );

    test(
      'v31 → v32 upgrade adds the 4 custom_surcharge_taxes columns to '
      'companies (all default false; legacy rows survive with the new '
      'columns backfilled). Paired with `custom_fields.surcharge1..4` for '
      'the per-surcharge "Charge taxes" toggle on Settings → Custom '
      'Fields → Invoices.',
      () async {
        final schema = await verifier.schemaAt(31);
        final v31Db = v31schema.DatabaseAtV31(schema.newConnection());
        // Seed a v31 company row — every prior column already present.
        await v31Db.customStatement(
          'INSERT INTO companies (id, name, settings, permissions, account_id, '
          "token, updated_at) VALUES ('co1', 'Acme', '{}', '', 'a', 't', 1)",
        );
        await v31Db.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, db.schemaVersion);
        final cols = await db
            .customSelect('PRAGMA table_info(companies)')
            .get();
        final names = cols.map((r) => r.data['name'] as String).toSet();
        expect(names, contains('custom_surcharge_taxes1'));
        expect(names, contains('custom_surcharge_taxes2'));
        expect(names, contains('custom_surcharge_taxes3'));
        expect(names, contains('custom_surcharge_taxes4'));

        // SQLite returns 0 for BOOLEAN columns defaulting to false.
        final rows = await db
            .customSelect(
              'SELECT custom_surcharge_taxes1, custom_surcharge_taxes2, '
              'custom_surcharge_taxes3, custom_surcharge_taxes4 '
              "FROM companies WHERE id = 'co1'",
            )
            .get();
        final row = rows.single.data;
        expect(row['custom_surcharge_taxes1'], 0);
        expect(row['custom_surcharge_taxes2'], 0);
        expect(row['custom_surcharge_taxes3'], 0);
        expect(row['custom_surcharge_taxes4'], 0);
        await db.close();
      },
    );

    test('v26 → v27 upgrade adds stop_on_unpaid_recurring + '
        'use_quote_terms_on_conversion to companies (both default false; '
        'legacy rows survive with the new columns backfilled)', () async {
      final schema = await verifier.schemaAt(26);
      final v26Db = v26schema.DatabaseAtV26(schema.newConnection());
      // Seed a v26 company row (no workflow toggles yet). Mirrors the v25
      // shape — all product-settings columns already present at this point.
      await v26Db.customStatement(
        'INSERT INTO companies (id, name, settings, permissions, account_id, '
        "token, updated_at) VALUES ('co1', 'Acme', '{}', '', 'a', 't', 1)",
      );
      await v26Db.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final cols = await db
          .customSelect('PRAGMA table_info(companies)')
          .get();
      final names = cols.map((r) => r.data['name'] as String).toSet();
      expect(names, contains('stop_on_unpaid_recurring'));
      expect(names, contains('use_quote_terms_on_conversion'));

      final rows = await db
          .customSelect(
            'SELECT stop_on_unpaid_recurring, use_quote_terms_on_conversion '
            "FROM companies WHERE id = 'co1'",
          )
          .get();
      // SQLite returns 0/1 for BOOLEAN with default false → 0.
      expect(rows.single.data['stop_on_unpaid_recurring'], 0);
      expect(rows.single.data['use_quote_terms_on_conversion'], 0);
      await db.close();
    });

    // v50 adds company-scoped performance indexes. Fresh-DB +
    // upgrade-path checks on the current schema — same idiom as the v49
    // custom_theme_json test (indexes aren't covered by drift's schema
    // verifier, which compares columns/tables, not indexes).
    test('a fresh current database has the company-scoped perf indexes '
        'and the list query uses one (no full table scan)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();

      Future<Set<String>> indexesOn(String table) async {
        final rows = await db
            .customSelect('PRAGMA index_list($table)')
            .get();
        return rows.map((r) => r.data['name'] as String).toSet();
      }

      // Representative high-volume entity tables across the mixin set.
      for (final t in ['clients', 'invoices', 'payments', 'bank_transactions']) {
        final idx = await indexesOn(t);
        expect(
          idx,
          containsAll(<String>{
            'idx_${t}_company_updated',
            'idx_${t}_company_deleted',
          }),
          reason: '$t is missing its v50 performance indexes',
        );
      }

      // Prove the index is actually chosen for the canonical list query
      // rather than scanning the table.
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM clients '
            "WHERE company_id = 'co' ORDER BY updated_at DESC LIMIT 50",
          )
          .get();
      final detail = plan.map((r) => r.data['detail'] as String).join(' | ');
      expect(
        detail,
        contains('USING INDEX'),
        reason: 'list query should use an index, got: $detail',
      );
      expect(
        detail,
        isNot(contains('SCAN clients')),
        reason: 'list query must not full-scan clients, got: $detail',
      );
      await db.close();
    });

    test('v31 → current upgrade creates the perf indexes; seeded rows '
        'survive', () async {
      final schema = await verifier.schemaAt(31);
      final v31Db = v31schema.DatabaseAtV31(schema.newConnection());
      // Seed a client row at v31 so we confirm the index-adding migration
      // doesn't disturb existing data.
      await v31Db.customStatement(
        'INSERT INTO clients (id, company_id, name, number, email, '
        'display_name, balance, updated_at, payload) '
        "VALUES ('c1', 'co', 'Acme', '0001', 'a@b.co', 'Acme', '0', 1, '{}')",
      );
      await v31Db.close();

      // Opening AppDatabase against the v31 connection runs the real
      // onUpgrade chain through to the current schemaVersion (incl. v50).
      final db = AppDatabase(schema.newConnection());
      await db.customSelect('SELECT 1').getSingle();
      final idx = await db
          .customSelect('PRAGMA index_list(clients)')
          .get();
      expect(
        idx.map((r) => r.data['name'] as String).toSet(),
        containsAll(<String>{
          'idx_clients_company_updated',
          'idx_clients_company_deleted',
        }),
      );
      final rows = await db
          .customSelect("SELECT name FROM clients WHERE id = 'c1'")
          .get();
      expect(rows.single.data['name'], 'Acme');
      await db.close();
    });
  });
}
