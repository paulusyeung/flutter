import 'package:admin/data/db/dao/quote_dao.dart';
import 'package:admin/data/models/domain/quote.dart';
import 'package:admin/data/repositories/quote_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/columns/quote_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/standard_crud_bulk_actions.dart';

class QuoteListViewModel extends GenericListViewModel<Quote> {
  QuoteListViewModel({
    required this.repo,
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.savedViews,
    super.searchDebounce,
    super.persistDebounce,
    super.now,
  });

  final QuoteRepository repo;

  @override
  EntityType get entityType => EntityType.quote;

  @override
  List<ColumnDefinition<Quote>> get allColumns => kAllQuoteColumns;

  @override
  List<String> get defaultColumnIds => kDefaultQuoteColumns;

  @override
  String get defaultSortField => QuoteFieldIds.number;

  @override
  bool isValidColumnId(String field) =>
      quoteColumnsById.containsKey(field) ||
      field == QuoteFieldIds.updatedAt;

  @override
  String idOf(Quote item) => item.id;

  @override
  bool isArchived(Quote item) => item.archivedAt != null;

  @override
  bool isDeleted(Quote item) => item.isDeleted;

  @override
  Stream<List<Quote>> watchPage() => repo.watchPage(
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
  Iterable<BulkAction<Quote>> get bulkActions => standardCrudBulkActions(
    isArchived: isArchived,
    isDeleted: isDeleted,
    archive: (id) => repo.archive(companyId: companyId, id: id),
    restore: (id) => repo.restore(companyId: companyId, id: id),
    delete: (id) => repo.delete(companyId: companyId, id: id),
  );
}
