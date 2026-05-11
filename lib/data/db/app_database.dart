import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dao/client_dao.dart';
import 'dao/companies_dao.dart';
import 'dao/drafts_dao.dart';
import 'dao/id_remap_dao.dart';
import 'dao/nav_state_dao.dart';
import 'dao/outbox_dao.dart';
import 'dao/statics_dao.dart';
import 'dao/sync_state_dao.dart';
import 'migrations.dart';
import 'tables/clients_table.dart';
import 'tables/companies_table.dart';
import 'tables/documents_table.dart';
import 'tables/drafts_table.dart';
import 'tables/id_remap_table.dart';
import 'tables/nav_state_table.dart';
import 'tables/outbox_table.dart';
import 'tables/statics_table.dart';
import 'tables/sync_state_table.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

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
    });
  }
}

/// Open the app database with recovery if the file is corrupt.
///
/// If opening fails (corrupt sqlite file, irreconcilable downgrade, etc.) the
/// file is renamed to `<name>.broken.<ts>` and a fresh database is opened.
/// The caller is responsible for routing the user back to `/login` after a
/// recovery (we lost the local cache but the server is unaffected).
Future<({AppDatabase db, bool wasReset})> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'invoiceninja.sqlite'));

  Future<AppDatabase> openFresh() async {
    final executor = NativeDatabase.createInBackground(file);
    return AppDatabase(executor);
  }

  try {
    final db = await openFresh();
    // Force a trivial query so a corrupt file fails here, not later.
    await db.customSelect('SELECT 1').getSingleOrNull();
    return (db: db, wasReset: false);
  } catch (e, st) {
    _log.severe('Drift open failed; recovering by resetting local data', e, st);
    if (await file.exists()) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      await file.rename(p.join(dir.path, 'invoiceninja.sqlite.broken.$ts'));
    }
    final db = await openFresh();
    return (db: db, wasReset: true);
  }
}
