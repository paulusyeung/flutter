import 'package:admin/data/db/dao/company_gateway_dao.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/data/repositories/company_gateway_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/columns/company_gateway_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/standard_crud_bulk_actions.dart';

/// List ViewModel for the Company Gateways screen. Mirrors the standard
/// `<Entity>ListViewModel` shape — the base class owns pagination, search,
/// filter, sort, multiselect, and column persistence.
class CompanyGatewayListViewModel extends GenericListViewModel<CompanyGateway> {
  CompanyGatewayListViewModel({
    required this.repo,
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.savedViews,
    super.searchDebounce,
    super.persistDebounce,
    super.now,
  });

  final CompanyGatewayRepository repo;

  @override
  EntityType get entityType => EntityType.companyGateway;

  @override
  List<ColumnDefinition<CompanyGateway>> get allColumns =>
      kAllCompanyGatewayColumns;

  @override
  List<String> get defaultColumnIds => kDefaultCompanyGatewayColumns;

  @override
  String get defaultSortField => CompanyGatewayFieldIds.updatedAt;

  @override
  bool isValidColumnId(String field) =>
      companyGatewayColumnsById.containsKey(field) ||
      field == CompanyGatewayFieldIds.updatedAt;

  @override
  String idOf(CompanyGateway item) => item.id;

  @override
  bool isArchived(CompanyGateway item) => item.archivedAt != 0;

  @override
  bool isDeleted(CompanyGateway item) => item.isDeleted;

  @override
  Stream<List<CompanyGateway>> watchPage() => repo.watchPage(
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
    extraFilters: extraFilters,
    ignoreCursor: ignoreCursor,
  );

  @override
  Future<void> refreshAll() => repo.refreshAll(companyId: companyId);

  @override
  Iterable<BulkAction<CompanyGateway>> get bulkActions =>
      standardCrudBulkActions(
        isArchived: isArchived,
        isDeleted: isDeleted,
        archive: (id) => repo.archive(companyId: companyId, id: id),
        restore: (id) => repo.restore(companyId: companyId, id: id),
        delete: (id) => repo.delete(companyId: companyId, id: id),
      );
}
