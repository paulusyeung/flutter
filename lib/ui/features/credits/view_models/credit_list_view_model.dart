import 'package:admin/data/db/dao/credit_dao.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/data/repositories/credit_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/columns/credit_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/standard_crud_bulk_actions.dart';

class CreditListViewModel extends GenericListViewModel<Credit> {
  CreditListViewModel({
    required this.repo,
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.savedViews,
    super.searchDebounce,
    super.persistDebounce,
    super.now,
  });

  final CreditRepository repo;

  @override
  EntityType get entityType => EntityType.credit;

  @override
  List<ColumnDefinition<Credit>> get allColumns => kAllCreditColumns;

  @override
  List<String> get defaultColumnIds => kDefaultCreditColumns;

  @override
  String get defaultSortField => CreditFieldIds.number;

  @override
  bool isValidColumnId(String field) =>
      creditColumnsById.containsKey(field) ||
      field == CreditFieldIds.updatedAt;

  @override
  String idOf(Credit item) => item.id;

  @override
  bool isArchived(Credit item) => item.archivedAt != null;

  @override
  bool isDeleted(Credit item) => item.isDeleted;

  @override
  Stream<List<Credit>> watchPage() => repo.watchPage(
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
  }) =>
      repo.ensurePageLoaded(
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
  Iterable<BulkAction<Credit>> get bulkActions => standardCrudBulkActions(
        isArchived: isArchived,
        isDeleted: isDeleted,
        archive: (id) => repo.archive(companyId: companyId, id: id),
        restore: (id) => repo.restore(companyId: companyId, id: id),
        delete: (id) => repo.delete(companyId: companyId, id: id),
      );
}
