/// Shared harness for the live demo end-to-end suite.
///
/// This is a **helper library, not a test file** — it has no `main()` and
/// its name does not end in `_test.dart`, so `flutter test integration_test/`
/// never collects it as a test. The area test files under
/// `integration_test/demo/` import it (relative, matching the repo's
/// `test/_support/...` convention) and supply their own `main()`.
///
/// Everything that boots/login/teardown/asserts against the real
/// `https://demo.invoiceninja.com` lives here so coverage can grow by
/// adding small focused `*_test.dart` files rather than one giant file.
///
/// **Read-mostly, with deliberate writes.** Most tests are loose read
/// assertions (screen mounted, no [ErrorView]); the CRUD tests intentionally
/// create/edit/delete on the shared demo account (overriding the "no
/// automated writes" note in `docs/probing-the-demo-api.md`, by team-lead
/// direction). Created rows use the [kWriteMarker] prefix and are deleted in
/// teardown.
///
/// **Network-gated.** Each test file calls [registerDemoReachabilityProbe]
/// in its `main()`; every test starts with `if (skipIfUnreachable()) return;`
/// so a demo outage skips (not fails) — no false CI red.
///
/// **Runner.** Lives under `integration_test/` (NOT `test/integration/`):
/// the real app can't boot headless under plain `flutter test`
/// (`google_fonts` → `path_provider` `MissingPluginException`). CI runs it
/// on a real macOS device via `flutter test integration_test/ -d macos`,
/// which globs recursively and ignores this non-`_test.dart` file.
///
/// **Do not run locally** in normal work — these take over the foreground
/// app and reach the network (the CRUD ones write to shared demo data).
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/biometric_service.dart';
import 'package:admin/data/services/connectivity_watcher.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/main.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/clients/views/client_detail_screen.dart';
import 'package:admin/ui/features/clients/views/client_edit_screen.dart';
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/products/views/product_detail_screen.dart';
import 'package:admin/ui/features/products/views/product_edit_screen.dart';
import 'package:admin/ui/features/shell/widgets/in_sidebar.dart';

// ── Demo server constants ───────────────────────────────────────────────
const kDemoBaseUrl = 'https://demo.invoiceninja.com';
const kDemoEmail = 'demo@invoiceninja.com';
const kDemoPassword = 'Password0';

/// Prefix on every record the CRUD tests create, so a leaked one (cleanup
/// failed) is instantly recognizable and manually purgeable in the demo
/// account.
const kWriteMarker = 'ZZ-CLAUDE-IT';

/// Set by the [registerDemoReachabilityProbe] `setUpAll`. When false every
/// test skips with a clear message instead of failing CI on a transient
/// demo outage. Top-level here, but each `*_test.dart` runs as its own
/// isolate so the probe re-runs (cheaply) once per file.
bool demoReachable = false;
String unreachableReason = '';

/// Always-cancels biometric stand-in — keeps the lock screen from blocking
/// on a real platform prompt. No session here enables biometric, but we
/// inject it defensively so no test can ever wedge on the OS dialog.
class AlwaysCancelBiometric implements BiometricService {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> authenticate({required String reason}) async => false;
}

/// Register the once-per-file reachability `setUpAll`. Call from each test
/// file's `main()` after `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
void registerDemoReachabilityProbe() {
  setUpAll(() async {
    // Cheap unauthenticated probe. Any HTTP answer (even 401/404) proves
    // the box is up; only a transport failure means skip.
    final client = http.Client();
    try {
      final res = await client
          .get(Uri.parse('$kDemoBaseUrl/api/v1/ping'))
          .timeout(const Duration(seconds: 20));
      demoReachable = res.statusCode > 0;
      if (!demoReachable) unreachableReason = 'HTTP ${res.statusCode}';
    } catch (e) {
      demoReachable = false;
      unreachableReason = '$e';
    } finally {
      client.close();
    }
  });
}

/// Skip-guard: every test calls this first. Returns true when the test
/// should bail out (server unreachable) after marking itself skipped.
bool skipIfUnreachable() {
  if (!demoReachable) {
    markTestSkipped('demo server unreachable: $unreachableReason');
    return true;
  }
  return false;
}

/// Build a real-network `Services`: real `http.Client`, in-memory Drift +
/// token storage so nothing leaks onto the dev machine, connectivity pinned
/// online so the outbox/refresh pumps behave deterministically.
({Services services, AppDatabase db}) buildLiveServices() {
  final db = AppDatabase(NativeDatabase.memory());
  final services = Services.build(
    db: db,
    tokenStorage: InMemoryTokenStorage(),
    biometricService: AlwaysCancelBiometric(),
    connectivityWatcher: ConnectivityWatcher.fixed(online: true),
    httpClient: http.Client(),
  );
  return (services: services, db: db);
}

/// Quiet the app *before* the in-memory DB is closed. Without this, a test
/// can finish, `db.close()` runs, and the still-alive app (refresh
/// scheduler, sidebar prefetch, a screen's `initState` formatter load)
/// touches the closed DB → "Can't re-open a database after closing it".
///
/// `addTearDown` is LIFO: registering `db.close` first and the quiet step
/// second means the quiet step runs first — stop the timers, cancel sync,
/// unmount the tree so screen `dispose()`s detach their streams, then let
/// any in-flight local DB read settle — and only then is the DB closed.
void registerLiveTeardown(
  WidgetTester tester,
  ({Services services, AppDatabase db}) bag,
) {
  addTearDown(bag.db.close);
  addTearDown(() async {
    bag.services.refreshScheduler.stop();
    await bag.services.sync.cancel();
    if (tester.binding.rootElement != null) {
      // Let short UI tickers settle before yanking the tree out. The
      // settings screens mount `super_editor` (markdown override fields),
      // whose keyboard-opener animation throws a teardown-only error if
      // its widget is disposed mid-animation.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
    await tester.pump(const Duration(seconds: 1));
  });
}

/// Real login against the demo server. Self-hosted shape (`isHosted:
/// false`) — the demo box is a self-hosted instance, not invoicing.co.
Future<void> loginDemo(Services services) async {
  await services.auth.login(
    baseUrl: kDemoBaseUrl,
    isHosted: false,
    email: kDemoEmail,
    password: kDemoPassword,
  );
}

/// Pump in short bursts until [finder] matches or [timeout] elapses.
/// Network-bound here, so the default budget is generous — the demo
/// `/refresh` payload alone is ~3 MB and the box can be slow.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
}

/// Inverse of [pumpUntilFound]: pump bursts until [finder] matches nothing
/// or [timeout] elapses. Used to wait out an async transition where the
/// success signal is a widget *disappearing* (e.g. the reports EmptyState
/// going away once a queued/polled report run renders results).
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return;
  }
}

/// Drag [scrollable] upward repeatedly, pumping network bursts between
/// drags, so a list crosses its 600px load-more threshold and fetches the
/// next page from the live server. Reusable for any paginated list.
Future<void> scrollToLoadMore(
  WidgetTester tester, {
  required Finder scrollable,
  int drags = 12,
}) async {
  for (var i = 0; i < drags; i++) {
    await tester.drag(scrollable, const Offset(0, -1200));
    for (var p = 0; p < 8; p++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
}

/// Pin a desktop-sized surface. Under headless `flutter test` the default
/// is 800×600, which is narrower than the app's wide breakpoint and makes
/// the master-detail shell overflow. Reset on teardown.
Future<void> useDesktopSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Boot the real app at [initialLocation] with an already-authenticated
/// live session. Teardown is registered via [registerLiveTeardown].
Future<Services> bootLoggedIn(
  WidgetTester tester, {
  required String initialLocation,
}) async {
  await useDesktopSurface(tester);
  final bag = buildLiveServices();
  registerLiveTeardown(tester, bag);
  await loginDemo(bag.services);
  await tester.pumpWidget(
    InvoiceNinjaApp(
      services: bag.services,
      dbWasReset: false,
      initialLocation: initialLocation,
    ),
  );
  return bag.services;
}

/// The running app's go_router, resolved via the always-present `Navigator`
/// under the `Router` — independent of which screen is mounted.
GoRouter goRouter(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

/// Navigate the running app to [route] via the real router, then wait for
/// [screenType] and assert no [ErrorView] surfaced on it.
Future<void> goAndExpect(
  WidgetTester tester, {
  required String route,
  required Type screenType,
}) async {
  GoRouter.of(tester.element(find.byType(InSidebar))).go(route);
  await pumpUntilFound(tester, find.byType(screenType));
  expect(
    find.byType(screenType),
    findsOneWidget,
    reason: 'expected $screenType after navigating to $route',
  );
  // The list/detail screens swap in an ErrorView on a failed fetch. A live
  // round-trip that 4xx/5xx'd would surface here — that's a real failure.
  expect(
    find.descendant(
      of: find.byType(screenType),
      matching: find.byType(ErrorView),
    ),
    findsNothing,
    reason: '$screenType showed an ErrorView after loading $route',
  );
}

/// Navigate to [listRoute], wait for its first [listTileType] row to load
/// from the server, tap it, and assert the [detailType] detail screen
/// mounts with no [ErrorView] — the generic "open a record" smoke,
/// mirroring the bespoke client-detail test for every other entity. The
/// demo dataset is seeded with ≥20 rows per entity, so row 0 always exists.
Future<void> openFirstRowDetail(
  WidgetTester tester, {
  required String listRoute,
  required Type listTileType,
  required Type detailType,
}) async {
  goRouter(tester).go(listRoute);
  final tile = find.byType(listTileType);
  await pumpUntilFound(tester, tile);
  expect(
    tile,
    findsAtLeastNWidgets(1),
    reason: 'demo server should return at least one row for $listRoute',
  );
  await tester.tap(tile.first);
  await pumpUntilFound(tester, find.byType(detailType));
  expect(
    find.byType(detailType),
    findsOneWidget,
    reason: 'expected $detailType after tapping a row on $listRoute',
  );
  expect(
    find.descendant(
      of: find.byType(detailType),
      matching: find.byType(ErrorView),
    ),
    findsNothing,
    reason: '$detailType showed an ErrorView with live data',
  );
}

// ── Write round-trip + cleanup helpers ──────────────────────────────────

/// Unique, self-describing label so a leaked record (cleanup failed) is
/// instantly recognizable and manually purgeable in the demo account.
String uniqueLabel(String what) =>
    '$kWriteMarker $what ${DateTime.now().toUtc().toIso8601String()}';

/// The header set the app's `ApiClient` sends, rebuilt here for raw
/// verification/cleanup requests. Mirrors `ApiClient._buildHeaders`
/// (lib/data/services/api_client.dart): `X-API-Token` from the live
/// session, `X-Requested-With`, JSON accept. `X-API-PASSWORD-BASE64` is
/// added for password-gated DELETEs (base64 of the demo password).
Map<String, String> apiHeaders(Services services, {bool withPassword = false}) {
  final creds = services.auth.credentials.value;
  return {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=UTF-8',
    'X-API-Token': creds?.token ?? '',
    'X-Requested-With': 'com.invoiceninja.admin',
    if (withPassword)
      'X-API-PASSWORD-BASE64': base64Encode(utf8.encode(kDemoPassword)),
  };
}

String apiBase(Services services) =>
    services.auth.credentials.value?.baseUrl ?? kDemoBaseUrl;

/// Best-effort cleanup: hard-DELETE the record we created so the shared demo
/// account doesn't accumulate. Password-gated (412 without the header), so
/// we send `X-API-PASSWORD-BASE64`. Never throws — a failed cleanup must not
/// mask the real test result; the [kWriteMarker] makes a leak findable.
Future<void> deleteEntityBestEffort(
  Services services, {
  required String apiPath, // e.g. '/api/v1/clients'
  required String id,
}) async {
  if (id.isEmpty || id.startsWith('tmp_')) return;
  final client = http.Client();
  try {
    final res = await client
        .delete(
          Uri.parse('${apiBase(services)}$apiPath/$id'),
          headers: apiHeaders(services, withPassword: true),
        )
        .timeout(const Duration(seconds: 20));
    debugPrint('[demo cleanup] DELETE $apiPath/$id → ${res.statusCode}');
  } catch (e) {
    debugPrint('[demo cleanup] DELETE $apiPath/$id failed: $e');
  } finally {
    client.close();
  }
}

/// Tap the edit scaffold's Save action. It's a bare `TextButton` labelled
/// with `tr('save')` ("Save") living in the AppBar actions of the edit
/// screen (`lib/ui/core/edit/entity_edit_scaffold.dart`).
Future<void> tapSave(WidgetTester tester, Type editScreenType) async {
  final saveBtn = find.descendant(
    of: find.byType(editScreenType),
    matching: find.widgetWithText(TextButton, 'Save'),
  );
  await pumpUntilFound(tester, saveBtn, timeout: const Duration(seconds: 10));
  expect(saveBtn, findsOneWidget, reason: 'edit screen must expose Save');
  await tester.tap(saveBtn);
}

/// The first text field inside [screenType] (the autofocused identity
/// field — client name / product key).
Finder firstFieldOf(Type screenType) => find
    .descendant(of: find.byType(screenType), matching: find.byType(TextField))
    .first;

/// Replace the identity field's text. When [awaitPrefillContains] is set
/// (edit mode), first wait until the field is populated with the loaded
/// entity — typing before the async row load finishes leaves the VM in a
/// create-like state (`_original == null`), so Save would POST a *new*
/// record instead of updating the existing one.
Future<void> enterIdentity(
  WidgetTester tester,
  Type screenType,
  String text, {
  String? awaitPrefillContains,
}) async {
  final field = firstFieldOf(screenType);
  if (awaitPrefillContains != null) {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      final w = field.evaluate().isEmpty
          ? null
          : tester.widget<TextField>(field);
      if ((w?.controller?.text ?? '').contains(awaitPrefillContains)) break;
    }
  }
  await tester.enterText(field, text);
  await tester.pump();
}

/// Poll the server's list endpoint (Invoice Ninja's generic `?filter=`
/// search) until a record whose JSON contains [unique] appears, and return
/// its server id ('' if it never shows). This is the authoritative proof
/// the UI → outbox → sync write actually round-tripped — it reads the
/// server, not local Drift. The timestamped [kWriteMarker] label matches
/// exactly one row.
Future<String> findServerEntityId(
  WidgetTester tester,
  Services services, {
  required String listPath, // e.g. '/api/v1/clients'
  required String unique,
}) async {
  final url = Uri.parse(
    '${apiBase(services)}$listPath'
    '?filter=${Uri.encodeQueryComponent(kWriteMarker)}'
    '&per_page=50&sort=updated_at|desc',
  );
  for (var attempt = 0; attempt < 12; attempt++) {
    final client = http.Client();
    http.Response? res;
    try {
      res = await client
          .get(url, headers: apiHeaders(services))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      /* transient — retry */
    } finally {
      client.close();
    }
    if (res != null && res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      for (final row in (body['data'] as List? ?? const [])) {
        final m = row as Map<String, dynamic>;
        if (jsonEncode(m).contains(unique)) return m['id'] as String;
      }
    }
    await tester.pump(const Duration(seconds: 2));
  }
  return '';
}

/// Tap the edit Save action, then leave the editor. With the saved-clean
/// latch in `GenericEditViewModel`, a successful Save clears `isDirty`, so
/// navigating away no longer pops "Discard changes?". The Discard tap below
/// is kept as a defensive fallback (e.g. a validation failure left the form
/// genuinely dirty) and is a harmless no-op on the happy path — the record
/// is already in the outbox/server by then regardless.
Future<void> saveAndLeaveEditor(
  WidgetTester tester,
  Type editScreenType, {
  required String listRoute,
  required Type listType,
}) async {
  await tapSave(tester, editScreenType);
  // Let the optimistic create/update commit + the auto drain kick fire.
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  goRouter(tester).go(listRoute);
  await tester.pump(const Duration(milliseconds: 500));
  final discard = find.text('Discard');
  if (discard.evaluate().isNotEmpty) {
    await tester.tap(discard.first);
    await tester.pump(const Duration(milliseconds: 500));
  }
  await pumpUntilFound(tester, find.byType(listType));
}

/// Best-effort failure forensics: the active route, mounted screens, and
/// visible dialog/text — always printed to the log. Plus, **only on GitHub
/// Actions**, a pixel screenshot written into the workspace for the
/// `upload-artifact` step. Locally `screencapture` is never invoked, so the
/// run never trips the macOS screen-recording permission prompt. Never
/// throws — diagnostics must not mask the real failure.
Future<void> dumpFailure(WidgetTester tester, String label) async {
  try {
    debugPrint(
      '[demo FAIL $label] route='
      '${goRouter(tester).routeInformationProvider.value.uri}',
    );
  } catch (e) {
    debugPrint('[demo FAIL $label] route unavailable: $e');
  }
  for (final t in const [
    ClientEditScreen,
    ClientDetailScreen,
    ClientListScreen,
    ProductEditScreen,
    ProductDetailScreen,
  ]) {
    if (find.byType(t).evaluate().isNotEmpty) {
      debugPrint('[demo FAIL $label] mounted: $t');
    }
  }
  if (find.byType(Dialog).evaluate().isNotEmpty) {
    debugPrint('[demo FAIL $label] a Dialog is on screen');
  }
  // Any visible dialog title/body text — surfaces the "Discard changes?"
  // guard and validation messages straight into the CI log.
  for (final w in find.byType(Text).evaluate()) {
    final t = (w.widget as Text).data;
    if (t != null && t.trim().isNotEmpty && t.length < 80) {
      debugPrint('[demo FAIL $label] text: $t');
    }
  }
  // CI-only pixel screenshot. Skipped entirely off GitHub Actions so a
  // local dev run never invokes `screencapture` (no screen-recording
  // permission prompt). Everything runs as child processes — the app
  // itself is sandboxed — and writes into the workspace so the workflow's
  // upload-artifact step can publish it. Never throws.
  if (Platform.environment['GITHUB_ACTIONS'] == 'true') {
    try {
      final ws =
          Platform.environment['GITHUB_WORKSPACE'] ?? Directory.current.path;
      final dir = '$ws/build/integration-failures';
      final safe = label.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
      final path = '$dir/${safe}_$ts.png';
      await Process.run('mkdir', ['-p', dir]);
      final r = await Process.run('screencapture', ['-x', path]);
      debugPrint('[demo FAIL $label] screenshot exit=${r.exitCode} → $path');
    } catch (e) {
      debugPrint('[demo FAIL $label] screenshot failed: $e');
    }
  }
}

/// Run [body]; on any failure dump diagnostics, then rethrow so the test
/// still fails (with forensics attached to the CI log).
Future<void> withFailureCapture(
  WidgetTester tester,
  String label,
  Future<void> Function() body,
) async {
  try {
    await body();
  } catch (_) {
    await dumpFailure(tester, label);
    rethrow;
  }
}
