import 'package:admin/data/db/dao/purchase_order_dao.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/data/repositories/purchase_order_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/columns/purchase_order_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/standard_crud_bulk_actions.dart';
import 'package:admin/ui/features/billing_shared/email/billing_doc_email_sheet.dart';

class PurchaseOrderListViewModel extends GenericListViewModel<PurchaseOrder> {
  PurchaseOrderListViewModel({
    required this.repo,
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.savedViews,
    super.searchDebounce,
    super.persistDebounce,
    super.now,
    this.vendorId,
  });

  final PurchaseOrderRepository repo;

  /// When non-null, scopes the watch + fetch to one vendor.
  final String? vendorId;

  @override
  Set<String> get lockedFilterKeyIds => {
    if (vendorId != null) 'vendor',
  };

  @override
  EntityType get entityType => EntityType.purchaseOrder;

  @override
  List<ColumnDefinition<PurchaseOrder>> get allColumns =>
      kAllPurchaseOrderColumns;

  @override
  List<String> get defaultColumnIds => kDefaultPurchaseOrderColumns;

  @override
  String get defaultSortField => PurchaseOrderFieldIds.number;

  @override
  bool isValidColumnId(String field) =>
      purchaseOrderColumnsById.containsKey(field) ||
      field == PurchaseOrderFieldIds.updatedAt;

  @override
  String idOf(PurchaseOrder item) => item.id;

  @override
  bool isArchived(PurchaseOrder item) => item.archivedAt != null;

  @override
  bool isDeleted(PurchaseOrder item) => item.isDeleted;

  @override
  Stream<List<PurchaseOrder>> watchPage() => repo.watchPage(
        companyId: companyId,
        loadedPages: loadedPages,
        search: search.isEmpty ? null : search,
        states: states,
        sortField: sortField,
        sortAscending: sortAscending,
        vendorId: vendorId,
        customFilters: customFilters,
      );

  @override
  Future<bool> fetchPage({
    required int page,
    required String? search,
    required Set<EntityState> states,
    required Map<String, Set<String>> extraFilters,
    required bool ignoreCursor,
  }) {
    final filters = vendorId == null
        ? extraFilters
        : {
            ...extraFilters,
            'vendor_id': {vendorId!},
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
  Iterable<BulkAction<PurchaseOrder>> get bulkActions => [
        ...standardCrudBulkActions(
          isArchived: isArchived,
          isDeleted: isDeleted,
          archive: (id) => repo.archive(companyId: companyId, id: id),
          restore: (id) => repo.restore(companyId: companyId, id: id),
          delete: (id) => repo.delete(companyId: companyId, id: id),
        ),
        BulkAction<PurchaseOrder>(
          id: 'mark_sent',
          labelKey: 'mark_sent',
          eligible: (po) => po.isDraft && !isDeleted(po),
          apply: (id) => repo.markSent(companyId: companyId, id: id),
        ),
        BulkAction<PurchaseOrder>(
          id: 'accept',
          labelKey: 'accept',
          eligible: (po) => !po.isAccepted && !isDeleted(po),
          apply: (id) => repo.accept(companyId: companyId, id: id),
        ),
        BulkAction<PurchaseOrder>(
          id: 'convert_to_expense',
          labelKey: 'convert_to_expense',
          eligible: (po) => !isDeleted(po),
          apply: (id) => repo.convertToExpense(companyId: companyId, id: id),
        ),
        BulkAction<PurchaseOrder>(
          id: 'email',
          labelKey: 'email',
          eligible: (po) => !isDeleted(po),
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
        BulkAction<PurchaseOrder>(
          id: 'run_template',
          labelKey: 'run_template',
          eligible: (po) => !isDeleted(po),
          applyArg: (id, arg) => repo.runTemplate(
            companyId: companyId,
            id: id,
            templateId: arg as String,
          ),
        ),
      ];
}
