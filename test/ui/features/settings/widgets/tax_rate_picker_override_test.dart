import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/ui/features/settings/view_models/client_settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/tax_rate_picker.dart';

class _FakeClientsApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Pins F7: the default-tax-rate picker's override checkbox is keyed on
/// `tax_name<slot>`, but name and rate are a denormalized pair — so clearing
/// the override must null BOTH `tax_name<slot>` and `tax_rate<slot>`. A naive
/// 1:1 `tax_name` binding would leave `tax_rate<slot>` overriding on its own
/// at client/group scope (an inherited name + a stale overridden rate).
void main() {
  group('TaxRatePicker.overrideBinding', () {
    test('disabling the override clears BOTH name and rate', () {
      const s = CompanySettings(taxName3: 'VAT', taxRate3: 19.0);
      final cleared = TaxRatePicker.overrideBinding(3, 0).write(s, null);
      expect(cleared.taxName3, isNull);
      expect(cleared.taxRate3, isNull);
    });

    test('enabling the override seeds name + the inherited rate', () {
      const s = CompanySettings();
      final set = TaxRatePicker.overrideBinding(2, 7.5).write(s, 'GST');
      expect(set.taxName2, 'GST');
      expect(set.taxRate2, 7.5);
    });

    test('read returns the slot name (drives override detection)', () {
      const s = CompanySettings(taxName1: 'VAT');
      expect(TaxRatePicker.overrideBinding(1, 0).read(s), 'VAT');
    });
  });

  group('client-scope override toggle-off (integration)', () {
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
      'toggling the rate override off leaves no dangling tax_rate',
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
          ),
        ]);

        final vm = ClientSettingsDraftViewModel(
          repo: clientRepo,
          db: db,
          companyId: 'co-A',
          clientId: 'client-1',
        );
        await vm.load();
        await pumpEventQueue(); // let the (empty) client watch emit → _loaded
        expect(vm.isLoaded, isTrue);

        // Picking a rate at client scope writes BOTH keys (what the picker's
        // onChanged → _writePair does).
        vm.updateSettings((s) => s.copyWith(taxName1: 'VAT', taxRate1: 19.0));
        expect(vm.isOverridden('tax_name1'), isTrue);
        expect(vm.isOverridden('tax_rate1'), isTrue);

        // Toggling the override OFF routes through the picker's paired binding
        // (exactly how OverridableField.bindInline invokes it).
        vm.updateSettings(
          (s) => TaxRatePicker.overrideBinding(1, 0).write(s, null),
        );

        // The blob save() serializes drops both keys — no stale rate survives.
        final blob = vm.draftSettings.toJson()
          ..removeWhere((_, v) => v == null);
        expect(blob.containsKey('tax_name1'), isFalse);
        expect(blob.containsKey('tax_rate1'), isFalse);

        vm.dispose();
      },
    );
  });
}
