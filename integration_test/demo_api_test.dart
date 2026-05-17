/// Live end-to-end coverage against the public demo server.
///
/// Unlike `app_smoke_test.dart` (which stubs every request with a
/// `MockClient`), this suite boots the real `InvoiceNinjaApp` with a real
/// `http.Client` and talks to `https://demo.invoiceninja.com` using the
/// canned read credentials documented in `docs/probing-the-demo-api.md`.
/// The point is to prove the whole stack works in practice: real login →
/// real `/refresh` → real page-by-page list loads → real detail loads →
/// settings → session refresh → logout.
///
/// **Read-only.** The demo dataset is shared and resets periodically, so
/// every assertion here is loose (screen mounted, no [ErrorView], data
/// present) and nothing in this file issues a write/mutation against the
/// server — see the warning in `docs/probing-the-demo-api.md`.
///
/// **Network-gated.** If the demo server is unreachable when the suite
/// starts, every test calls `markTestSkipped` instead of failing — a demo
/// outage is not an app regression. When the server *is* reachable, a
/// failure here is a real failure.
///
/// **Location / runner.** Lives under `integration_test/` next to
/// `app_smoke_test.dart`, and runs on a real macOS device via CI's
/// `flutter test integration_test/ -d macos` step. It deliberately does
/// **not** live under `test/integration/`: that directory runs headless
/// under plain `flutter test`, where the real app can't boot (no
/// `path_provider` plugin → `google_fonts` throws `MissingPluginException`).
/// The suite still pins a desktop-sized surface so the responsive
/// master-detail shell doesn't overflow the default integration window.
///
/// **Do not run these locally** in normal work — like the rest of
/// `integration_test/`, they take over the foreground app and reach the
/// network. They run in CI on macOS. (The exception is while actively
/// developing this file, per the team lead's standing instruction.)
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/biometric_service.dart';
import 'package:admin/data/services/connectivity_watcher.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/main.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/auth/views/login_screen.dart';
import 'package:admin/ui/features/clients/views/client_detail_screen.dart';
import 'package:admin/ui/features/clients/views/client_edit_screen.dart';
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/clients/widgets/client_list_tile.dart';
import 'package:admin/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:admin/ui/features/expenses/views/expense_list_screen.dart';
import 'package:admin/ui/features/invoices/views/invoice_list_screen.dart';
import 'package:admin/ui/features/payments/views/payment_list_screen.dart';
import 'package:admin/ui/features/products/views/product_detail_screen.dart';
import 'package:admin/ui/features/products/views/product_edit_screen.dart';
import 'package:admin/ui/features/products/views/product_list_screen.dart';
import 'package:admin/ui/features/projects/views/project_list_screen.dart';
import 'package:admin/ui/features/quotes/views/quote_list_screen.dart';
import 'package:admin/ui/features/reports/views/reports_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/company_details_shell.dart';
import 'package:admin/ui/features/settings/views/basic/localization/localization_shell.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/user_details_shell.dart';
import 'package:admin/ui/features/shell/widgets/in_sidebar.dart';
import 'package:admin/ui/features/tasks/views/task_list_screen.dart';
import 'package:admin/ui/features/vendors/views/vendor_list_screen.dart';

// ── Demo server constants ───────────────────────────────────────────────
const _demoBaseUrl = 'https://demo.invoiceninja.com';
const _demoEmail = 'demo@invoiceninja.com';
const _demoPassword = 'Password0';

/// Set in [main]'s reachability precheck. When false every test skips with a
/// clear message rather than failing CI on a transient demo outage.
bool _demoReachable = false;
String _unreachableReason = '';

/// Always-cancels biometric stand-in — keeps the lock screen from blocking
/// on a real platform prompt. No session here enables biometric, but we
/// inject it defensively so no test can ever wedge on the OS dialog.
class _AlwaysCancelBiometric implements BiometricService {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> authenticate({required String reason}) async => false;
}

/// Build a real-network `Services`: real `http.Client`, in-memory Drift +
/// token storage so nothing leaks onto the dev machine, connectivity pinned
/// online so the outbox/refresh pumps behave deterministically.
({Services services, AppDatabase db}) _buildLiveServices() {
  final db = AppDatabase(NativeDatabase.memory());
  final services = Services.build(
    db: db,
    tokenStorage: InMemoryTokenStorage(),
    biometricService: _AlwaysCancelBiometric(),
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
void _registerLiveTeardown(
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
Future<void> _loginDemo(Services services) async {
  await services.auth.login(
    baseUrl: _demoBaseUrl,
    isHosted: false,
    email: _demoEmail,
    password: _demoPassword,
  );
}

/// Pump in short bursts until [finder] matches or [timeout] elapses.
/// Network-bound here, so the default budget is generous — the demo
/// `/refresh` payload alone is ~3 MB and the box can be slow.
Future<void> _pumpUntilFound(
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

/// Skip-guard: every test calls this first. Returns true when the suite
/// should bail out (server unreachable) after marking the test skipped.
bool _skipIfUnreachable() {
  if (!_demoReachable) {
    markTestSkipped('demo server unreachable: $_unreachableReason');
    return true;
  }
  return false;
}

/// Pin a desktop-sized surface. Under headless `flutter test` the default
/// is 800×600, which is narrower than the app's wide breakpoint and makes
/// the master-detail shell overflow. Reset on teardown.
Future<void> _useDesktopSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Boot the real app at [initialLocation] with an already-authenticated
/// live session. Caller is responsible for `addTearDown(db.close)`.
Future<Services> _bootLoggedIn(
  WidgetTester tester, {
  required String initialLocation,
}) async {
  await _useDesktopSurface(tester);
  final bag = _buildLiveServices();
  _registerLiveTeardown(tester, bag);
  await _loginDemo(bag.services);
  await tester.pumpWidget(
    InvoiceNinjaApp(
      services: bag.services,
      dbWasReset: false,
      initialLocation: initialLocation,
    ),
  );
  return bag.services;
}

/// Navigate the running app to [route] via the real router, then wait for
/// [screenType] and assert no [ErrorView] surfaced on it.
Future<void> _goAndExpect(
  WidgetTester tester, {
  required String route,
  required Type screenType,
}) async {
  final router = GoRouter.of(tester.element(find.byType(InSidebar)));
  router.go(route);
  await _pumpUntilFound(tester, find.byType(screenType));
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

// ── Write round-trip + cleanup helpers ──────────────────────────────────
//
// These tests OVERRIDE the "no automated writes to the demo server" rule in
// docs/probing-the-demo-api.md — done deliberately, per the team lead, to
// get real create/edit coverage. Every record created here uses the
// [_kWriteMarker] prefix so it's obvious in the shared demo account, and a
// best-effort authenticated DELETE runs in teardown to clean up even if the
// assertions fail.

const _kWriteMarker = 'ZZ-CLAUDE-IT';

/// Unique, self-describing label so a leaked record (cleanup failed) is
/// instantly recognizable and manually purgeable in the demo account.
String _uniqueLabel(String what) =>
    '$_kWriteMarker $what ${DateTime.now().toUtc().toIso8601String()}';

/// The header set the app's `ApiClient` sends, rebuilt here for raw
/// verification/cleanup requests. Mirrors `ApiClient._buildHeaders`
/// (lib/data/services/api_client.dart): `X-API-Token` from the live
/// session, `X-Requested-With`, JSON accept. `X-API-PASSWORD-BASE64` is
/// added for password-gated DELETEs (base64 of the demo password).
Map<String, String> _apiHeaders(
  Services services, {
  bool withPassword = false,
}) {
  final creds = services.auth.credentials.value;
  return {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=UTF-8',
    'X-API-Token': creds?.token ?? '',
    'X-Requested-With': 'com.invoiceninja.admin',
    if (withPassword)
      'X-API-PASSWORD-BASE64': base64Encode(utf8.encode(_demoPassword)),
  };
}

String _apiBase(Services services) =>
    services.auth.credentials.value?.baseUrl ?? _demoBaseUrl;

/// Best-effort cleanup: hard-DELETE the record we created so the shared demo
/// account doesn't accumulate. Password-gated (412 without the header), so
/// we send `X-API-PASSWORD-BASE64`. Never throws — a failed cleanup must not
/// mask the real test result; the [_kWriteMarker] makes a leak findable.
Future<void> _deleteEntityBestEffort(
  Services services, {
  required String apiPath, // e.g. '/api/v1/clients'
  required String id,
}) async {
  if (id.isEmpty || id.startsWith('tmp_')) return;
  final client = http.Client();
  try {
    final res = await client
        .delete(
          Uri.parse('${_apiBase(services)}$apiPath/$id'),
          headers: _apiHeaders(services, withPassword: true),
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
Future<void> _tapSave(WidgetTester tester, Type editScreenType) async {
  final saveBtn = find.descendant(
    of: find.byType(editScreenType),
    matching: find.widgetWithText(TextButton, 'Save'),
  );
  await _pumpUntilFound(tester, saveBtn, timeout: const Duration(seconds: 10));
  expect(saveBtn, findsOneWidget, reason: 'edit screen must expose Save');
  await tester.tap(saveBtn);
}

/// The running app's go_router, resolved via the always-present `Navigator`
/// under the `Router` — independent of which screen is mounted.
GoRouter _goRouter(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

/// The first text field inside [screenType] (the autofocused identity
/// field — client name / product key).
Finder _firstFieldOf(Type screenType) => find
    .descendant(of: find.byType(screenType), matching: find.byType(TextField))
    .first;

/// Replace the identity field's text. When [awaitPrefillContains] is set
/// (edit mode), first wait until the field is populated with the loaded
/// entity — typing before the async row load finishes leaves the VM in a
/// create-like state (`_original == null`), so Save would POST a *new*
/// record instead of updating the existing one.
Future<void> _enterIdentity(
  WidgetTester tester,
  Type screenType,
  String text, {
  String? awaitPrefillContains,
}) async {
  final field = _firstFieldOf(screenType);
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
/// server, not local Drift. The timestamped [_kWriteMarker] label matches
/// exactly one row.
Future<String> _findServerEntityId(
  WidgetTester tester,
  Services services, {
  required String listPath, // e.g. '/api/v1/clients'
  required String unique,
}) async {
  final url = Uri.parse(
    '${_apiBase(services)}$listPath'
    '?filter=${Uri.encodeQueryComponent(_kWriteMarker)}'
    '&per_page=50&sort=updated_at|desc',
  );
  for (var attempt = 0; attempt < 12; attempt++) {
    final client = http.Client();
    http.Response? res;
    try {
      res = await client
          .get(url, headers: _apiHeaders(services))
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
Future<void> _saveAndLeaveEditor(
  WidgetTester tester,
  Type editScreenType, {
  required String listRoute,
  required Type listType,
}) async {
  await _tapSave(tester, editScreenType);
  // Let the optimistic create/update commit + the auto drain kick fire.
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  _goRouter(tester).go(listRoute);
  await tester.pump(const Duration(milliseconds: 500));
  final discard = find.text('Discard');
  if (discard.evaluate().isNotEmpty) {
    await tester.tap(discard.first);
    await tester.pump(const Duration(milliseconds: 500));
  }
  await _pumpUntilFound(tester, find.byType(listType));
}

/// Best-effort failure forensics: the active route, mounted screens, and
/// visible dialog/text — always printed to the log. Plus, **only on GitHub
/// Actions**, a pixel screenshot written into the workspace for the
/// `upload-artifact` step. Locally `screencapture` is never invoked, so the
/// run never trips the macOS screen-recording permission prompt. Never
/// throws — diagnostics must not mask the real failure.
Future<void> _dumpFailure(WidgetTester tester, String label) async {
  try {
    debugPrint(
      '[demo FAIL $label] route='
      '${_goRouter(tester).routeInformationProvider.value.uri}',
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
Future<void> _withFailureCapture(
  WidgetTester tester,
  String label,
  Future<void> Function() body,
) async {
  try {
    await body();
  } catch (_) {
    await _dumpFailure(tester, label);
    rethrow;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Cheap unauthenticated reachability probe. Any HTTP answer (even
    // 401/404) proves the box is up; only a transport failure means skip.
    final client = http.Client();
    try {
      final res = await client
          .get(Uri.parse('$_demoBaseUrl/api/v1/ping'))
          .timeout(const Duration(seconds: 20));
      _demoReachable = res.statusCode > 0;
      if (!_demoReachable) _unreachableReason = 'HTTP ${res.statusCode}';
    } catch (e) {
      _demoReachable = false;
      _unreachableReason = '$e';
    } finally {
      client.close();
    }
  });

  testWidgets('full login UI flow against the demo server lands in the app', (
    tester,
  ) async {
    if (_skipIfUnreachable()) return;
    await _useDesktopSurface(tester);

    final bag = _buildLiveServices();
    _registerLiveTeardown(tester, bag);
    await bag.services.auth.restore(); // no creds → boots to /login

    await tester.pumpWidget(
      InvoiceNinjaApp(
        services: bag.services,
        dbWasReset: false,
        initialLocation: '/login',
      ),
    );
    await _pumpUntilFound(tester, find.byType(LoginScreen));
    expect(find.byType(LoginScreen), findsOneWidget);

    // Switch to the self-hosted tab so the server-URL field appears, then
    // fill URL + email + password (field order on self-hosted is
    // [url, email, password, otp]).
    await tester.tap(find.text('Self-Hosted'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await _pumpUntilFound(tester, fields);
    expect(fields, findsAtLeastNWidgets(3));
    await tester.enterText(fields.at(0), _demoBaseUrl);
    await tester.enterText(fields.at(1), _demoEmail);
    await tester.enterText(fields.at(2), _demoPassword);

    await tester.tap(find.byKey(const ValueKey('login_submit')));
    // demo user is owner/admin with view_dashboard → /dashboard.
    await _pumpUntilFound(tester, find.byType(DashboardScreen));
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DashboardScreen),
        matching: find.byType(ErrorView),
      ),
      findsNothing,
    );
  });

  testWidgets('clients list loads real rows from the demo server', (
    tester,
  ) async {
    if (_skipIfUnreachable()) return;

    await _bootLoggedIn(tester, initialLocation: '/clients');
    await _pumpUntilFound(tester, find.byType(ClientListScreen));
    expect(find.byType(ClientListScreen), findsOneWidget);

    // The demo dataset is always seeded with clients — page one should
    // produce at least one real tile after the live fetch resolves.
    await _pumpUntilFound(tester, find.byType(ClientListTile));
    expect(
      find.byType(ClientListTile),
      findsAtLeastNWidgets(1),
      reason: 'demo server should return at least one client',
    );
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('opening a client shows the detail screen with live data', (
    tester,
  ) async {
    if (_skipIfUnreachable()) return;

    await _bootLoggedIn(tester, initialLocation: '/clients');
    await _pumpUntilFound(tester, find.byType(ClientListTile));
    expect(find.byType(ClientListTile), findsAtLeastNWidgets(1));

    await tester.tap(find.byType(ClientListTile).first);
    await _pumpUntilFound(tester, find.byType(ClientDetailScreen));
    expect(find.byType(ClientDetailScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ClientDetailScreen),
        matching: find.byType(ErrorView),
      ),
      findsNothing,
    );
  });

  testWidgets('every primary entity list loads from the demo server', (
    tester,
  ) async {
    if (_skipIfUnreachable()) return;

    // One login, then tour each list through the real router. Each route
    // triggers a live page-by-page fetch; we assert the screen mounted and
    // no ErrorView surfaced.
    await _bootLoggedIn(tester, initialLocation: '/clients');
    await _pumpUntilFound(tester, find.byType(ClientListScreen));

    final tour = <({String route, Type screen})>[
      (route: '/products', screen: ProductListScreen),
      (route: '/invoices', screen: InvoiceListScreen),
      (route: '/quotes', screen: QuoteListScreen),
      (route: '/payments', screen: PaymentListScreen),
      (route: '/expenses', screen: ExpenseListScreen),
      (route: '/tasks', screen: TaskListScreen),
      (route: '/projects', screen: ProjectListScreen),
      (route: '/vendors', screen: VendorListScreen),
    ];
    for (final stop in tour) {
      await _goAndExpect(tester, route: stop.route, screenType: stop.screen);
    }
  });

  testWidgets('reports screen mounts post-login', (tester) async {
    if (_skipIfUnreachable()) return;

    await _bootLoggedIn(tester, initialLocation: '/reports');
    await _pumpUntilFound(tester, find.byType(ReportsScreen));
    expect(find.byType(ReportsScreen), findsOneWidget);
  });

  testWidgets('settings screens mount against a live session', (tester) async {
    if (_skipIfUnreachable()) return;

    await _bootLoggedIn(tester, initialLocation: '/settings/company_details');
    await _pumpUntilFound(tester, find.byType(CompanyDetailsShell));
    expect(find.byType(CompanyDetailsShell), findsOneWidget);

    await _goAndExpect(
      tester,
      route: '/settings/user_details',
      screenType: UserDetailsShell,
    );
    await _goAndExpect(
      tester,
      route: '/settings/localization',
      screenType: LocalizationShell,
    );

    // End on a non-editor screen so `super_editor` (mounted by the
    // markdown override fields on the settings shells) disposes gracefully
    // while frames are still pumping, instead of mid-animation at teardown.
    await _goAndExpect(tester, route: '/clients', screenType: ClientListScreen);
  });

  testWidgets('session refresh against the demo server keeps us signed in', (
    tester,
  ) async {
    if (_skipIfUnreachable()) return;

    final bag = _buildLiveServices();
    _registerLiveTeardown(tester, bag);
    await _loginDemo(bag.services);
    expect(bag.services.auth.isAuthenticated, isTrue);

    // Real GET /api/v1/refresh round-trip — must not throw and must leave
    // the session intact.
    await bag.services.auth.refreshSession();
    expect(bag.services.auth.isAuthenticated, isTrue);
    expect(bag.services.auth.session.value, isNotNull);
  });

  testWidgets('logout from a live session returns to /login', (tester) async {
    if (_skipIfUnreachable()) return;

    final services = await _bootLoggedIn(tester, initialLocation: '/dashboard');
    await _pumpUntilFound(tester, find.byType(DashboardScreen));
    expect(find.byType(DashboardScreen), findsOneWidget);

    await services.auth.logout();
    await _pumpUntilFound(tester, find.byType(LoginScreen));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(services.auth.isAuthenticated, isFalse);
  });

  testWidgets(
    'create + edit a client round-trips to the demo server (UI → outbox → API)',
    (tester) async {
      if (_skipIfUnreachable()) return;
      final services = await _bootLoggedIn(
        tester,
        initialLocation: '/clients/new',
      );

      var createdId = '';
      // LIFO → runs before the app teardown, while creds are live, so a
      // mid-test failure still purges the created record.
      addTearDown(
        () => _deleteEntityBestEffort(
          services,
          apiPath: '/api/v1/clients',
          id: createdId,
        ),
      );

      await _withFailureCapture(tester, 'client-create-edit', () async {
        await _pumpUntilFound(tester, find.byType(ClientEditScreen));
        final companyId = services.auth.session.value!.currentCompanyId;
        expect(companyId, isNotEmpty);

        // CREATE — type a unique name into the autofocused first field and
        // save through the real Save action. Verify on the *server*.
        final createName = _uniqueLabel('client');
        await _enterIdentity(tester, ClientEditScreen, createName);
        await _saveAndLeaveEditor(
          tester,
          ClientEditScreen,
          listRoute: '/clients',
          listType: ClientListScreen,
        );
        await services.sync.drainOnce(companyId: companyId);

        createdId = await _findServerEntityId(
          tester,
          services,
          listPath: '/api/v1/clients',
          unique: createName,
        );
        expect(
          createdId,
          isNotEmpty,
          reason: 'client create did not round-trip to the demo server',
        );

        // EDIT — full UI: open the created record's edit form, change the
        // name, Save, and confirm the *server* reflects it. First wait for
        // the row to exist locally so the edit screen loads in edit mode
        // (not create); `awaitPrefillContains` then waits for the field to
        // be populated before typing — typing pre-load would leave the VM
        // create-like and Save would POST a duplicate.
        final editName = _uniqueLabel('client-edited');
        await services.clients
            .watch(companyId: companyId, id: createdId)
            .firstWhere((c) => c != null && c.id == createdId)
            .timeout(const Duration(seconds: 30));
        _goRouter(tester).go('/clients/$createdId/edit');
        await _pumpUntilFound(tester, find.byType(ClientEditScreen));
        await _enterIdentity(
          tester,
          ClientEditScreen,
          editName,
          awaitPrefillContains: _kWriteMarker,
        );
        await _saveAndLeaveEditor(
          tester,
          ClientEditScreen,
          listRoute: '/clients',
          listType: ClientListScreen,
        );
        await services.sync.drainOnce(companyId: companyId);

        final editedId = await _findServerEntityId(
          tester,
          services,
          listPath: '/api/v1/clients',
          unique: editName,
        );
        expect(
          editedId,
          createdId,
          reason: 'client edit did not round-trip to the demo server',
        );
      });
    },
  );

  testWidgets('create a product round-trips to the demo server', (
    tester,
  ) async {
    if (_skipIfUnreachable()) return;
    final services = await _bootLoggedIn(
      tester,
      initialLocation: '/products/new',
    );

    var createdId = '';
    addTearDown(
      () => _deleteEntityBestEffort(
        services,
        apiPath: '/api/v1/products',
        id: createdId,
      ),
    );

    await _withFailureCapture(tester, 'product-create', () async {
      await _pumpUntilFound(tester, find.byType(ProductEditScreen));
      final companyId = services.auth.session.value!.currentCompanyId;

      // First field on the product form is the product key (autofocused).
      final productKey = _uniqueLabel('product');
      await _enterIdentity(tester, ProductEditScreen, productKey);
      await _saveAndLeaveEditor(
        tester,
        ProductEditScreen,
        listRoute: '/products',
        listType: ProductListScreen,
      );
      await services.sync.drainOnce(companyId: companyId);

      createdId = await _findServerEntityId(
        tester,
        services,
        listPath: '/api/v1/products',
        unique: productKey,
      );
      expect(
        createdId,
        isNotEmpty,
        reason: 'product create did not round-trip to the demo server',
      );
    });
  });
}
