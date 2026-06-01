import 'package:admin/data/db/dao/quote_dao.dart';
import 'package:admin/data/models/domain/quote.dart';
import 'package:admin/data/repositories/quote_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/columns/quote_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/standard_crud_bulk_actions.dart';
import 'package:admin/ui/features/billing_shared/email/billing_doc_email_sheet.dart';

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
    this.clientId,
    this.projectId,
  });

  final QuoteRepository repo;

  /// When non-null, scopes the watch + fetch to one client. Used by the
  /// embedded list inside `ClientDetailScreen`'s Quotes tab.
  final String? clientId;

  /// When non-null, scopes the watch + fetch to one project. Used by the
  /// embedded list inside `ProjectDetailScreen`'s Quotes tab.
  final String? projectId;

  @override
  Set<String> get lockedFilterKeyIds => {
    if (clientId != null) 'client',
    if (projectId != null) 'project',
  };

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
      quoteColumnsById.containsKey(field) || field == QuoteFieldIds.updatedAt;

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
    clientId: clientId,
    projectId: projectId,
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
  }) {
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
  Iterable<BulkAction<Quote>> get bulkActions => [
    ...standardCrudBulkActions(
      isArchived: isArchived,
      isDeleted: isDeleted,
      archive: (id) => repo.archive(companyId: companyId, id: id),
      restore: (id) => repo.restore(companyId: companyId, id: id),
      delete: (id) => repo.delete(companyId: companyId, id: id),
    ),
    BulkAction<Quote>(
      id: 'mark_sent',
      labelKey: 'mark_sent',
      eligible: (q) => q.isDraft && !isDeleted(q),
      apply: (id) => repo.markSent(companyId: companyId, id: id),
    ),
    BulkAction<Quote>(
      id: 'approve',
      labelKey: 'approve',
      eligible: (q) => !q.isApproved && !isDeleted(q),
      apply: (id) => repo.approve(companyId: companyId, id: id),
    ),
    BulkAction<Quote>(
      id: 'convert_to_invoice',
      labelKey: 'convert_to_invoice',
      eligible: (q) => !isDeleted(q),
      apply: (id) => repo.convertToInvoice(companyId: companyId, id: id),
    ),
    BulkAction<Quote>(
      id: 'email',
      labelKey: 'email',
      eligible: (q) => !isDeleted(q),
      applyArg: (id, arg) {
        final r = arg as BillingEmailResult;
        final scheduledFor = r.scheduledFor;
        if (scheduledFor != null) {
          return repo.scheduleEmail(
            companyId: companyId,
            id: id,
            template: r.template,
            sendAt: scheduledFor.toUtc().toIso8601String(),
            subject: r.subject.isEmpty ? null : r.subject,
            body: r.body.isEmpty ? null : r.body,
          );
        }
        return repo.email(
          companyId: companyId,
          id: id,
          template: r.template,
          subject: r.subject.isEmpty ? null : r.subject,
          body: r.body.isEmpty ? null : r.body,
          ccEmail: r.ccEmail.isEmpty ? null : r.ccEmail,
        );
      },
    ),
    BulkAction<Quote>(
      id: 'run_template',
      labelKey: 'run_template',
      eligible: (q) => !isDeleted(q),
      applyArg: (id, arg) => repo.runTemplate(
        companyId: companyId,
        id: id,
        templateId: arg as String,
      ),
    ),
  ];
}
