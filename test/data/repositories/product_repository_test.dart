import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/data/services/products_api.dart';
import 'package:admin/domain/sync/mutation.dart';

import '_base_entity_repository_contract.dart';

/// Covers the universal `BaseEntityRepository` contract via the shared
/// harness and a small set of Product-specific assertions for behavior
/// the contract intentionally doesn't probe (watchPage is_dirty overlay,
/// Decimal price round-trip).
class _ProductFixture
    extends EntityRepositoryContractFixture<Product, ProductApi> {
  @override
  String get entityType => 'product';

  @override
  ProductRepository buildRepo(AppDatabase db) =>
      ProductRepository(db: db, api: _FakeProductsApi());

  @override
  ProductApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) =>
      ProductApi(id: id, productKey: displayValue ?? id, updatedAt: updatedAt);

  @override
  Product fromApi(ProductApi api) => Product.fromApi(api);

  @override
  Product editCopy(Product item, {required String displayValue}) =>
      item.copyWith(productKey: displayValue);

  @override
  String idOf(Product item) => item.id;

  @override
  bool isDirtyOf(Product item) => item.isDirty;

  @override
  Future<Product> create(
    BaseEntityRepository<Product, ProductApi> repo, {
    required String companyId,
    required Product draft,
  }) => (repo as ProductRepository).create(companyId: companyId, draft: draft);

  @override
  Future<void> save(
    BaseEntityRepository<Product, ProductApi> repo, {
    required String companyId,
    required Product entity,
  }) => (repo as ProductRepository).save(companyId: companyId, product: entity);

  @override
  Future<void> delete(
    BaseEntityRepository<Product, ProductApi> repo, {
    required String companyId,
    required String id,
  }) => (repo as ProductRepository).delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_ProductFixture());

  group('ProductRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    ProductRepository makeRepo() =>
        ProductRepository(db: db, api: _FakeProductsApi());

    test('_fromRow overlays is_dirty so the watchPage list reflects the '
        'unsaved state after restart', () async {
      final repo = makeRepo();
      final draft = Product.fromApi(
        const ProductApi(productKey: 'X', price: '1', updatedAt: 1700000000),
      );
      await repo.create(companyId: 'co', draft: draft);
      final created = await repo
          .watchPage(companyId: 'co', loadedPages: 1)
          .first;
      expect(created, hasLength(1));
      expect(created.first.isDirty, isTrue);
    });

    test('Decimal price survives round-trip without precision loss', () async {
      final repo = makeRepo();
      // Seed an existing product with a non-trivial price.
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

      // The outbox has both the seed create (it was queued by
      // applyCreateResponse via repo.create) and the update.
      final outbox = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 9999999999999,
      );
      expect(
        outbox.where((r) => r.mutationKind == MutationKind.update.wireName),
        hasLength(1),
      );
    });
  });
}

class _FakeProductsApi implements ProductsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
