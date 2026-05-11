import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// `CompanyRepository` subclass that fails `get` on demand, so we can drive
/// the VM down the error path without needing a real `byId` to misbehave.
class _ThrowingCompanyRepository extends CompanyRepository {
  _ThrowingCompanyRepository({
    required super.db,
    required super.api,
    required this.error,
  });

  final Object error;

  @override
  Future<Null> get(String companyId) async {
    throw error;
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

  group('CompanyDetailsViewModel.load', () {
    test('happy path: isLoaded=true, draft populated, no error', () async {
      await seedCompany('co');
      final repo = CompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        uuid: const Uuid(),
      );
      final vm = CompanyDetailsViewModel(repo: repo, companyId: 'co');

      await vm.load();

      expect(vm.isLoaded, isTrue);
      expect(vm.draft, isNotNull);
      expect(vm.draft!.id, 'co');
      expect(vm.loadError, isNull);
    });

    test(
      'repo throw still clears the spinner and surfaces the error',
      () async {
        // This is the regression net for the perpetual-spinner bug: a throw
        // anywhere on the load path must not leave `isLoaded` false.
        final repo = _ThrowingCompanyRepository(
          db: db,
          api: _FakeCompaniesApi(),
          error: StateError('boom'),
        );
        final vm = CompanyDetailsViewModel(repo: repo, companyId: 'co');

        await vm.load();

        expect(vm.isLoaded, isTrue, reason: 'spinner must clear');
        expect(
          vm.draft,
          isNotNull,
          reason: 'draft falls back to empty Company',
        );
        expect(vm.loadError, contains('boom'));
      },
    );

    test('load is idempotent — re-running is a no-op once loaded', () async {
      await seedCompany('co');
      final repo = CompanyRepository(
        db: db,
        api: _FakeCompaniesApi(),
        uuid: const Uuid(),
      );
      final vm = CompanyDetailsViewModel(repo: repo, companyId: 'co');

      await vm.load();
      final first = vm.draft;
      await vm.load();
      expect(identical(vm.draft, first), isTrue);
    });
  });
}
