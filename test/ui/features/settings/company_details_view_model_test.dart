import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// `CompanyRepository` subclass that lets each test wire a custom `watch`
/// stream + skip the network refresh, so we can drive every code path
/// without touching real Drift / HTTP.
class _StubCompanyRepository extends CompanyRepository {
  _StubCompanyRepository({
    required super.db,
    required super.api,
    required this.watchStream,
  });

  final Stream<Company?> watchStream;
  int refreshCalls = 0;

  @override
  Stream<Company?> watchCompany(String companyId) => watchStream;

  @override
  Future<void> refresh(String companyId) async {
    refreshCalls += 1;
  }
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async {
    await db.close();
  });

  Future<void> seedCompany(String id) async {
    await db.companiesDao.upsertAll([
      CompaniesCompanion.insert(
        id: id,
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
  }

  /// Yield once so the VM's `_watchSub.listen` delivers any pending events.
  Future<void> tick() => Future<void>.delayed(Duration.zero);

  Company emptyCompany(String id, {String name = ''}) => Company(
    id: id,
    name: name,
    settings: CompanySettingsApi(name: name.isEmpty ? null : name),
  );

  group('CompanyDetailsViewModel.load', () {
    test(
      'happy path: first watch emission flips isLoaded and seeds draft',
      () async {
        await seedCompany('co');
        final repo = CompanyRepository(
          db: db,
          api: _FakeCompaniesApi(),
          uuid: const Uuid(),
        );
        final vm = CompanyDetailsViewModel(repo: repo, companyId: 'co');

        await vm.load();
        await tick();

        expect(vm.isLoaded, isTrue);
        expect(vm.draft, isNotNull);
        expect(vm.draft!.id, 'co');
        expect(vm.loadError, isNull);
        vm.dispose();
      },
    );

    test('watch error clears the spinner and surfaces the error', () async {
      // Regression net for the perpetual-spinner bug: a throw on the watch
      // path must not leave `isLoaded` false.
      final controller = StreamController<Company?>();
      final repo = _StubCompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        watchStream: controller.stream,
      );
      final vm = CompanyDetailsViewModel(repo: repo, companyId: 'co');

      await vm.load();
      controller.addError(StateError('boom'));
      await tick();

      expect(vm.isLoaded, isTrue, reason: 'spinner must clear');
      expect(vm.draft, isNotNull, reason: 'draft falls back to empty Company');
      expect(vm.loadError, contains('boom'));
      await controller.close();
      vm.dispose();
    });

    test('load is idempotent — re-subscribing is a no-op', () async {
      final controller = StreamController<Company?>.broadcast();
      final repo = _StubCompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        watchStream: controller.stream,
      );
      final vm = CompanyDetailsViewModel(repo: repo, companyId: 'co');
      await vm.load();
      await vm.load();
      expect(
        repo.refreshCalls,
        1,
        reason: 'refresh should only fire on the first load()',
      );
      await controller.close();
      vm.dispose();
    });

    test(
      'background refresh updates baseline; preserves dirty draft',
      () async {
        // Sequence: watch emits an "old" company → user edits → watch emits a
        // "fresh" company from the background refresh.
        //
        // The user's in-progress edit must survive (`_draft` stays as their
        // edit), but the baseline (`_initial`) must move to the fresh value so
        // saving sends only the user's actual change.
        final controller = StreamController<Company?>();
        final repo = _StubCompanyRepository(
          db: db,
          api: _FakeCompaniesApi(),
          watchStream: controller.stream,
        );
        final vm = CompanyDetailsViewModel(repo: repo, companyId: 'co');

        await vm.load();
        controller.add(emptyCompany('co', name: 'Old Name'));
        await tick();
        expect(vm.draft!.settings.name, 'Old Name');

        // User edits.
        vm.updateSettings((s) => s.copyWith(name: 'User Edit'));
        expect(vm.isDirty, isTrue);

        // Background refresh lands with a fresher server snapshot.
        controller.add(emptyCompany('co', name: 'Fresh From Server'));
        await tick();

        expect(
          vm.draft!.settings.name,
          'User Edit',
          reason: 'user edit must survive a refresh',
        );
        expect(
          vm.isDirty,
          isTrue,
          reason: 'dirty diff is now between baseline (Fresh) and draft (User)',
        );

        await controller.close();
        vm.dispose();
      },
    );

    test(
      'refresh emission while clean updates the draft to the server value',
      () async {
        final controller = StreamController<Company?>();
        final repo = _StubCompanyRepository(
          db: db,
          api: _FakeCompaniesApi(),
          watchStream: controller.stream,
        );
        final vm = CompanyDetailsViewModel(repo: repo, companyId: 'co');

        await vm.load();
        controller.add(emptyCompany('co', name: 'Initial'));
        await tick();
        expect(vm.draft!.settings.name, 'Initial');
        expect(vm.isDirty, isFalse);

        // Server refresh lands while the user hasn't touched anything.
        controller.add(emptyCompany('co', name: 'Fresh'));
        await tick();

        expect(vm.draft!.settings.name, 'Fresh');
        expect(vm.isDirty, isFalse);

        await controller.close();
        vm.dispose();
      },
    );
  });
}
