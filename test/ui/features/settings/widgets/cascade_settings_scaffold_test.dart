import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/app/design_tokens.dart';
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
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';

import '../../../../_localization_helper.dart';

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeClientsApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StubCompanyRepo extends CompanyRepository {
  _StubCompanyRepo({required super.db, required super.api});
  final _controllers = <String, StreamController<Company?>>{};
  StreamController<Company?> controllerFor(String id) =>
      _controllers.putIfAbsent(id, StreamController<Company?>.broadcast);

  @override
  Stream<Company?> watchCompany(String companyId) =>
      controllerFor(companyId).stream;
  @override
  Future<void> refresh(String companyId) async {}
}

class _CapturingVm extends SettingsDraftViewModel {
  _CapturingVm({required super.repo, required super.companyId});
}

/// Records every factory invocation so the test can assert it was called
/// with the expected company id and not double-invoked.
class _FactoryRecorder {
  final calls = <({String companyId, CompanyRepository repo})>[];
  SettingsDraftViewModel build({
    required CompanyRepository repo,
    required String companyId,
  }) {
    calls.add((companyId: companyId, repo: repo));
    return _CapturingVm(repo: repo, companyId: companyId);
  }
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

/// Test stand-in for [Services]. Returns real values for the five surfaces
/// `CascadeSettingsScaffold` touches; everything else throws.
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

Widget _host({
  required Services services,
  required CompanySettingsVmFactory factory,
}) => MaterialApp(
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
    child: CascadeSettingsScaffold(
      titleKey: 'localization',
      companyVmFactory: factory,
      body: const Text('PAGE_BODY'),
    ),
  ),
);

void main() {
  late AppDatabase db;
  late _FakeCompaniesApi companiesApi;
  late _FakeClientsApi clientsApi;
  late _StubCompanyRepo companyRepo;
  late ClientRepository clientRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    companiesApi = _FakeCompaniesApi();
    clientsApi = _FakeClientsApi();
    companyRepo = _StubCompanyRepo(db: db, api: companiesApi);
    clientRepo = ClientRepository(db: db, api: clientsApi);
  });
  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'at company scope, the factory is invoked with the active company id',
    (tester) async {
      final session = ValueNotifier<AuthSession?>(_sessionWith('co-A'));
      final services = _FakeServices(
        auth: _FakeAuth(session),
        company: companyRepo,
        clients: clientRepo,
        db: db,
        settingsLevel: SettingsLevelController(),
        unsavedChangesGuard: UnsavedChangesGuard(),
      );
      final recorder = _FactoryRecorder();

      await tester.pumpWidget(
        _host(services: services, factory: recorder.build),
      );
      await tester.pump();

      expect(recorder.calls, hasLength(1));
      expect(recorder.calls.single.companyId, 'co-A');
      expect(recorder.calls.single.repo, same(companyRepo));
    },
  );

  testWidgets('at client scope, the factory is NOT invoked', (tester) async {
    final session = ValueNotifier<AuthSession?>(_sessionWith('co-A'));
    final level = SettingsLevelController()
      ..setLevel(SettingsLevel.client, targetId: 'client-1');
    final services = _FakeServices(
      auth: _FakeAuth(session),
      company: companyRepo,
      clients: clientRepo,
      db: db,
      settingsLevel: level,
      unsavedChangesGuard: UnsavedChangesGuard(),
    );
    final recorder = _FactoryRecorder();

    await tester.pumpWidget(_host(services: services, factory: recorder.build));
    await tester.pumpAndSettle();

    // The scaffold should pick the ClientSettingsDraftViewModel branch and
    // skip the company-VM factory entirely.
    expect(recorder.calls, isEmpty);

    // Sanity: the host registered in the SettingsPageScaffold's Provider is
    // the client-scoped VM, confirming the dispatch.
    final BuildContext ctx = tester.element(find.text('PAGE_BODY'));
    expect(
      Provider.of<SettingsDraftHost>(ctx, listen: false),
      isA<ClientSettingsDraftViewModel>(),
    );

    // Tear the widget down inside the test so the Drift watch subscription
    // closes before `_verifyInvariants` runs (otherwise the periodic
    // StreamQueryStore timer trips the no-pending-timers invariant).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'company-switch swaps the VM and re-invokes the factory with the new id',
    (tester) async {
      final session = ValueNotifier<AuthSession?>(_sessionWith('co-A'));
      final services = _FakeServices(
        auth: _FakeAuth(session),
        company: companyRepo,
        clients: clientRepo,
        db: db,
        settingsLevel: SettingsLevelController(),
        unsavedChangesGuard: UnsavedChangesGuard(),
      );
      final recorder = _FactoryRecorder();

      await tester.pumpWidget(
        _host(services: services, factory: recorder.build),
      );
      await tester.pump();

      expect(recorder.calls.map((c) => c.companyId), ['co-A']);

      // Simulate the company picker flipping to a different company.
      session.value = _sessionWith('co-B');
      await tester.pump();

      expect(recorder.calls.map((c) => c.companyId), ['co-A', 'co-B']);
    },
  );
}
