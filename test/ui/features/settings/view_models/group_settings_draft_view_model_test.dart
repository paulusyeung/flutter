import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/group_setting_api_model.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/data/services/group_settings_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/ui/features/settings/view_models/group_settings_draft_view_model.dart';

/// Covers the group-scope cascade draft VM — the mirror of
/// `ClientSettingsDraftViewModel` that lights up group-level settings editing.
/// Asserts the merged-view inheritance, override toggle, and sparse save that
/// the override widgets bind against.
class _FakeGroupSettingsApi implements GroupSettingsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async {
    await db.close();
  });

  GroupSettingRepository makeRepo() =>
      GroupSettingRepository(db: db, api: _FakeGroupSettingsApi());

  Future<void> seedCompany(Map<String, dynamic> settings) =>
      db.companiesDao.upsertAll([
        CompaniesCompanion.insert(
          id: 'co',
          name: 'Acme',
          displayName: const Value('Acme'),
          settings: jsonEncode(settings),
          customFields: const Value('{}'),
          permissions: '',
          accountId: 'acct',
          token: 'tok',
          updatedAt: 1700000000,
        ),
      ]);

  Future<void> seedGroup(
    GroupSettingRepository repo, {
    Map<String, dynamic>? settings,
  }) => repo.applyCreateResponse(
    companyId: 'co',
    tempId: 'g1',
    serverResponse: GroupSettingApi(
      id: 'g1',
      name: 'Premium',
      updatedAt: 1700000000,
      settings: settings,
    ),
  );

  // The VM subscribes to a Drift watch; spin until the first emission lands.
  Future<void> waitLoaded(GroupSettingsDraftViewModel vm) async {
    for (var i = 0; i < 200 && !vm.isLoaded; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  GroupSettingsDraftViewModel makeVm(GroupSettingRepository repo) =>
      GroupSettingsDraftViewModel(
        repo: repo,
        db: db,
        companyId: 'co',
        groupId: 'g1',
      );

  test(
    'merged view inherits the company default when not overridden',
    () async {
      final repo = makeRepo();
      await seedCompany({'vat_number': 'CO-VAT'});
      await seedGroup(repo);
      final vm = makeVm(repo);
      await vm.load();
      await waitLoaded(vm);

      expect(vm.isLoaded, isTrue);
      expect(vm.settings.vatNumber, 'CO-VAT');
      expect(vm.isOverridden('vat_number'), isFalse);
      expect(vm.isDirty, isFalse);
      vm.dispose();
    },
  );

  test(
    'setOverride shadows the company default and toggles back off',
    () async {
      final repo = makeRepo();
      await seedCompany({'vat_number': 'CO-VAT'});
      await seedGroup(repo);
      final vm = makeVm(repo);
      await vm.load();
      await waitLoaded(vm);

      vm.setOverride(
        apiKey: 'vat_number',
        enabled: true,
        cascadedValue: 'G-VAT',
      );
      expect(vm.isOverridden('vat_number'), isTrue);
      expect(vm.settings.vatNumber, 'G-VAT');
      expect(vm.isDirty, isTrue);

      vm.setOverride(apiKey: 'vat_number', enabled: false);
      expect(vm.isOverridden('vat_number'), isFalse);
      expect(vm.settings.vatNumber, 'CO-VAT'); // inherited again
      vm.dispose();
    },
  );

  test('save writes a sparse override blob back onto the group', () async {
    final repo = makeRepo();
    await seedCompany({'vat_number': 'CO-VAT'});
    await seedGroup(repo);
    final vm = makeVm(repo);
    await vm.load();
    await waitLoaded(vm);

    vm.setOverride(apiKey: 'vat_number', enabled: true, cascadedValue: 'G-VAT');
    final saved = await vm.save();
    expect(saved, isNotNull);
    expect(vm.isDirty, isFalse, reason: 'baseline advances to draft on save');

    final stored = await repo.watch(companyId: 'co', id: 'g1').first;
    expect(stored!.settings!['vat_number'], 'G-VAT');
    vm.dispose();
  });

  test('an existing group override loads as overridden (not dirty)', () async {
    final repo = makeRepo();
    await seedCompany({'vat_number': 'CO-VAT'});
    await seedGroup(repo, settings: {'vat_number': 'G-EXISTING'});
    final vm = makeVm(repo);
    await vm.load();
    await waitLoaded(vm);

    expect(vm.settings.vatNumber, 'G-EXISTING');
    expect(vm.isOverridden('vat_number'), isTrue);
    expect(vm.isDirty, isFalse);
    vm.dispose();
  });

  group('design "Update all records" (cascade save)', () {
    Future<List<String>> designRowPayloads(GroupSettingRepository repo) async {
      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      return pending
          .where(
            (r) => r.mutationKind == MutationKind.setDefaultDesign.wireName,
          )
          .map((r) => r.payload)
          .toList();
    }

    test('save enqueues a group-scope set_default_design row for a changed + '
        'ticked design', () async {
      final repo = makeRepo();
      await seedCompany({'vat_number': 'CO-VAT'});
      await seedGroup(repo);
      final vm = makeVm(repo);
      await vm.load();
      await waitLoaded(vm);

      vm.updateSettings((s) => s.copyWith(invoiceDesignId: 'design_X'));
      vm.setUpdateAll('invoice', true);
      await vm.save();

      final rows = await designRowPayloads(repo);
      expect(rows, hasLength(1));
      final payload = jsonDecode(rows.single) as Map<String, dynamic>;
      expect(payload['design_id'], 'design_X');
      expect(payload['entity'], 'invoice');
      expect(payload['settings_level'], 'group_settings');
      expect(payload['group_settings_id'], 'g1');
      vm.dispose();
    });

    test('purchase_order design is never retro-applied at group scope (PO '
        'designs are company-scoped server-side)', () async {
      final repo = makeRepo();
      await seedCompany({'vat_number': 'CO-VAT'});
      await seedGroup(repo);
      final vm = makeVm(repo);
      await vm.load();
      await waitLoaded(vm);

      vm.updateSettings((s) => s.copyWith(purchaseOrderDesignId: 'design_PO'));
      vm.setUpdateAll('purchase_order', true);
      await vm.save();

      expect(await designRowPayloads(repo), isEmpty);
      vm.dispose();
    });
  });
}
