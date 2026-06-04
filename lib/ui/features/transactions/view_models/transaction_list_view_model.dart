import 'package:admin/data/db/dao/bank_transaction_dao.dart';
import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/data/repositories/bank_transaction_repository.dart';
import 'package:admin/domain/columns/bank_transaction_columns.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/standard_crud_bulk_actions.dart';

/// List ViewModel for the workspace `/transactions` screen and the embedded
/// transactions list inside `BankAccountDetailScreen`.
///
/// The optional [bankAccountId] gates the watch+fetch to a single bank
/// integration — set when this VM drives the embedded list (the standalone
/// screen leaves it null and shows transactions across all integrations).
class TransactionListViewModel extends GenericListViewModel<BankTransaction> {
  TransactionListViewModel({
    required this.repo,
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.savedViews,
    super.searchDebounce,
    super.persistDebounce,
    super.now,
    this.bankAccountId,
  });

  final BankTransactionRepository repo;

  /// When non-null, scopes the watch + fetch to one bank integration's
  /// transactions. Used by `BankAccountDetailScreen`'s embedded list.
  final String? bankAccountId;

  @override
  EntityType get entityType => EntityType.transaction;

  @override
  List<ColumnDefinition<BankTransaction>> get allColumns =>
      kAllBankTransactionColumns;

  @override
  List<String> get defaultColumnIds => kDefaultBankTransactionColumns;

  /// Default sort: most recent transactions first. Bank feeds drop in
  /// chronologically and users overwhelmingly look at the latest rows.
  @override
  String get defaultSortField => BankTransactionFieldIds.date;

  @override
  bool isValidColumnId(String field) =>
      bankTransactionColumnsById.containsKey(field) ||
      field == BankTransactionFieldIds.updatedAt ||
      field == BankTransactionFieldIds.amount;

  @override
  String idOf(BankTransaction item) => item.id;

  @override
  bool isArchived(BankTransaction item) => item.archivedAt != null;

  @override
  bool isDeleted(BankTransaction item) => item.isDeleted;

  @override
  Stream<List<BankTransaction>> watchPage() => repo.watchPage(
    companyId: companyId,
    loadedPages: loadedPages,
    search: search.isEmpty ? null : search,
    states: states,
    sortField: sortField,
    sortAscending: sortAscending,
    bankAccountId: bankAccountId,
  );

  @override
  Future<bool> fetchPage({
    required int page,
    required String? search,
    required Set<EntityState> states,
    required Map<String, Set<String>> extraFilters,
    required bool ignoreCursor,
  }) {
    // Embedded mode: thread the bank-account scope through to the server
    // via the standard `extraFilters` plumbing. The repo's
    // `ensurePageLoadedTemplate` joins it into the query string.
    final filters = bankAccountId == null
        ? extraFilters
        : {
            ...extraFilters,
            // Server filter is `bank_integration_ids` (plural) — see
            // `BankTransactionFilters::bank_integration_ids`, which decodes the
            // comma list via `transformKeys`. The singular form is silently
            // ignored, so a single id still goes through the plural key.
            'bank_integration_ids': {bankAccountId!},
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

  /// Standard CRUD trio + the unlink bulk action. Convert is row-level
  /// only (it creates server-side payments / expenses; we always show a
  /// confirmation dialog via `TransactionActions._confirmConvert`).
  /// Unlink is eligible for Matched + Converted rows because it's the
  /// recovery path on either side.
  @override
  Iterable<BulkAction<BankTransaction>> get bulkActions => [
    ...standardCrudBulkActions(
      isArchived: isArchived,
      isDeleted: isDeleted,
      archive: (id) => repo.archive(companyId: companyId, id: id),
      restore: (id) => repo.restore(companyId: companyId, id: id),
      delete: (id) => repo.delete(companyId: companyId, id: id),
    ),
    BulkAction<BankTransaction>(
      id: 'unlink',
      labelKey: 'unlink',
      eligible: (t) => t.isMatched || t.isConverted,
      apply: (id) =>
          repo.unlinkTransactions(companyId: companyId, transactionIds: [id]),
    ),
  ];
}
