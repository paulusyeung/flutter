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
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/views/basic/localization/custom_labels_screen.dart';
import 'package:admin/ui/features/settings/views/basic/localization/localization_screen.dart';
import 'package:admin/ui/features/settings/views/basic/localization/localization_shell.dart';

import '../../../../../../_localization_helper.dart';

/// Emits a single [Company] on `watchCompany` (company-scope path).
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

/// Throwing API client — `StaticsService.fetch` calls `getOne`, which throws;
/// `StaticsRepository.ensureLoaded` swallows it, leaving the typed maps empty.
class _FakeApiClient implements ApiClient {
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
    required this.statics,
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
  final StaticsRepository statics;
  @override
  final SettingsLevelController settingsLevel;
  @override
  final UnsavedChangesGuard unsavedChangesGuard;

  // The Settings body's currency-format preview calls `formatterFor` (with an
  // error handler); a failed future exercises the cold-start fallback (bare
  // option labels). `formatterIfReady` returning null leaves the date-format
  // preview locale unset — both are no-crash paths.
  @override
  Future<Formatter> formatterFor(String companyId) =>
      Future.error(StateError('statics not stubbed in this test'));

  @override
  Formatter? formatterIfReady(String companyId) => null;

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
/// no-op.
Widget _host({required Services services}) {
  final router = GoRouter(
    initialLocation: '/settings/localization',
    routes: [
      GoRoute(
        path: '/settings/localization',
        builder: (_, _) => const LocalizationShell(),
        routes: [
          GoRoute(
            path: ':tab',
            builder: (_, state) =>
                LocalizationShell(initialTab: state.pathParameters['tab']),
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
  late ClientRepository clientRepo;
  late StaticsRepository statics;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clientRepo = ClientRepository(db: db, api: _FakeClientsApi());
    statics = StaticsRepository(
      db: db,
      service: StaticsService(_FakeApiClient()),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Services makeServices(SettingsLevelController level) {
    return _FakeServices(
      auth: _FakeAuth(ValueNotifier(_session())),
      company: _StubCompanyRepo(
        db: db,
        api: _FakeCompaniesApi(),
        company: const Company(id: 'co-A'),
      ),
      clients: clientRepo,
      db: db,
      statics: statics,
      settingsLevel: level,
      unsavedChangesGuard: UnsavedChangesGuard(),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('company scope → tabbed shell with Settings + Custom Labels', (
    tester,
  ) async {
    final services = makeServices(SettingsLevelController());
    await tester.pumpWidget(_host(services: services));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(2));
    expect(find.byType(LocalizationSettingsBody), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('client scope → Custom Labels hidden, no TabBar', (tester) async {
    final level = SettingsLevelController()
      ..setLevel(SettingsLevel.client, targetId: 'client-1');
    final services = makeServices(level);
    await tester.pumpWidget(_host(services: services));
    await settle(tester);

    // Custom Labels is company-only: at client scope the shell drops the tab
    // bar and renders just the Settings body via CascadeSettingsScaffold.
    expect(tester.takeException(), isNull);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(Tab), findsNothing);
    expect(find.byType(LocalizationCustomLabelsBody), findsNothing);
    expect(find.byType(LocalizationSettingsBody), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
