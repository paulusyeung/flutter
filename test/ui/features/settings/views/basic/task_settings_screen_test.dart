import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/client_settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/view_models/task_settings_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/task_settings_screen.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

import '../../../../../_localization_helper.dart';

/// Regression guard for the client-scope mis-target bug: Task Settings used
/// `SettingsCompanyScopedHost` directly, so at client scope its cascade
/// `Overridable*` fields wrote to the *company* settings instead of the
/// client's override blob. The fix routes the screen through
/// `CascadeSettingsScaffold`, which swaps to a `ClientSettingsDraftViewModel`
/// at client scope. These tests pin the host the body binds to at each scope.

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeClientsApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Company repo stub: `watchCompany` returns a controller stream (never
/// emits in these tests — the host type is read from the always-present
/// scaffold chrome, above the loading spinner) and `refresh` is a no-op so
/// no `CompaniesApi` call is made.
class _StubCompanyRepo extends CompanyRepository {
  _StubCompanyRepo({required super.db, required super.api});
  final _controllers = <String, StreamController<Company?>>{};
  @override
  Stream<Company?> watchCompany(String companyId) => _controllers
      .putIfAbsent(companyId, StreamController<Company?>.broadcast)
      .stream;
  @override
  Future<void> refresh(String companyId) async {}
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

AuthSession _sessionWith(String companyId) => AuthSession(
  baseUrl: 'https://example.test',
  isHosted: false,
  accountId: 'acct',
  companies: const [],
  currentCompanyId: companyId,
);

void main() {
  late AppDatabase db;
  late _StubCompanyRepo companyRepo;
  late ClientRepository clientRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    companyRepo = _StubCompanyRepo(db: db, api: _FakeCompaniesApi());
    clientRepo = ClientRepository(db: db, api: _FakeClientsApi());
  });
  tearDown(() async {
    await db.close();
  });

  Widget host(Services services) => MaterialApp(
    theme: buildInTheme(InTheme.light),
    localizationsDelegates: kTestLocalizationsDelegates,
    supportedLocales: kTestSupportedLocales,
    home: MultiProvider(
      providers: [
        Provider<Services>.value(value: services),
        ChangeNotifierProvider<SettingsLevelController>.value(
          value: services.settingsLevel,
        ),
      ],
      child: const TaskSettingsScreen(),
    ),
  );

  // Read the SettingsDraftHost the body is bound to, from the scaffold chrome
  // (present regardless of load state, so we don't have to wait out the
  // loading spinner's infinite animation).
  SettingsDraftHost hostOf(WidgetTester tester) {
    final ctx = tester.element(find.byType(SettingsScreenScaffold));
    return Provider.of<SettingsDraftHost>(ctx, listen: false);
  }

  testWidgets('at company scope, binds to the company TaskSettingsViewModel', (
    tester,
  ) async {
    final services = _FakeServices(
      auth: _FakeAuth(ValueNotifier(_sessionWith('co-A'))),
      company: companyRepo,
      clients: clientRepo,
      db: db,
      settingsLevel: SettingsLevelController(),
      unsavedChangesGuard: UnsavedChangesGuard(),
    );

    await tester.pumpWidget(host(services));
    await tester.pump();

    expect(hostOf(tester), isA<TaskSettingsViewModel>());

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'at client scope, binds to the client override VM (not the company)',
    (tester) async {
      await db.companiesDao.upsertAll([
        CompaniesCompanion.insert(
          id: 'co-A',
          name: 'Acme',
          settings: '{}',
          permissions: '',
          accountId: 'acct',
          token: 'tok',
          updatedAt: 1700000000,
          enabledModules: const Value(32767),
        ),
      ]);
      final level = SettingsLevelController()
        ..setLevel(
          SettingsLevel.client,
          targetId: 'client-1',
          targetName: 'Client One',
        );
      final services = _FakeServices(
        auth: _FakeAuth(ValueNotifier(_sessionWith('co-A'))),
        company: companyRepo,
        clients: clientRepo,
        db: db,
        settingsLevel: level,
        unsavedChangesGuard: UnsavedChangesGuard(),
      );

      await tester.pumpWidget(host(services));
      await tester.pump();

      // Before the fix this was a company-scoped TaskSettingsViewModel, so
      // edits PUT the company. It must now be the client-scoped VM.
      final bound = hostOf(tester);
      expect(bound, isA<ClientSettingsDraftViewModel>());
      expect(bound, isNot(isA<TaskSettingsViewModel>()));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
