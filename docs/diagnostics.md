# Diagnostics log

Debug-only on-disk capture so future Claude sessions can read what went wrong without the user copy-pasting console output. Wired in `lib/app/diagnostics_log.dart` + `lib/main.dart`; surfaced in Settings → Advanced → System Logs. **Release builds disable this entirely** (`Services.diagnosticsLog == null`, no handlers registered).

What's captured automatically (debug only):
- Uncaught Flutter errors via `FlutterError.onError`.
- Uncaught async errors via `PlatformDispatcher.instance.onError` + `runZonedGuarded`.
- Every `Logger` record at `WARNING` or higher (uses the same `redact()` helper as `lib/app/logging.dart`).

What the user can trigger explicitly:
- **Append outbox snapshot** button on System Logs — dumps stale rows for the active company (dead + in_flight + pending parked > 24 h). Uses `OutboxDao.staleRowsForCompany`. Payload bodies are intentionally omitted (only `payload_size` is written) to keep the file small.

**Disabled on web.** `DiagnosticsLog.open()` resolves a path via `path_provider`, which has no web implementation. `_initDiagnostics()` early-returns `null` on web (`kIsWeb`), exactly as it does in release. There is no on-disk diagnostics log on web.

File layout:
- Path: `getApplicationSupportDirectory()/claude-diagnostics.log` (next to the encrypted Drift DB).
- Rotation: at 512 KB, current file is renamed to `<name>.log.1` (one backup, overwritten on each rotation).
- Format: plain text, one record per line, ISO-8601 UTC timestamps, indented stack lines under the head line.
- gitignored as `claude-diagnostics.log*` (the rotated `.log.1` isn't caught by the generic `*.log` rule).

**To check the log in a future Claude session**, the user can say *"read the diagnostics log"*. The path isn't a constant — it resolves at runtime per platform — so Claude reads it from one of these sources (in order of cost):
1. Settings → Advanced → System Logs displays the absolute path with a copy button; the user can paste it.
2. Boot logs the path via `Logger('main').info('Diagnostics log open at <path>')` — visible in the Xcode/IDE console.
3. On macOS dev, the conventional path is `~/Library/Containers/<bundle-id>/Data/Library/Application Support/<bundle-id>/claude-diagnostics.log` (or, outside the App Sandbox, `~/Library/Application Support/<bundle-id>/`).

Once you have the path, `Read <path>` (or `Read <path>.1` for the rotated backup) ingests it. Lines are pre-redacted, but the file still contains real company/entity ids — treat as user data.
