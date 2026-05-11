import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:admin/data/db/dao/client_dao.dart';
import 'package:admin/data/db/dao/companies_dao.dart';
import 'package:admin/data/db/dao/dashboard_cache_dao.dart';
import 'package:admin/data/db/dao/drafts_dao.dart';
import 'package:admin/data/db/dao/id_remap_dao.dart';
import 'package:admin/data/db/dao/nav_state_dao.dart';
import 'package:admin/data/db/dao/outbox_dao.dart';
import 'package:admin/data/db/dao/statics_dao.dart';
import 'package:admin/data/db/dao/sync_state_dao.dart';
import 'package:admin/data/db/dao/user_settings_dao.dart';
import 'package:admin/data/db/migrations.dart';
import 'package:admin/data/db/tables/clients_table.dart';
import 'package:admin/data/db/tables/companies_table.dart';
import 'package:admin/data/db/tables/dashboard_cache_table.dart';
import 'package:admin/data/db/tables/documents_table.dart';
import 'package:admin/data/db/tables/drafts_table.dart';
import 'package:admin/data/db/tables/id_remap_table.dart';
import 'package:admin/data/db/tables/nav_state_table.dart';
import 'package:admin/data/db/tables/outbox_table.dart';
import 'package:admin/data/db/tables/statics_table.dart';
import 'package:admin/data/db/tables/sync_state_table.dart';
import 'package:admin/data/db/tables/user_settings_table.dart';

part 'app_database.g.dart';

final _log = Logger('AppDatabase');

@DriftDatabase(
  tables: [
    Clients,
    Outbox,
    IdRemap,
    SyncStateRows,
    Statics,
    Drafts,
    NavState,
    Companies,
    Accounts,
    Documents,
    UserSettings,
    DashboardCache,
  ],
  daos: [
    ClientDao,
    OutboxDao,
    IdRemapDao,
    SyncStateDao,
    StaticsDao,
    DraftsDao,
    NavStateDao,
    CompaniesDao,
    UserSettingsDao,
    DashboardCacheDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      await runMigrations(this, m, from, to);
    },
  );

  /// Wipe every table. Used by `logout()` and "Reset local data".
  Future<void> wipe() async {
    await transaction(() async {
      await delete(clients).go();
      await delete(outbox).go();
      await delete(idRemap).go();
      await delete(syncStateRows).go();
      await delete(statics).go();
      await delete(drafts).go();
      await delete(navState).go();
      await delete(documents).go();
      await delete(companies).go();
      await delete(accounts).go();
      await delete(userSettings).go();
      await delete(dashboardCache).go();
    });
  }
}

/// Open the app database with recovery if the file is corrupt or its schema
/// has drifted from what the generated code expects.
///
/// Two failure modes trigger recovery (rename `<name>` → `<name>.broken.<ts>`
/// + open fresh + return `wasReset: true` so `main` routes the user to
/// `/login`):
///   1. Open / probe fails (corrupt sqlite file, irreconcilable downgrade).
///   2. Open succeeds but a table is missing a column the code expects —
///      i.e. a prior schema migration didn't fully apply on this device.
///      Without this backstop a missing column surfaces as a fatal
///      `SqliteException` deep inside login (`_persistAndActivate` INSERT)
///      with no path forward for the user. Caught here, the user just sees
///      "/login" and a fresh sync.
Future<({AppDatabase db, bool wasReset})> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'invoiceninja.sqlite'));

  Future<AppDatabase> openFresh() async {
    final executor = NativeDatabase.createInBackground(file);
    return AppDatabase(executor);
  }

  Future<({AppDatabase db, bool wasReset})> resetAndReopen() async {
    if (await file.exists()) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      await file.rename(p.join(dir.path, 'invoiceninja.sqlite.broken.$ts'));
    }
    final db = await openFresh();
    return (db: db, wasReset: true);
  }

  try {
    final db = await openFresh();
    // Force a trivial query so a corrupt file fails here, not later. This
    // also drives the lazy connection open + runs any pending migrations.
    await db.customSelect('SELECT 1').getSingleOrNull();
    if (!await isSchemaIntact(db)) {
      _log.severe('Drift schema drift detected; resetting local data');
      await db.close();
      return resetAndReopen();
    }
    return (db: db, wasReset: false);
  } catch (e, st) {
    _log.severe('Drift open failed; recovering by resetting local data', e, st);
    return resetAndReopen();
  }
}

/// Probes every declared table with `SELECT col1, col2, ... LIMIT 0` so that
/// SQLite's prepare step throws `no such column: …` if a migration didn't
/// land. `LIMIT 0` means no row scan; this is cheap and runs once per boot.
///
/// Exposed (not private) so integration tests can verify the drift-detection
/// path without needing the platform-specific path_provider glue around the
/// real [openAppDatabase].
Future<bool> isSchemaIntact(AppDatabase db) async {
  try {
    for (final table in db.allTables) {
      final cols = table.columnsByName.keys
          .map((name) => '"$name"')
          .join(', ');
      await db
          .customSelect(
            'SELECT $cols FROM "${table.actualTableName}" LIMIT 0',
          )
          .get();
    }
    return true;
  } catch (e, st) {
    _log.severe('Drift schema validation failed', e, st);
    return false;
  }
}
