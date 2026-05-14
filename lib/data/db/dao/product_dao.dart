import 'package:drift/drift.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/company_scoped_dao.dart';
import 'package:admin/data/db/tables/products_table.dart';

part 'product_dao.g.dart';

/// Stable field-id constants used by the list ViewModel for column +
/// sort selection. Keep in sync with `ProductRepository.watchPage`.
class ProductFieldIds {
  static const String productKey = 'product_key';
  static const String price = 'price';
  static const String cost = 'cost';
  static const String quantity = 'quantity';
  static const String updatedAt = 'updated_at';
}

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase>
    with _$ProductDaoMixin, CompanyScopedDao {
  ProductDao(super.db);

  /// Watch a windowed slice of products. Filters: state (active/archived/
  /// deleted), free-text search across product_key + notes.
  Stream<List<ProductRow>> watchPage({
    required String companyId,
    required int offset,
    required int limit,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = ProductFieldIds.productKey,
    bool sortAscending = true,
  }) {
    final q = select(products)..where((p) => p.companyId.equals(companyId));

    if (states.isNotEmpty) {
      q.where((p) {
        Expression<bool>? acc;
        for (final s in states) {
          final pred = switch (s) {
            EntityState.active =>
              p.archivedAt.isNull() & p.isDeleted.equals(false),
            EntityState.archived =>
              p.archivedAt.isNotNull() & p.isDeleted.equals(false),
            EntityState.deleted => p.isDeleted.equals(true),
          };
          acc = acc == null ? pred : acc | pred;
        }
        return acc!;
      });
    }

    if (search != null && search.isNotEmpty) {
      final needle = '%${search.toLowerCase()}%';
      q.where(
        (p) => p.productKey.lower().like(needle) | p.notes.lower().like(needle),
      );
    }

    q.orderBy([
      (p) => OrderingTerm(
        expression: _sortExpression(p, sortField),
        mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
      ),
      // Stable secondary key.
      (p) => OrderingTerm(expression: p.id),
    ]);

    q.limit(limit, offset: offset);
    return q.watch();
  }

  Expression _sortExpression(Products p, String field) {
    switch (field) {
      case ProductFieldIds.productKey:
        return p.productKey.lower();
      case ProductFieldIds.price:
        return p.price.cast<double>();
      case ProductFieldIds.cost:
        return p.cost.cast<double>();
      case ProductFieldIds.quantity:
        return p.quantity.cast<double>();
      case ProductFieldIds.updatedAt:
        return p.updatedAt;
      default:
        return p.productKey.lower();
    }
  }

  Stream<int> watchCount({required String companyId}) {
    final q = selectOnly(products)
      ..addColumns([products.id.count()])
      ..where(
        products.companyId.equals(companyId) & products.isDeleted.equals(false),
      );
    return q
        .map((row) => row.read<int>(products.id.count()) ?? 0)
        .watchSingle();
  }

  Stream<ProductRow?> watchById({
    required String companyId,
    required String id,
  }) {
    final q = select(products)
      ..where((p) => p.companyId.equals(companyId) & p.id.equals(id))
      ..limit(1);
    return q.watchSingleOrNull();
  }

  Future<void> upsert(ProductsCompanion row) =>
      into(products).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<ProductsCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(products, rows));
  }

  Future<int> deleteById({required String companyId, required String id}) {
    return (delete(
      products,
    )..where((p) => p.companyId.equals(companyId) & p.id.equals(id))).go();
  }
}
