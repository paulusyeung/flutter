import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/data/services/products_api.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Smoke tests that prove the Products module wires correctly through
/// the generic base. The behavioral coverage that matters at this
/// milestone is "the generic abstractions hold for a second entity" —
/// `sync_round_trip_test.dart` already covers the offline-create / sync
/// machinery in depth via Clients.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  ProductRepository makeRepo() =>
      ProductRepository(db: db, api: _FakeProductsApi());

  test(
    'create() mints a tmp id, writes is_dirty=true, enqueues outbox row',
    () async {
      final repo = makeRepo();
      final draft = Product.fromApi(
        const ProductApi(productKey: 'Widget', price: '12.50'),
      );

      final created = await repo.create(companyId: 'co', draft: draft);

      expect(created.id.startsWith('tmp_'), isTrue);
      final row = await db.productDao
          .watchById(companyId: 'co', id: created.id)
          .first;
      expect(row?.isDirty, isTrue);
      expect(row?.productKey, 'Widget');

      final outbox = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 9999999999999,
      );
      expect(outbox, hasLength(1));
      expect(outbox.first.mutationKind, MutationKind.create.wireName);
      expect(outbox.first.entityType, 'product');
      expect(outbox.first.idempotencyKey, isNotEmpty);
    },
  );

  test('delete enqueues with requiresPassword=true (server policy)', () async {
    final repo = makeRepo();
    await repo.delete(companyId: 'co', id: 'prod_1');

    final outbox = await db.outboxDao.nextReady(
      companyId: 'co',
      now: 9999999999999,
    );
    expect(outbox, hasLength(1));
    expect(outbox.first.requiresPassword, isTrue);
  });

  test(
    'applyCreateResponse upserts under the real id and remaps the tmp',
    () async {
      final repo = makeRepo();
      final draft = Product.fromApi(
        const ProductApi(productKey: 'Widget', price: '12.50'),
      );
      final created = await repo.create(companyId: 'co', draft: draft);
      final tmpId = created.id;

      await repo.applyCreateResponse(
        companyId: 'co',
        tempId: tmpId,
        serverResponse: const ProductApi(
          id: 'real_007',
          productKey: 'Widget',
          price: '12.50',
          updatedAt: 1700000000,
        ),
      );

      final realRow = await db.productDao
          .watchById(companyId: 'co', id: 'real_007')
          .first;
      expect(realRow, isNotNull);
      final tmpRow = await db.productDao
          .watchById(companyId: 'co', id: tmpId)
          .first;
      expect(tmpRow, isNull);

      final mapped = await db.idRemapDao.resolve(
        entityType: 'product',
        tempId: tmpId,
      );
      expect(mapped, 'real_007');
    },
  );

  test('_fromRow overlays is_dirty so unsaved edits survive restart', () async {
    final repo = makeRepo();
    final draft = Product.fromApi(
      const ProductApi(productKey: 'X', price: '1', updatedAt: 1700000000),
    );
    await repo.create(companyId: 'co', draft: draft);
    final created = await repo.watchPage(companyId: 'co', loadedPages: 1).first;
    expect(created, hasLength(1));
    // is_dirty was set during the create transaction; the row→domain
    // conversion must overlay it (the API payload itself has no such
    // field).
    expect(created.first.isDirty, isTrue);
  });

  test('save() writes the draft and queues an update mutation', () async {
    final repo = makeRepo();
    // Seed an existing product.
    await repo.applyCreateResponse(
      companyId: 'co',
      tempId: 'prod_1',
      serverResponse: const ProductApi(
        id: 'prod_1',
        productKey: 'Widget',
        price: '10',
        updatedAt: 1700000000,
      ),
    );

    final loaded = await repo.watch(companyId: 'co', id: 'prod_1').first;
    final edited = loaded!.copyWith(
      price: Decimal.parse('15.00'),
      productKey: 'Widget v2',
    );
    await repo.save(companyId: 'co', product: edited);

    final row = await db.productDao
        .watchById(companyId: 'co', id: 'prod_1')
        .first;
    expect(row?.productKey, 'Widget v2');
    expect(row?.isDirty, isTrue);

    final outbox = await db.outboxDao.nextReady(
      companyId: 'co',
      now: 9999999999999,
    );
    expect(
      outbox.where((r) => r.mutationKind == MutationKind.update.wireName),
      hasLength(1),
    );
  });
}

class _FakeProductsApi implements ProductsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
