import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:logging/logging.dart';

final _log = Logger('AppDatabase');

/// Logical drift database name (the IndexedDB / OPFS store key).
const _kWasmDbName = 'invoiceninja';

/// Bound on a single `WasmDatabase.open` / `WasmDatabase.probe`. The OPFS /
/// IndexedDB store is held **exclusively per browser context**: an overlapping
/// page reload — e.g. the forced reload Flutter's self-destructing service
/// worker performs after a redeploy — can leave a stale context holding the
/// lock, so the next `open` blocks **indefinitely with no error**, trapping
/// boot on the HTML loader forever. Bounding the open turns that hang into a
/// `TimeoutException`, which `openAppDatabase()`'s reset-and-reopen recovery
/// catches (and, failing even that, the `web/index.html` loader safety-net
/// surfaces a reload prompt). The stale context normally releases within a
/// second or two, so the reset's second open — or a user reload — succeeds.
const _kOpenTimeout = Duration(seconds: 5);
const _kProbeTimeout = Duration(seconds: 4);

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
///
/// The open is time-bounded (see [_kOpenTimeout]): a `WasmDatabase.open` that
/// hangs on a store lock held by a concurrent reload must surface as a
/// `TimeoutException` so the caller's recovery path runs, not as an infinite
/// boot-loader spinner.
Future<QueryExecutor> openDatabaseExecutor() async {
  final result = await WasmDatabase.open(
    databaseName: _kWasmDbName,
    sqlite3Uri: _sqlite3Uri,
    driftWorkerUri: _driftWorkerUri,
  ).timeout(_kOpenTimeout);
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
/// Best-effort — a probe/delete failure (including a [_kProbeTimeout] on a
/// still-locked store) must not block startup; the catch swallows it and the
/// fresh open + full re-sync still happens.
Future<void> destroyDatabaseStore() async {
  try {
    final probe = await WasmDatabase.probe(
      sqlite3Uri: _sqlite3Uri,
      driftWorkerUri: _driftWorkerUri,
      databaseName: _kWasmDbName,
    ).timeout(_kProbeTimeout);
    for (final existing in probe.existingDatabases) {
      if (existing.$2 == _kWasmDbName) {
        await probe.deleteDatabase(existing).timeout(_kProbeTimeout);
      }
    }
  } catch (e, st) {
    _log.warning('Failed to delete web database store', e, st);
  }
}
