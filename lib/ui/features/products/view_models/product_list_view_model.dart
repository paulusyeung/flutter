import 'package:admin/data/db/dao/product_dao.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/columns/product_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';

/// List ViewModel for the Products screen. Plugs the [GenericListViewModel]
/// base into [ProductRepository] + the product column registry.
class ProductListViewModel extends GenericListViewModel<Product> {
  ProductListViewModel({
    required this.repo,
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
    super.now,
  });

  final ProductRepository repo;

  @override
  EntityType get entityType => EntityType.product;

  @override
  List<ColumnDefinition<Product>> get allColumns => kAllProductColumns;

  @override
  List<String> get defaultColumnIds => kDefaultProductColumns;

  @override
  String get defaultSortField => ProductFieldIds.productKey;

  @override
  bool isValidColumnId(String field) => productColumnsById.containsKey(field);

  @override
  String idOf(Product item) => item.id;

  @override
  bool isArchived(Product item) => item.archivedAt != null;

  @override
  bool isDeleted(Product item) => item.isDeleted;

  @override
  Stream<List<Product>> watchPage() => repo.watchPage(
    companyId: companyId,
    loadedPages: loadedPages,
    search: search.isEmpty ? null : search,
    states: states,
    sortField: sortField,
    sortAscending: sortAscending,
  );

  @override
  Future<bool> fetchPage({
    required int page,
    required String? search,
    required Set<EntityState> states,
    required Map<String, Set<String>> extraFilters,
    required bool ignoreCursor,
  }) => repo.ensurePageLoaded(
    companyId: companyId,
    page: page,
    search: search,
    states: states,
    ignoreCursor: ignoreCursor,
  );

  @override
  Future<void> refreshAll() => repo.refreshAll(companyId: companyId);

  /// Products don't expose distinct custom-value filtering today.
  @override
  Stream<List<String>> watchDistinctCustomValues(int columnIndex) =>
      Stream<List<String>>.value(const <String>[]);

  @override
  Iterable<BulkAction<Product>> get bulkActions => [
    BulkAction<Product>(
      id: 'archive',
      labelKey: 'archive',
      eligible: (p) => p.archivedAt == null && !p.isDeleted,
      apply: (id) => repo.archive(companyId: companyId, id: id),
    ),
    BulkAction<Product>(
      id: 'restore',
      labelKey: 'restore',
      eligible: (p) => p.archivedAt != null || p.isDeleted,
      apply: (id) => repo.restore(companyId: companyId, id: id),
    ),
    BulkAction<Product>(
      id: 'delete',
      labelKey: 'delete',
      eligible: (p) => !p.isDeleted,
      apply: (id) => repo.delete(companyId: companyId, id: id),
      requiresPassword: true,
    ),
  ];
}
