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
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/clients/widgets/client_list_tile.dart';
import 'package:admin/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:admin/ui/features/expenses/views/expense_list_screen.dart';
import 'package:admin/ui/features/invoices/views/invoice_list_screen.dart';
import 'package:admin/ui/features/payments/views/payment_list_screen.dart';
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
}
