import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/data/services/products_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sibling of `clients/client_edit_view_model_test.dart` — the canonical
/// edit-screen test pattern. It asserts the VM→repo→outbox contract the
/// screen depends on (save lands in Drift + queues the right mutation),
/// without the `Services`/`Provider` scaffolding a full screen pump needs.
/// New entity edit VMs should copy this shape.

class _NoopApi implements ProductsApi {
  @override
  Object? noSuchMethod(Invocation invocation) {
    // The edit VM never hits the API directly — everything lands via the
    // outbox. A call here means we accidentally bypassed the repo.
    throw StateError('Unexpected API call: ${invocation.memberName}');
  }
}

void main() {
  late AppDatabase db;
  late ProductRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProductRepository(db: db, api: _NoopApi());
  });
  tearDown(() async {
    await db.close();
  });

  Product existing() => Product.fromApi(
    ProductApi.fromJson({'id': 'p1', 'product_key': 'Original'}),
  );

  group('isDirty', () {
    test('edit mode: stays false until a field actually changes', () {
      final vm = ProductEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing(),
      );
      expect(vm.isDirty, isFalse);
      vm.setProductKey('Renamed');
      expect(vm.isDirty, isTrue);
      vm.dispose();
    });

    test('create mode: false until the form has any content', () {
      final vm = ProductEditViewModel(repo: repo, companyId: 'co');
      expect(vm.isDirty, isFalse);
      vm.setProductKey('SKU-1');
      expect(vm.isDirty, isTrue);
      vm.dispose();
    });
  });

  group('save (edit)', () {
    test(
      'queues an update outbox row and reflects the new key in Drift',
      () async {
        await repo.applyUpdateResponse(
          companyId: 'co',
          serverResponse: ProductApi.fromJson({
            'id': 'p1',
            'product_key': 'Original',
          }),
        );

        final vm = ProductEditViewModel(
          repo: repo,
          companyId: 'co',
          existing: existing(),
        );
        vm.setProductKey('Renamed');

        final result = await vm.save();
        expect(result, isNotNull);
        expect(result!.productKey, 'Renamed');

        final pending = await db.outboxDao.nextReady(
          companyId: 'co',
          now: 1 << 60,
        );
        expect(pending, hasLength(1));
        expect(pending.single.mutationKind, MutationKind.update.wireName);
        expect(pending.single.entityId, 'p1');
        vm.dispose();
      },
    );
  });

  group('save (create)', () {
    test('mints a tmp_ id and queues a create outbox row', () async {
      final vm = ProductEditViewModel(repo: repo, companyId: 'co');
      vm.setProductKey('SKU-NEW');

      final result = await vm.save();
      expect(result, isNotNull);
      expect(result!.id, startsWith('tmp_'));
      expect(result.productKey, 'SKU-NEW');

      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(pending, hasLength(1));
      expect(pending.single.mutationKind, MutationKind.create.wireName);
      vm.dispose();
    });
  });

  group('save — in_stock_quantity flag', () {
    test('editing the stock count rides update_in_stock_quantity into the '
        'outbox payload', () async {
      final vm = ProductEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing(),
      );
      vm.setInStockQuantity('5');

      await vm.save();

      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      final payload =
          jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expect(payload[kSaveQueryPayloadKey], {
        'update_in_stock_quantity': 'true',
      });
      vm.dispose();
    });

    test(
      'editing a non-stock field does NOT send update_in_stock_quantity',
      () async {
        final vm = ProductEditViewModel(
          repo: repo,
          companyId: 'co',
          existing: existing(),
        );
        vm.setProductKey('Renamed');

        await vm.save();

        final pending = await db.outboxDao.nextReady(
          companyId: 'co',
          now: 1 << 60,
        );
        final payload =
            jsonDecode(pending.single.payload) as Map<String, dynamic>;
        expect(payload.containsKey(kSaveQueryPayloadKey), isFalse);
        vm.dispose();
      },
    );
  });
}
