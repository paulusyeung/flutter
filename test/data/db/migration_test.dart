import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../generated/schema.dart';

/// Schema tests for the squashed, single-version (v1) Drift schema.
///
/// The migration history was squashed to a single initial schema pre-launch —
/// no installed databases exist to upgrade, so the whole schema is built by
/// `createAll()` in `AppDatabase`'s `onCreate`. There is therefore no upgrade
/// matrix here; these tests guard the fresh-install path instead. When the
/// first post-launch migration lands (schemaVersion 2+), re-introduce a
/// `from → to` matrix test per `docs/squashing-migrations.md`.
void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  group('squashed v1 schema', () {
    test('createAll() matches the generated v1 schema dump', () async {
      // A fresh in-memory database runs `onCreate` → `createAll()` from the
      // live Dart table definitions; `migrateAndValidate` compares that against
      // the dumped v1 schema (`drift_schemas/drift_schema_v1.json`). Fails if a
      // table/column changed without re-running `drift_dev schema dump` +
      // `schema generate`. (Indexes aren't compared by the verifier, so the
      // imperative perf/filter indexes in `onCreate` don't trip it — they're
      // covered by the dedicated index test below.)
      final db = AppDatabase(NativeDatabase.memory());
      await verifier.migrateAndValidate(db, db.schemaVersion);
      await db.close();
    });

    test(
      'a fresh database passes the isSchemaIntact runtime backstop',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        expect(await isSchemaIntact(db), isTrue);
        await db.close();
      },
    );

    test(
      'a fresh database has the late-added single-row + entity columns',
      () async {
        // Belt-and-suspenders column canaries, independent of the schema dump:
        // these were folded in from their historical migration steps and are
        // easy to drop by accident when editing table definitions.
        final db = AppDatabase(NativeDatabase.memory());
        await db.customSelect('SELECT 1').getSingle();

        Future<Set<String>> columnsOf(String table) async {
          final rows = await db.customSelect('PRAGMA table_info($table)').get();
          return rows.map((r) => r.data['name'] as String).toSet();
        }

        expect(
          await columnsOf('nav_state'),
          containsAll(<String>{
            'custom_theme_json',
            'recent_entities_json',
            'text_scale',
          }),
        );
        expect(await columnsOf('saved_views'), contains('icon'));
        expect(await columnsOf('companies'), contains('first_day_of_week'));
        expect(
          await columnsOf('companies'),
          contains('use_comma_as_decimal_place'),
        );
        // Top-level Client Portal registration toggle (the server gates
        // registration on this column, not the deprecated settings copy).
        expect(await columnsOf('companies'), contains('client_can_register'));
        await db.close();
      },
    );

    test('a fresh database has the company-scoped perf + client-filter indexes '
        'and the list query uses one (no full table scan)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').getSingle();

      Future<Set<String>> indexesOn(String table) async {
        final rows = await db.customSelect('PRAGMA index_list($table)').get();
        return rows.map((r) => r.data['name'] as String).toSet();
      }

      // Representative high-volume entity tables across the mixin set
      // (createPerformanceIndexes auto-discovers any company_id table).
      for (final t in [
        'clients',
        'invoices',
        'payments',
        'bank_transactions',
      ]) {
        final idx = await indexesOn(t);
        expect(
          idx,
          containsAll(<String>{
            'idx_${t}_company_updated',
            'idx_${t}_company_deleted',
          }),
          reason: '$t is missing its company-scoped performance indexes',
        );
      }

      // The targeted Client filter indexes (createClientFilterIndexes).
      expect(
        await indexesOn('clients'),
        containsAll(<String>{
          'idx_clients_company_country',
          'idx_clients_company_group',
        }),
      );

      // Prove the index is actually chosen for the canonical list query rather
      // than scanning the table.
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
  });
}
