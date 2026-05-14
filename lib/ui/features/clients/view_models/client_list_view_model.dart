import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/standard_crud_bulk_actions.dart';

/// Drives the read-only Clients list screen.
///
/// All list-screen machinery — pagination, search, filter, sort, multiselect,
/// filter persistence, column selection — lives on [GenericListViewModel].
/// This subclass plugs in the client-specific bits: which column registry
/// to use, how to ask the repo for rows, and the bulk-action predicates.
/// When entity #2 (Invoice) lands, it follows the same shape with a swap of
/// repo and column registry.
class ClientListViewModel extends GenericListViewModel<Client> {
  ClientListViewModel({
    required this.repo,
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.savedViews,
    super.searchDebounce,
    super.persistDebounce,
    super.now,
  });

  final ClientRepository repo;

  // ── Configuration ──────────────────────────────────────────────────

  @override
  EntityType get entityType => EntityType.client;

  @override
  List<ColumnDefinition<Client>> get allColumns => kAllClientColumns;

  @override
  List<String> get defaultColumnIds => kDefaultClientColumns;

  @override
  String get defaultSortField => ClientFieldIds.name;

  @override
  bool isValidColumnId(String field) => clientColumnsById.containsKey(field);

  @override
  String idOf(Client item) => item.id;

  @override
  bool isArchived(Client item) => item.archivedAt != null;

  @override
  bool isDeleted(Client item) => item.isDeleted;

  // ── Data-source hooks ──────────────────────────────────────────────

  @override
  Stream<List<Client>> watchPage() => repo.watchPage(
    companyId: companyId,
    loadedPages: loadedPages,
    search: search.isEmpty ? null : search,
    states: states,
    sortField: sortField,
    sortAscending: sortAscending,
    customFilters: customFilters,
    extraFilters: extraFilters,
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
  Stream<List<String>> watchDistinctCustomValues(int columnIndex) =>
      repo.watchDistinctCustomValues(
        companyId: companyId,
        columnIndex: columnIndex,
      );

  // ── Bulk actions ───────────────────────────────────────────────────

  @override
  Iterable<BulkAction<Client>> get bulkActions => standardCrudBulkActions(
    isArchived: isArchived,
    isDeleted: isDeleted,
    archive: (id) => repo.archive(companyId: companyId, id: id),
    restore: (id) => repo.restore(companyId: companyId, id: id),
    delete: (id) => repo.delete(companyId: companyId, id: id),
  );

  /// Convenience wrappers for the multiselect AppBar — the same calls
  /// the existing UI already used, now backed by the generic engine.
  Future<({int ok, int skipped, int failed})> bulkArchive() =>
      applyBulkAction(bulkActionById('archive')!);

  Future<({int ok, int skipped, int failed})> bulkRestore() =>
      applyBulkAction(bulkActionById('restore')!);
}
