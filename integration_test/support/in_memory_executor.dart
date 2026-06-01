/// Test-only platform seam: an in-memory drift [QueryExecutor].
///
/// Native uses `NativeDatabase.memory()` (dart:ffi). Web loads sqlite3 WASM
/// with an in-memory VFS. Mirrors the production seam in
/// `lib/data/db/database_opener.dart` so the smoke test compiles on both
/// `flutter test -d macos` and `flutter drive -d web-server` — without the
/// dart:ffi `package:sqlite3` bindings leaking into the web build.
library;

export 'in_memory_executor_web.dart'
    if (dart.library.io) 'in_memory_executor_io.dart';
