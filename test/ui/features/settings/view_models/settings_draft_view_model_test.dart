import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Stub repository that lets each test wire a custom `watch` stream, skip the
/// network refresh, and optionally inject a save failure.
class _StubCompanyRepository extends CompanyRepository {
  _StubCompanyRepository({
    required super.db,
    required super.api,
    required this.watchStream,
    this.onUpdate,
  });

  final Stream<Company?> watchStream;
  Future<void> Function(Company draft)? onUpdate;

  @override
  Stream<Company?> watchCompany(String companyId) => watchStream;

  @override
  Future<void> refresh(String companyId) async {}

  @override
  Future<void> updateCompany({required Company draft}) async {
    final hook = onUpdate;
    if (hook != null) await hook(draft);
  }
}

/// Minimal concrete subclass so we exercise the base class behaviour
/// directly — no `CompanyDetailsViewModel`-specific code reachable.
class _TestSettingsViewModel extends SettingsDraftViewModel {
  _TestSettingsViewModel({required super.repo, required super.companyId});
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async {
    await db.close();
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  Company company(String id, {String? name}) => Company(
    id: id,
    name: name ?? '',
    settings: CompanySettingsApi(name: name),
  );

  group('setOverride routes through the bindings table', () {
    test('enable seeds the field with the cascaded value', () async {
      final controller = StreamController<Company?>();
      final repo = _StubCompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        watchStream: controller.stream,
      );
      final vm = _TestSettingsViewModel(repo: repo, companyId: 'co');

      await vm.load();
      controller.add(company('co'));
      await tick();

      vm.setOverride(
        apiKey: 'vat_number',
        enabled: true,
        cascadedValue: 'EU123',
      );

      expect(vm.settings.vatNumber, 'EU123');
      expect(vm.isOverridden('vat_number'), isTrue);

      await controller.close();
      vm.dispose();
    });

    test('disable nulls the field', () async {
      final controller = StreamController<Company?>();
      final repo = _StubCompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        watchStream: controller.stream,
      );
      final vm = _TestSettingsViewModel(repo: repo, companyId: 'co');

      await vm.load();
      controller.add(
        Company(
          id: 'co',
          settings: const CompanySettingsApi(vatNumber: 'EU999'),
        ),
      );
      await tick();
      expect(vm.settings.vatNumber, 'EU999');

      vm.setOverride(apiKey: 'vat_number', enabled: false);

      expect(vm.settings.vatNumber, isNull);
      expect(vm.isOverridden('vat_number'), isFalse);

      await controller.close();
      vm.dispose();
    });

    test('unknown apiKey throws StateError', () async {
      final controller = StreamController<Company?>();
      final repo = _StubCompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        watchStream: controller.stream,
      );
      final vm = _TestSettingsViewModel(repo: repo, companyId: 'co');
      await vm.load();
      controller.add(company('co'));
      await tick();

      expect(
        () => vm.setOverride(
          apiKey: 'totally_made_up_key',
          enabled: true,
          cascadedValue: 'x',
        ),
        throwsStateError,
      );

      await controller.close();
      vm.dispose();
    });
  });

  group('fieldErrors', () {
    test(
      'save populates fieldErrors when repo throws ValidationException',
      () async {
        final controller = StreamController<Company?>();
        final repo = _StubCompanyRepository(
          db: db,
          api: _FakeCompaniesApi(),
          watchStream: controller.stream,
          onUpdate: (_) async =>
              throw const ValidationException('The given data was invalid.', {
                'settings.email': ['Email is not valid'],
              }),
        );
        final vm = _TestSettingsViewModel(repo: repo, companyId: 'co');

        await vm.load();
        controller.add(company('co'));
        await tick();
        vm.updateSettings((s) => s.copyWith(email: 'bogus'));

        final result = await vm.save();
        expect(result, isNull);
        expect(vm.fieldErrors['settings.email'], ['Email is not valid']);
        expect(vm.submitError, contains('given data was invalid'));

        await controller.close();
        vm.dispose();
      },
    );

    test('updateSettings clears fieldErrors on next edit', () async {
      final controller = StreamController<Company?>();
      final repo = _StubCompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        watchStream: controller.stream,
        onUpdate: (_) async => throw const ValidationException('bad', {
          'email': ['bad'],
        }),
      );
      final vm = _TestSettingsViewModel(repo: repo, companyId: 'co');
      await vm.load();
      controller.add(company('co'));
      await tick();
      vm.updateSettings((s) => s.copyWith(email: 'x'));
      await vm.save();
      expect(vm.fieldErrors, isNotEmpty);

      vm.updateSettings((s) => s.copyWith(email: 'fix'));
      expect(vm.fieldErrors, isEmpty);

      await controller.close();
      vm.dispose();
    });

    test('reset clears fieldErrors', () async {
      final controller = StreamController<Company?>();
      final repo = _StubCompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        watchStream: controller.stream,
        onUpdate: (_) async => throw const ValidationException('bad', {
          'email': ['bad'],
        }),
      );
      final vm = _TestSettingsViewModel(repo: repo, companyId: 'co');
      await vm.load();
      controller.add(company('co'));
      await tick();
      vm.updateSettings((s) => s.copyWith(email: 'x'));
      await vm.save();
      expect(vm.fieldErrors, isNotEmpty);

      vm.reset();
      expect(vm.fieldErrors, isEmpty);
      expect(vm.submitError, isNull);

      await controller.close();
      vm.dispose();
    });

    test('save success flushes any prior fieldErrors', () async {
      var calls = 0;
      final controller = StreamController<Company?>();
      final repo = _StubCompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        watchStream: controller.stream,
        onUpdate: (_) async {
          calls += 1;
          if (calls == 1) {
            throw const ValidationException('bad', {
              'email': ['bad'],
            });
          }
        },
      );
      final vm = _TestSettingsViewModel(repo: repo, companyId: 'co');
      await vm.load();
      controller.add(company('co'));
      await tick();

      vm.updateSettings((s) => s.copyWith(email: 'x'));
      await vm.save();
      expect(vm.fieldErrors, isNotEmpty);

      // Touch a field then re-save — succeeds. Errors must be cleared.
      vm.updateSettings((s) => s.copyWith(email: 'fix'));
      final result = await vm.save();
      expect(result, isNotNull);
      expect(vm.fieldErrors, isEmpty);

      await controller.close();
      vm.dispose();
    });
  });

  group('save', () {
    test(
      'returns the saved Company on success and advances the baseline',
      () async {
        final controller = StreamController<Company?>();
        final repo = _StubCompanyRepository(
          db: db,
          api: _FakeCompaniesApi(),
          watchStream: controller.stream,
        );
        final vm = _TestSettingsViewModel(repo: repo, companyId: 'co');
        await vm.load();
        controller.add(company('co'));
        await tick();
        vm.updateSettings((s) => s.copyWith(name: 'New'));
        expect(vm.isDirty, isTrue);

        final result = await vm.save();
        expect(result, isNotNull);
        expect(vm.isDirty, isFalse, reason: 'baseline moves to draft on save');
        expect(vm.submitError, isNull);

        await controller.close();
        vm.dispose();
      },
    );

    test('generic exception lands in submitError', () async {
      final controller = StreamController<Company?>();
      final repo = _StubCompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        watchStream: controller.stream,
        onUpdate: (_) async => throw Exception('disk full'),
      );
      final vm = _TestSettingsViewModel(repo: repo, companyId: 'co');
      await vm.load();
      controller.add(company('co'));
      await tick();

      vm.updateSettings((s) => s.copyWith(name: 'x'));
      final result = await vm.save();
      expect(result, isNull);
      expect(vm.submitError, contains('disk full'));
      expect(vm.fieldErrors, isEmpty);

      await controller.close();
      vm.dispose();
    });
  });

  group('Drift seed helper', () {
    // Anchor for future Drift-roundtrip tests at the base layer — keeps the
    // pattern obvious for the next entity/setting added.
    test('seed-and-watch is wired correctly', () async {
      await db.companiesDao.upsertAll([
        CompaniesCompanion.insert(
          id: 'co',
          name: 'Acme',
          displayName: const Value('Acme'),
          settings: '{"name":"Acme"}',
          customFields: const Value('{}'),
          permissions: '',
          accountId: 'acct',
          token: 'tok',
          updatedAt: 1700000000,
        ),
      ]);
      // Just check the row is fetchable via the repo's watch path.
      // (Full repo+VM round-trip is covered by company_details_view_model_test.)
      final row = await db.companiesDao.byId('co');
      expect(row, isNotNull);
      expect(row!.name, 'Acme');
    });
  });
}
