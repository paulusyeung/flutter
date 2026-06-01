import 'package:drift/drift.dart';
import 'package:drift/wasm.dart'; // WasmDatabase
import 'package:sqlite3/wasm.dart'; // WasmSqlite3, InMemoryFileSystem

/// Loads the same `sqlite3.wasm` asset the production web opener uses
/// (`lib/data/db/database_opener_web.dart`), served from the app root by
/// `flutter drive -d web-server`, registers an in-memory VFS, and opens a
/// worker-less in-memory `WasmDatabase`. No `drift_worker.js` / IndexedDB is
/// needed for an ephemeral test database. Recipe per drift's own
/// `WasmDatabase.inMemory` docstring.
Future<QueryExecutor> openInMemoryExecutor() async {
  final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  sqlite3.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  return WasmDatabase.inMemory(sqlite3);
}
