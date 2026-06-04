import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/ui/features/settings/view_models/client_settings_draft_view_model.dart';

class _FakeClientsApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Guards the client-scope fix for Settings → Tax Settings: at client scope
/// `draft` is null (the cascade body would early-return blank), so the body
/// reads company-level fields (tax-rate slot counts, decimal separator) via
/// `companyContext`. This pins that the client-scoped host actually surfaces
/// the loaded company's values there.
void main() {
  late AppDatabase db;
  late ClientRepository clientRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clientRepo = ClientRepository(db: db, api: _FakeClientsApi());
  });
  tearDown(() async {
    await db.close();
  });

  test(
    'companyContext surfaces the company tax counts at client scope',
    () async {
      await db.companiesDao.upsertAll([
        CompaniesCompanion.insert(
          id: 'co-A',
          name: 'Acme',
          settings: '{}',
          permissions: '',
          accountId: 'acct',
          token: 'tok',
          updatedAt: 1700000000,
          enabledTaxRates: const Value(2),
          enabledItemTaxRates: const Value(1),
          useCommaAsDecimalPlace: const Value(true),
        ),
      ]);

      final vm = ClientSettingsDraftViewModel(
        repo: clientRepo,
        db: db,
        companyId: 'co-A',
        clientId: 'client-1',
      );

      // draft is null at client scope — the early-return bug this fix removes.
      expect(vm.draft, isNull);

      await vm.load();

      // companyContext carries exactly the company-level fields the Tax Settings
      // body needs to render the default-rate pickers + decimal-aware display.
      expect(vm.companyContext, isNotNull);
      expect(vm.companyContext!.id, 'co-A');
      expect(vm.companyContext!.enabledTaxRates, 2);
      expect(vm.companyContext!.enabledItemTaxRates, 1);
      expect(vm.companyContext!.useCommaAsDecimalPlace, isTrue);

      vm.dispose();
    },
  );
}
