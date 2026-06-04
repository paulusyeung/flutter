import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/ui/features/settings/view_models/invoice_design_view_model.dart';

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Captures the `extraOutboxPayload` handed to `updateCompany` so the test can
/// assert what the "Update all records" toggles attach on save.
class _CapturingCompanyRepository extends CompanyRepository {
  _CapturingCompanyRepository({
    required super.db,
    required super.api,
    required this.watchStream,
  });

  final Stream<Company?> watchStream;
  Map<String, dynamic>? lastExtraPayload;
  int updateCalls = 0;

  @override
  Stream<Company?> watchCompany(String companyId) => watchStream;

  @override
  Future<void> refresh(String companyId) async {}

  @override
  Future<void> updateCompany({
    required Company draft,
    Map<String, dynamic>? extraOutboxPayload,
  }) async {
    updateCalls += 1;
    lastExtraPayload = extraOutboxPayload;
  }
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async {
    await db.close();
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  Company companyWith({String? invoice, String? quote}) => Company(
    id: 'co',
    settings: CompanySettingsApi(
      invoiceDesignId: invoice,
      quoteDesignId: quote,
    ),
  );

  Future<
    (
      InvoiceDesignViewModel,
      _CapturingCompanyRepository,
      StreamController<Company?>,
    )
  >
  boot(Company seed) async {
    final controller = StreamController<Company?>();
    final repo = _CapturingCompanyRepository(
      db: db,
      api: _FakeCompaniesApi(),
      watchStream: controller.stream,
    );
    final vm = InvoiceDesignViewModel(repo: repo, companyId: 'co');
    await vm.load();
    controller.add(seed);
    await tick();
    return (vm, repo, controller);
  }

  group('extraOutboxPayload (Update all records)', () {
    test('null when no toggle is set, even after a design change', () async {
      final (vm, _, controller) = await boot(companyWith(invoice: 'A'));
      vm.updateSettings((s) => s.copyWith(invoiceDesignId: 'B'));

      expect(vm.extraOutboxPayload(), isNull);

      await controller.close();
      vm.dispose();
    });

    test('emits a directive for a changed, toggled design', () async {
      final (vm, _, controller) = await boot(companyWith(invoice: 'A'));
      vm.updateSettings((s) => s.copyWith(invoiceDesignId: 'B'));
      vm.setUpdateAll('invoice', true);

      expect(vm.extraOutboxPayload(), {
        '_design_updates': [
          {'design_id': 'B', 'entity': 'invoice'},
        ],
      });

      await controller.close();
      vm.dispose();
    });

    test('no directive when toggled but the design is unchanged', () async {
      final (vm, _, controller) = await boot(companyWith(invoice: 'A'));
      // Toggle on, but the design id still matches the loaded baseline.
      vm.setUpdateAll('invoice', true);

      expect(vm.extraOutboxPayload(), isNull);

      await controller.close();
      vm.dispose();
    });

    test('emits one directive per changed+toggled design', () async {
      final (vm, _, controller) = await boot(
        companyWith(invoice: 'A', quote: 'Q'),
      );
      vm.updateSettings(
        (s) => s.copyWith(invoiceDesignId: 'B', quoteDesignId: 'Q2'),
      );
      vm.setUpdateAll('invoice', true);
      vm.setUpdateAll('quote', true);

      // Iteration order is fixed (invoice → quote → credit → purchase_order),
      // so the directive list is deterministic.
      expect(vm.extraOutboxPayload(), {
        '_design_updates': [
          {'design_id': 'B', 'entity': 'invoice'},
          {'design_id': 'Q2', 'entity': 'quote'},
        ],
      });

      await controller.close();
      vm.dispose();
    });

    test(
      'save() carries the directive then clears the one-shot flag',
      () async {
        final (vm, repo, controller) = await boot(companyWith(invoice: 'A'));
        vm.updateSettings((s) => s.copyWith(invoiceDesignId: 'B'));
        vm.setUpdateAll('invoice', true);

        await vm.save();
        expect(repo.lastExtraPayload, {
          '_design_updates': [
            {'design_id': 'B', 'entity': 'invoice'},
          ],
        });

        // The flag is one-shot: a second design change without re-ticking
        // attaches nothing (the baseline advanced to 'B' on the prior save).
        vm.updateSettings((s) => s.copyWith(invoiceDesignId: 'C'));
        expect(vm.extraOutboxPayload(), isNull);

        await controller.close();
        vm.dispose();
      },
    );
  });
}
