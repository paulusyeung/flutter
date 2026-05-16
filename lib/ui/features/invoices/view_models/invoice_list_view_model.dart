import 'package:admin/data/db/dao/invoice_dao.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/columns/invoice_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/standard_crud_bulk_actions.dart';

/// List ViewModel for the Invoices screen. Mirrors `ExpenseListViewModel` —
/// pagination / search / sort / multiselect / columns all live on the
/// generic base. M2+ extends `bulkActions` with mark_sent, mark_paid,
/// auto_bill, email, schedule_email, and run_template.
class InvoiceListViewModel extends GenericListViewModel<Invoice> {
  InvoiceListViewModel({
    required this.repo,
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.savedViews,
    super.searchDebounce,
    super.persistDebounce,
    super.now,
    this.clientId,
  });

  final InvoiceRepository repo;

  /// When non-null, scopes the watch + fetch to one client. Used by the
  /// embedded list inside `ClientDetailScreen`'s Invoices tab.
  final String? clientId;

  @override
  EntityType get entityType => EntityType.invoice;

  @override
  List<ColumnDefinition<Invoice>> get allColumns => kAllInvoiceColumns;

  @override
  List<String> get defaultColumnIds => kDefaultInvoiceColumns;

  /// Default sort is by invoice number descending — matches admin-portal's
  /// "newest invoice first" convention. The generic base starts ascending;
  /// in practice the first sort-toggle persists per saved view.
  @override
  String get defaultSortField => InvoiceFieldIds.number;

  @override
  bool isValidColumnId(String field) =>
      invoiceColumnsById.containsKey(field) ||
      field == InvoiceFieldIds.updatedAt;

  @override
  String idOf(Invoice item) => item.id;

  @override
  bool isArchived(Invoice item) => item.archivedAt != null;

  @override
  bool isDeleted(Invoice item) => item.isDeleted;

  @override
  Stream<List<Invoice>> watchPage() => repo.watchPage(
    companyId: companyId,
    loadedPages: loadedPages,
    search: search.isEmpty ? null : search,
    states: states,
    sortField: sortField,
    sortAscending: sortAscending,
    clientId: clientId,
  );

  @override
  Future<bool> fetchPage({
    required int page,
    required String? search,
    required Set<EntityState> states,
    required Map<String, Set<String>> extraFilters,
    required bool ignoreCursor,
  }) {
    // Embedded mode: thread the client scope through to the server via the
    // standard `extraFilters` plumbing so pagination cursors stay aligned
    // with the on-screen rows.
    final filters = clientId == null
        ? extraFilters
        : {
            ...extraFilters,
            'client_id': {clientId!},
          };
    return repo.ensurePageLoaded(
      companyId: companyId,
      page: page,
      search: search,
      states: states,
      extraFilters: filters,
      ignoreCursor: ignoreCursor,
    );
  }

  @override
  Future<void> refreshAll() => repo.refreshAll(companyId: companyId);

  @override
  Iterable<BulkAction<Invoice>> get bulkActions => standardCrudBulkActions(
    isArchived: isArchived,
    isDeleted: isDeleted,
    archive: (id) => repo.archive(companyId: companyId, id: id),
    restore: (id) => repo.restore(companyId: companyId, id: id),
    delete: (id) => repo.delete(companyId: companyId, id: id),
  );
}
