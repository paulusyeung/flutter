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
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_shell.dart';

import '../../../../../../_localization_helper.dart';

/// Stand-in [CompanyRepository] that emits a single [Company] on
/// `watchCompany`, mirroring the helper from `generated_numbers_shell_test.dart`.
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

/// Mount the shell behind a minimal GoRouter so `context.go` calls work. The
/// bare URL is index 0, so the tabbed shell's post-frame `animateTo` is a
/// no-op (a non-zero deep link would blow up the not-yet-laid-out TabBar
/// viewport).
Widget _host({
  required Services services,
  String initialLocation = '/settings/workflow_settings',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/settings/workflow_settings',
        builder: (_, _) => const WorkflowSettingsShell(),
        routes: [
          GoRoute(
            path: ':tab',
            builder: (_, state) =>
                WorkflowSettingsShell(initialTab: state.pathParameters['tab']),
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

  Finder tab(String label) =>
      find.descendant(of: find.byType(Tab), matching: find.text(label));

  testWidgets('both modules on → Invoices + Quotes tabs', (tester) async {
    final services = makeServices(
      company: Company(
        id: 'co-A',
        enabledModules:
            EnabledModule.invoices.bitmask | EnabledModule.quotes.bitmask,
      ),
    );
    await tester.pumpWidget(_host(services: services));
    await settle(tester);

    expect(find.byType(TabBar), findsOneWidget);
    expect(tab('Invoices'), findsOneWidget);
    expect(tab('Quotes'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('invoices only → single body, no TabBar (no >=2-tabs assert)', (
    tester,
  ) async {
    final services = makeServices(
      company: Company(
        id: 'co-A',
        enabledModules: EnabledModule.invoices.bitmask,
      ),
    );
    await tester.pumpWidget(_host(services: services));
    await settle(tester);

    // The bug: a single visible tab tripped `assert(tabs.length >= 2)` in
    // CascadeTabbedSettingsShell. The fix renders the lone body through the
    // non-tabbed CascadeSettingsScaffold instead — no tab bar, no assert.
    expect(tester.takeException(), isNull);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(Tab), findsNothing);
    // It's the Invoices body: only that body carries the `lock_invoices`
    // dropdown (DropdownButtonFormField<String>); the Quotes body has none.
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('quotes only → single body, no TabBar', (tester) async {
    final services = makeServices(
      company: Company(
        id: 'co-A',
        enabledModules: EnabledModule.quotes.bitmask,
      ),
    );
    await tester.pumpWidget(_host(services: services));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(Tab), findsNothing);
    // Quotes body has switch toggles but no dropdown.
    expect(find.byType(SwitchListTile), findsWidgets);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('both modules off → fallback to both tabs', (tester) async {
    // Only reachable via a hand-typed URL (the section is hidden from the
    // sidebar when both modules are off). The shell falls back to the full
    // two-tab set rather than an empty (or single-tab) shell.
    final services = makeServices(
      company: const Company(id: 'co-A', enabledModules: 0),
    );
    await tester.pumpWidget(_host(services: services));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(TabBar), findsOneWidget);
    expect(tab('Invoices'), findsOneWidget);
    expect(tab('Quotes'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
