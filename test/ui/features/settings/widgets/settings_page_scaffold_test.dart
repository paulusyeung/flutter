import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';

import '../../../../_localization_helper.dart';

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StubRepo extends CompanyRepository {
  _StubRepo({required super.db, required super.api, required this.controller});
  final StreamController<Company?> controller;
  @override
  Stream<Company?> watchCompany(String companyId) => controller.stream;
  @override
  Future<void> refresh(String companyId) async {}
  @override
  Future<void> updateCompany({required Company draft}) async {}
}

class _TestVM extends SettingsDraftViewModel {
  _TestVM({required super.repo, required super.companyId});
}

/// Minimal Services stand-in — only the bits the scaffold reaches for via
/// [UnsavedChangesScope]. Other members throw so accidental reuse is loud.
class _FakeServices implements Services {
  _FakeServices(this.unsavedChangesGuard);
  @override
  final UnsavedChangesGuard unsavedChangesGuard;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Widget _host({required _TestVM vm, required Widget body}) => MaterialApp(
  theme: buildInTheme(InTheme.light),
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  home: MultiProvider(
    providers: [
      Provider<Services>.value(value: _FakeServices(UnsavedChangesGuard())),
      // The scope banner mounted by `SettingsScreenScaffold` reads this
      // off the ambient Provider chain. In production it's mounted once
      // at app root (`main.dart`); tests have to supply it explicitly.
      ChangeNotifierProvider<SettingsLevelController>(
        create: (_) => SettingsLevelController(),
      ),
    ],
    child: SettingsPageScaffold<_TestVM>(
      titleKey: 'company_details',
      viewModel: vm,
      body: body,
    ),
  ),
);

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async {
    await db.close();
  });

  Company company(String id, {String? name}) => Company(
    id: id,
    name: name ?? '',
    settings: CompanySettingsApi(name: name),
  );

  testWidgets('shows spinner before the VM has loaded', (tester) async {
    final controller = StreamController<Company?>();
    final repo = _StubRepo(
      db: db,
      api: _FakeCompaniesApi(),
      controller: controller,
    );
    final vm = _TestVM(repo: repo, companyId: 'co');
    await vm.load();

    await tester.pumpWidget(_host(vm: vm, body: const Text('PAGE_BODY')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('PAGE_BODY'), findsNothing);

    await controller.close();
    vm.dispose();
  });

  testWidgets('renders the body after the first emission', (tester) async {
    final controller = StreamController<Company?>();
    final repo = _StubRepo(
      db: db,
      api: _FakeCompaniesApi(),
      controller: controller,
    );
    final vm = _TestVM(repo: repo, companyId: 'co');
    await vm.load();

    await tester.pumpWidget(_host(vm: vm, body: const Text('PAGE_BODY')));
    controller.add(company('co', name: 'Acme'));
    await tester.pumpAndSettle();

    expect(find.text('PAGE_BODY'), findsOneWidget);

    await controller.close();
    vm.dispose();
  });

  testWidgets('Save button is disabled when the draft is clean', (
    tester,
  ) async {
    final controller = StreamController<Company?>();
    final repo = _StubRepo(
      db: db,
      api: _FakeCompaniesApi(),
      controller: controller,
    );
    final vm = _TestVM(repo: repo, companyId: 'co');
    await vm.load();

    await tester.pumpWidget(_host(vm: vm, body: const Text('PAGE_BODY')));
    controller.add(company('co', name: 'Acme'));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<TextButton>(find.byType(TextButton));
    expect(saveButton.onPressed, isNull);

    await controller.close();
    vm.dispose();
  });

  testWidgets('Save button is enabled once the draft is dirty', (tester) async {
    final controller = StreamController<Company?>();
    final repo = _StubRepo(
      db: db,
      api: _FakeCompaniesApi(),
      controller: controller,
    );
    final vm = _TestVM(repo: repo, companyId: 'co');
    await vm.load();

    await tester.pumpWidget(_host(vm: vm, body: const Text('PAGE_BODY')));
    controller.add(company('co', name: 'Acme'));
    await tester.pumpAndSettle();

    vm.updateSettings((s) => s.copyWith(name: 'NewName'));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<TextButton>(find.byType(TextButton));
    expect(saveButton.onPressed, isNotNull);

    await controller.close();
    vm.dispose();
  });

  testWidgets('loadError banner appears above the body', (tester) async {
    final controller = StreamController<Company?>();
    final repo = _StubRepo(
      db: db,
      api: _FakeCompaniesApi(),
      controller: controller,
    );
    final vm = _TestVM(repo: repo, companyId: 'co');
    await vm.load();

    await tester.pumpWidget(_host(vm: vm, body: const Text('PAGE_BODY')));
    controller.addError(StateError('parse failed: bad field'));
    await tester.pumpAndSettle();

    // Banner shows the error message verbatim (alongside a localized header).
    expect(find.textContaining('parse failed: bad field'), findsOneWidget);
    expect(find.text('PAGE_BODY'), findsOneWidget);

    await controller.close();
    vm.dispose();
  });
}
