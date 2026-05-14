import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/expense_category_api_model.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/expense_category_repository.dart';
import 'package:admin/data/services/expense_categories_api.dart';

import '_base_entity_repository_contract.dart';

/// Covers the universal `BaseEntityRepository` contract via the shared
/// harness and the entity-specific behaviour the contract doesn't probe
/// (mapper round-trip, bundled-seed upsert + cursor advance, dirty-
/// preserving re-bundle).
class _ExpenseCategoryFixture
    extends EntityRepositoryContractFixture<ExpenseCategory, ExpenseCategoryApi> {
  @override
  String get entityType => 'expense_category';

  @override
  ExpenseCategoryRepository buildRepo(AppDatabase db) =>
      ExpenseCategoryRepository(db: db, api: _FakeExpenseCategoriesApi());

  @override
  ExpenseCategoryApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) => ExpenseCategoryApi(
    id: id,
    name: displayValue ?? id,
    color: '#abcdef',
    updatedAt: updatedAt,
  );

  @override
  ExpenseCategory fromApi(ExpenseCategoryApi api) =>
      ExpenseCategory.fromApi(api);

  @override
  ExpenseCategory editCopy(
    ExpenseCategory item, {
    required String displayValue,
  }) => item.copyWith(name: displayValue);

  @override
  String idOf(ExpenseCategory item) => item.id;

  @override
  bool isDirtyOf(ExpenseCategory item) => item.isDirty;

  @override
  Future<ExpenseCategory> create(
    BaseEntityRepository<ExpenseCategory, ExpenseCategoryApi> repo, {
    required String companyId,
    required ExpenseCategory draft,
  }) => (repo as ExpenseCategoryRepository).create(
    companyId: companyId,
    draft: draft,
  );

  @override
  Future<void> save(
    BaseEntityRepository<ExpenseCategory, ExpenseCategoryApi> repo, {
    required String companyId,
    required ExpenseCategory entity,
  }) => (repo as ExpenseCategoryRepository)
      .save(companyId: companyId, category: entity);

  @override
  Future<void> delete(
    BaseEntityRepository<ExpenseCategory, ExpenseCategoryApi> repo, {
    required String companyId,
    required String id,
  }) => (repo as ExpenseCategoryRepository)
      .delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_ExpenseCategoryFixture());

  group('ExpenseCategoryRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    ExpenseCategoryRepository makeRepo() =>
        ExpenseCategoryRepository(db: db, api: _FakeExpenseCategoriesApi());

    test(
      'ExpenseCategoryApi → ExpenseCategory round-trip preserves id, name, color',
      () {
        const api = ExpenseCategoryApi(
          id: 'ec_1',
          name: 'Travel',
          color: '#ff8800',
          updatedAt: 1700000000,
        );
        final domain = ExpenseCategory.fromApi(api);
        expect(domain.id, 'ec_1');
        expect(domain.name, 'Travel');
        expect(domain.color, '#ff8800');
        expect(domain.isDirty, isFalse);
      },
    );

    test(
      'applyBundle upserts every row and advances the cursor to max updatedAt',
      () async {
        final repo = makeRepo();
        await repo.applyBundle(
          companyId: 'co',
          bundle: const [
            ExpenseCategoryApi(
              id: 'ec_a',
              name: 'Travel',
              color: '#ff0000',
              updatedAt: 1700000100,
            ),
            ExpenseCategoryApi(
              id: 'ec_b',
              name: 'Meals',
              color: '#00ff00',
              updatedAt: 1700000200,
            ),
          ],
        );
        final rows = await repo.watchActive(companyId: 'co').first;
        expect(rows.map((c) => c.id).toSet(), {'ec_a', 'ec_b'});
        final cursor = await db.syncStateDao.read(
          companyId: 'co',
          entityType: 'expense_category',
        );
        expect(cursor.updatedAt, 1700000200);
        expect(cursor.id, 'ec_b');
      },
    );

    test('applyBundle preserves the local payload of an is_dirty row '
        'so an offline edit is not clobbered by a re-bundle', () async {
      final repo = makeRepo();
      // Land a dirty local create (offline).
      final draft = ExpenseCategory.fromApi(
        const ExpenseCategoryApi(name: 'My Custom', color: '#123456'),
      );
      await repo.create(companyId: 'co', draft: draft);
      final dirtyBefore = (await repo.watchActive(companyId: 'co').first)
          .single;
      expect(dirtyBefore.isDirty, isTrue);

      // Bundle in a server row with a different id; dirty row must survive.
      await repo.applyBundle(
        companyId: 'co',
        bundle: const [
          ExpenseCategoryApi(
            id: 'ec_server',
            name: 'Server Category',
            color: '#000000',
            updatedAt: 1700000500,
          ),
        ],
      );
      final all = await repo.watchActive(companyId: 'co').first;
      expect(all, hasLength(2));
      expect(all.map((c) => c.name).toSet(), {'My Custom', 'Server Category'});
      final stillDirty = all.firstWhere((c) => c.name == 'My Custom');
      expect(stillDirty.isDirty, isTrue);
    });
  });
}

class _FakeExpenseCategoriesApi implements ExpenseCategoriesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
