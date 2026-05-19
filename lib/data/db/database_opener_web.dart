import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:logging/logging.dart';

final _log = Logger('AppDatabase');

/// Logical drift database name (the IndexedDB / OPFS store key).
const _kWasmDbName = 'invoiceninja';

/// These two assets are vendored into `web/` and served from the app root.
/// `sqlite3.wasm` is the plain (unencrypted) build — web does not use
/// SQLCipher (see CLAUDE.md § Web). `drift_worker.js` is generated via
/// `dart run drift_dev make-driftworker`. Both must be version-matched to
/// the resolved `drift` / `sqlite3` packages.
final _sqlite3Uri = Uri.parse('sqlite3.wasm');
final _driftWorkerUri = Uri.parse('drift_worker.js');

/// Web executor: drift WASM over the best available browser storage
/// (OPFS where headers allow it, otherwise IndexedDB). No encryption and
/// no `PRAGMA key` — the browser origin sandbox is the trust boundary.
Future<QueryExecutor> openDatabaseExecutor() async {
  final result = await WasmDatabase.open(
    databaseName: _kWasmDbName,
    sqlite3Uri: _sqlite3Uri,
    driftWorkerUri: _driftWorkerUri,
  );
  if (result.missingFeatures.isNotEmpty) {
    // Surfaced so a future Claude session / the developer can see why
    // persistence degraded (e.g. unsafeIndexedDb / inMemory) instead of
    // silently losing data on reload.
    _log.warning(
      'Web DB missing browser features: ${result.missingFeatures}; '
      'storage=${result.chosenImplementation}',
    );
  }
  return result.resolvedExecutor;
}

/// Web recovery: probe for the drift store under [_kWasmDbName] and delete
/// it (IndexedDB or OPFS). The next [openDatabaseExecutor] opens fresh.
/// Best-effort — a probe/delete failure must not block startup; the fresh
/// open + full re-sync still happens.
Future<void> destroyDatabaseStore() async {
  try {
    final probe = await WasmDatabase.probe(
      sqlite3Uri: _sqlite3Uri,
      driftWorkerUri: _driftWorkerUri,
      databaseName: _kWasmDbName,
    );
    for (final existing in probe.existingDatabases) {
      if (existing.$2 == _kWasmDbName) {
        await probe.deleteDatabase(existing);
      }
    }
  } catch (e, st) {
    _log.warning('Failed to delete web database store', e, st);
  }
}
