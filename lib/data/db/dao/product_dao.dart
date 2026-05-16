import 'package:drift/drift.dart';

import 'package:admin/data/db/dao/_distinct_stream.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/base_entity_dao.dart';
import 'package:admin/data/db/dao/entity_query_helpers.dart';
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
class ProductDao extends BaseEntityDao<$ProductsTable, ProductRow>
    with _$ProductDaoMixin {
  ProductDao(super.db);

  @override
  $ProductsTable get table => products;
  @override
  GeneratedColumn<String> get idColumn => products.id;
  @override
  GeneratedColumn<String> get companyIdColumn => products.companyId;
  @override
  GeneratedColumn<bool> get isDeletedColumn => products.isDeleted;
  @override
  GeneratedColumn<bool> get isDirtyColumn => products.isDirty;

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
      q.where(
        (p) => entityStateFilter(
          states: states,
          archivedAt: p.archivedAt,
          isDeleted: p.isDeleted,
        ),
      );
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
    return q.watch().distinctRows();
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
}
