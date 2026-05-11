import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';

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
    await db.customStatement(r'''
      UPDATE clients SET
        created_at    = COALESCE(json_extract(payload, '$.created_at'), 0),
        custom_value1 = COALESCE(json_extract(payload, '$.custom_value1'), ''),
        custom_value2 = COALESCE(json_extract(payload, '$.custom_value2'), ''),
        custom_value3 = COALESCE(json_extract(payload, '$.custom_value3'), ''),
        custom_value4 = COALESCE(json_extract(payload, '$.custom_value4'), '')
      ''');
  }
  if (from < 3) {
    // Per-(user, company) settings cache. Single row per company; populated
    // on login and updated through the outbox.
    await m.createTable(db.userSettings);
  }
  if (from < 4) {
    // Per-(user, company) admin/owner flags. Previously rebuilt from the
    // login response only; on app restart they were hardcoded to false,
    // silently downgrading permissions until the next login. Backfill is
    // unnecessary because permissions on a stale local row are server-
    // enforced — the worst case is a one-login regression for users who
    // upgrade before re-authenticating.
    await m.addColumn(db.companies, db.companies.isAdmin);
    await m.addColumn(db.companies, db.companies.isOwner);
  }
  if (from < 5) {
    // Read-only dashboard cache (totals/chart/activities/list cards), keyed
    // by `(company_id, kind, filter_hash)`. The repo writes raw API JSON
    // payloads; the UI watches per-row streams.
    await m.createTable(db.dashboardCache);
  }
}

/// Shared denormalized columns every entity table carries: id, company id,
/// tmp id, timestamps, dirty/deleted flags, and the four optional
/// `custom_value` columns Invoice Ninja exposes per entity. Future entity
/// tables (Invoice, Quote, Payment, …) declare their per-entity columns
/// alongside these, and reuse the same backfill pattern in migrations.
///
/// `customFieldCount` lets tables that don't carry custom fields (e.g. tax
/// rates) opt out — 0 skips them entirely, 4 mirrors what Client uses today.
///
/// This is a Drift-table column factory, not a migration helper — Drift's
/// `addColumn` API is per-column anyway, so the actual ALTER TABLE work
/// stays inline in [runMigrations].
class StandardEntityColumns {
  const StandardEntityColumns._();

  /// Documents the contract Invoice/Quote/Product/etc. tables follow. Concrete
  /// table classes mirror this list of columns by name and type. The
  /// `customFieldCount` parameter records the per-entity custom-field arity
  /// in the class doc rather than at runtime.
  static const List<String> requiredColumnNames = <String>[
    'id',
    'company_id',
    'temp_id',
    'updated_at',
    'created_at',
    'archived_at',
    'is_dirty',
    'is_deleted',
    'payload',
  ];

  static const List<String> customFieldColumnNames = <String>[
    'custom_value1',
    'custom_value2',
    'custom_value3',
    'custom_value4',
  ];
}
