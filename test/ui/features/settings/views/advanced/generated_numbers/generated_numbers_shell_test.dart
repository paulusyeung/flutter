import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/generated_numbers_shell.dart';

import '../../../../../../_localization_helper.dart';

/// Stand-in [CompanyRepository] that emits a single [Company] on
/// `watchCompany`, mirroring the helper from `custom_fields_shell_test.dart`.
class _StubCompanyRepo extends CompanyRepository {
  _StubCompanyRepo({
    required super.db,
    required super.api,
    required this.company,
  });

  final Company company;
  final _controllers = <String, StreamController<Company?>>{};

  @override
  Stream<Company?> watchCompany(String companyId) {
    final c = _controllers.putIfAbsent(
      companyId,
      StreamController<Company?>.broadcast,
    );
    Future.microtask(() {
      if (!c.isClosed) c.add(company);
    });
    return c.stream;
  }

  @override
  Future<void> refresh(String companyId) async {}
}

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeClientsApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAuth implements AuthRepository {
  _FakeAuth(this._session);
  final ValueNotifier<AuthSession?> _session;
  @override
  ValueListenable<AuthSession?> get session => _session;
  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeServices implements Services {
  _FakeServices({
    required this.auth,
    required this.company,
    required this.clients,
    required this.db,
    required this.settingsLevel,
    required this.unsavedChangesGuard,
  });
  @override
  final AuthRepository auth;
  @override
  final CompanyRepository company;
  @override
  final ClientRepository clients;
  @override
  final AppDatabase db;
  @override
  final SettingsLevelController settingsLevel;
  @override
  final UnsavedChangesGuard unsavedChangesGuard;

  // The Settings tab body calls `services.formatterFor` in initState (with an
  // `onError` handler) so the `Next Reset` date field can render in the
  // user's date format. Returning a failed future here exercises the
  // production failure path — the date field stays hidden, the rest of the
  // form continues to work.
  @override
  Future<Formatter> formatterFor(String companyId) =>
      Future.error(StateError('statics not stubbed in this test'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

AuthSession _session() => const AuthSession(
  baseUrl: 'https://example.test',
  isHosted: false,
  accountId: 'acct',
  companies: [],
  currentCompanyId: 'co-A',
  plan: 'pro',
);

int _allEntityModules() =>
    EnabledModule.invoices.bitmask |
    EnabledModule.recurringInvoices.bitmask |
    EnabledModule.quotes.bitmask |
    EnabledModule.credits.bitmask |
    EnabledModule.projects.bitmask |
    EnabledModule.tasks.bitmask |
    EnabledModule.vendors.bitmask |
    EnabledModule.purchaseOrders.bitmask |
    EnabledModule.expenses.bitmask |
    EnabledModule.recurringExpenses.bitmask;

/// Mount the shell behind a minimal GoRouter so `context.go` calls work.
/// Default location is the bare URL — that matches the controller's
/// initial index 0, so the shell's post-frame `animateTo` is a no-op
/// (otherwise the TabBar's scroll viewport, which hasn't been laid out
/// in the first frame, blows up with a null `viewportDimension`).
/// The Settings body's `formatterFor` call surfaces as an async error
/// against the unstubbed `services.statics`; the body swallows it and
/// the date field stays hidden — exactly the production failure mode.
Widget _host({
  required Services services,
  String initialLocation = '/settings/generated_numbers',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/settings/generated_numbers',
        builder: (_, _) => const GeneratedNumbersShell(),
        routes: [
          GoRoute(
            path: ':tab',
            builder: (_, state) =>
                GeneratedNumbersShell(initialTab: state.pathParameters['tab']),
          ),
        ],
      ),
    ],
  );
  return MaterialApp.router(
    theme: buildInTheme(InTheme.light),
    localizationsDelegates: kTestLocalizationsDelegates,
    supportedLocales: kTestSupportedLocales,
    routerConfig: router,
    builder: (_, child) => MultiProvider(
      providers: [
        Provider<Services>.value(value: services),
        ChangeNotifierProvider<SettingsLevelController>.value(
          value: services.settingsLevel,
        ),
      ],
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

void main() {
  late AppDatabase db;
  late _FakeCompaniesApi companiesApi;
  late _FakeClientsApi clientsApi;
  late ClientRepository clientRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    companiesApi = _FakeCompaniesApi();
    clientsApi = _FakeClientsApi();
    clientRepo = ClientRepository(db: db, api: clientsApi);
  });

  tearDown(() async {
    await db.close();
  });

  Services makeServices({required Company company}) {
    final repo = _StubCompanyRepo(db: db, api: companiesApi, company: company);
    return _FakeServices(
      auth: _FakeAuth(ValueNotifier(_session())),
      company: repo,
      clients: clientRepo,
      db: db,
      settingsLevel: SettingsLevelController(),
      unsavedChangesGuard: UnsavedChangesGuard(),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('all entity modules enabled → 13 tabs visible', (tester) async {
    final services = makeServices(
      company: Company(id: 'co-A', enabledModules: _allEntityModules()),
    );
    await tester.pumpWidget(_host(services: services));
    await settle(tester);

    // 13 tabs in display order. Text is the localized label.
    for (final label in const [
      'Settings',
      'Clients',
      'Invoices',
      'Recurring Invoices',
      'Payments',
      'Quotes',
      'Credits',
      'Projects',
      'Tasks',
      'Vendors',
      'Purchase Orders',
      'Expenses',
      'Recurring Expenses',
    ]) {
      expect(
        find.descendant(of: find.byType(Tab), matching: find.text(label)),
        findsOneWidget,
        reason: 'expected tab "$label" to be visible',
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('enabledModules = 0 → only Settings + Clients tabs render', (
    tester,
  ) async {
    final services = makeServices(
      company: const Company(id: 'co-A', enabledModules: 0),
    );
    await tester.pumpWidget(_host(services: services));
    await settle(tester);

    // Always-visible tabs.
    for (final label in const ['Settings', 'Clients']) {
      expect(
        find.descendant(of: find.byType(Tab), matching: find.text(label)),
        findsOneWidget,
      );
    }
    // Module-gated tabs should be absent.
    for (final label in const [
      'Invoices',
      'Recurring Invoices',
      'Payments',
      'Quotes',
      'Credits',
      'Projects',
      'Tasks',
      'Vendors',
      'Purchase Orders',
      'Expenses',
      'Recurring Expenses',
    ]) {
      expect(
        find.descendant(of: find.byType(Tab), matching: find.text(label)),
        findsNothing,
        reason: 'tab "$label" should be hidden when its module is disabled',
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'invoices module on without quotes/credits → no Payments tab gating bug',
    (tester) async {
      // Payments tab is gated on EnabledModule.invoices (mirroring React's
      // "payment numbers depend on invoices being on"). This regression-test
      // pins that behavior so a future drive-by edit doesn't silently lose
      // the Payments tab when only the Invoices module is on.
      final services = makeServices(
        company: Company(
          id: 'co-A',
          enabledModules: EnabledModule.invoices.bitmask,
        ),
      );
      await tester.pumpWidget(_host(services: services));
      await settle(tester);

      for (final label in const [
        'Settings',
        'Clients',
        'Invoices',
        'Payments',
      ]) {
        expect(
          find.descendant(of: find.byType(Tab), matching: find.text(label)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: find.byType(Tab), matching: find.text('Quotes')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('deep link to a hidden tab falls back to a visible tab', (
    tester,
  ) async {
    // Tasks module disabled but URL targets `/tasks`.
    final services = makeServices(
      company: const Company(id: 'co-A', enabledModules: 0),
    );
    await tester.pumpWidget(
      _host(
        services: services,
        initialLocation: '/settings/generated_numbers/tasks',
      ),
    );
    await settle(tester);

    expect(
      find.descendant(of: find.byType(Tab), matching: find.text('Tasks')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
