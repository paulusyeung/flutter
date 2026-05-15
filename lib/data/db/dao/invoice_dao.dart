import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/base_entity_dao.dart';
import 'package:admin/data/db/dao/entity_query_helpers.dart';
import 'package:admin/data/db/tables/invoices_table.dart';
import 'package:admin/domain/entity_state.dart';

part 'invoice_dao.g.dart';

/// Stable field-id constants used by the list ViewModel for column +
/// sort selection. Keep in sync with `InvoiceRepository.watchPage` +
/// `InvoiceDao._sortExpression`.
class InvoiceFieldIds {
  static const String number = 'number';
  static const String status = 'status_id';
  static const String clientId = 'client_id';
  static const String vendorId = 'vendor_id';
  static const String projectId = 'project_id';
  static const String date = 'date';
  static const String dueDate = 'due_date';
  static const String partialDueDate = 'partial_due_date';
  static const String amount = 'amount';
  static const String balance = 'balance';
  static const String paidToDate = 'paid_to_date';
  static const String partial = 'partial';
  static const String poNumber = 'po_number';
  static const String designId = 'design_id';
  static const String assignedUserId = 'assigned_user_id';
  static const String publicNotes = 'public_notes';
  static const String privateNotes = 'private_notes';
  static const String updatedAt = 'updated_at';
  static const String createdAt = 'created_at';
  static const String customValue1 = 'custom_value1';
  static const String customValue2 = 'custom_value2';
  static const String customValue3 = 'custom_value3';
  static const String customValue4 = 'custom_value4';
}

@DriftAccessor(tables: [Invoices])
class InvoiceDao extends BaseEntityDao<$InvoicesTable, InvoiceRow>
    with _$InvoiceDaoMixin {
  InvoiceDao(super.db);

  @override
  $InvoicesTable get table => invoices;
  @override
  GeneratedColumn<String> get idColumn => invoices.id;
  @override
  GeneratedColumn<String> get companyIdColumn => invoices.companyId;
  @override
  GeneratedColumn<bool> get isDeletedColumn => invoices.isDeleted;
  @override
  GeneratedColumn<bool> get isDirtyColumn => invoices.isDirty;

  /// Windowed list watch. Filters: state (active/archived/deleted), free-text
  /// search across number + public_notes + private_notes + po_number (via
  /// payload JSON extract). Sort field is one of [InvoiceFieldIds].
  Stream<List<InvoiceRow>> watchPage({
    required String companyId,
    required int offset,
    required int limit,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = InvoiceFieldIds.number,
    bool sortAscending = false,
  }) {
    final q = select(invoices)..where((e) => e.companyId.equals(companyId));

    if (states.isNotEmpty) {
      q.where(
        (e) => entityStateFilter(
          states: states,
          archivedAt: e.archivedAt,
          isDeleted: e.isDeleted,
        ),
      );
    }

    if (search != null && search.isNotEmpty) {
      final needle = '%${search.toLowerCase()}%';
      q.where(
        (e) =>
            e.number.lower().like(needle) |
            e.poNumber.lower().like(needle) |
            e.notesLikePayload(needle),
      );
    }

    q.orderBy([
      (e) => OrderingTerm(
        expression: _sortExpression(e, sortField),
        mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
      ),
      (e) => OrderingTerm(expression: e.id),
    ]);

    q.limit(limit, offset: offset);
    return q.watch();
  }

  Expression _sortExpression(Invoices e, String field) {
    switch (field) {
      case InvoiceFieldIds.number:
        return e.number.lower();
      case InvoiceFieldIds.status:
        return e.statusId;
      case InvoiceFieldIds.clientId:
        return e.clientId;
      case InvoiceFieldIds.vendorId:
        return e.vendorId;
      case InvoiceFieldIds.projectId:
        return e.projectId;
      case InvoiceFieldIds.date:
        return e.date;
      case InvoiceFieldIds.dueDate:
        return e.dueDate;
      case InvoiceFieldIds.partialDueDate:
        return e.partialDueDate;
      case InvoiceFieldIds.amount:
        return e.amount.cast<double>();
      case InvoiceFieldIds.balance:
        return e.balance.cast<double>();
      case InvoiceFieldIds.paidToDate:
        return e.paidToDate.cast<double>();
      case InvoiceFieldIds.partial:
        return e.partial.cast<double>();
      case InvoiceFieldIds.poNumber:
        return e.poNumber.lower();
      case InvoiceFieldIds.designId:
        return e.designId;
      case InvoiceFieldIds.assignedUserId:
        return e.assignedUserId;
      case InvoiceFieldIds.updatedAt:
        return e.updatedAt;
      case InvoiceFieldIds.createdAt:
        return e.createdAt;
      case InvoiceFieldIds.customValue1:
        return e.customValue1.lower();
      case InvoiceFieldIds.customValue2:
        return e.customValue2.lower();
      case InvoiceFieldIds.customValue3:
        return e.customValue3.lower();
      case InvoiceFieldIds.customValue4:
        return e.customValue4.lower();
      default:
        // Silent fallback would mask real failures — see expense_dao.dart
        // for the rationale.
        throw ArgumentError(
          'Unknown sort field "$field" for Invoice — add a case in '
          '_sortExpression or stop exposing it as a sort option.',
        );
    }
  }

  /// Cheap stream used by the Client detail page's "Invoices" card. Filters
  /// by `client_id` + excludes deleted rows by default.
  Stream<List<InvoiceRow>> watchForClient({
    required String companyId,
    required String clientId,
    Set<EntityState> states = const {EntityState.active},
  }) {
    final q = select(invoices)
      ..where(
        (e) => e.companyId.equals(companyId) & e.clientId.equals(clientId),
      );
    if (states.isNotEmpty) {
      q.where(
        (e) => entityStateFilter(
          states: states,
          archivedAt: e.archivedAt,
          isDeleted: e.isDeleted,
        ),
      );
    }
    q.orderBy([
      (e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc),
    ]);
    return q.watch();
  }

  Stream<List<InvoiceRow>> watchForProject({
    required String companyId,
    required String projectId,
    Set<EntityState> states = const {EntityState.active},
  }) {
    final q = select(invoices)
      ..where(
        (e) => e.companyId.equals(companyId) & e.projectId.equals(projectId),
      );
    if (states.isNotEmpty) {
      q.where(
        (e) => entityStateFilter(
          states: states,
          archivedAt: e.archivedAt,
          isDeleted: e.isDeleted,
        ),
      );
    }
    q.orderBy([
      (e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc),
    ]);
    return q.watch();
  }
}

/// Free-text search helper. SQLite's JSON1 `json_extract` digs notes out of
/// the `payload` blob; same technique as `task_dao.dart`/`expense_dao.dart`.
extension on Invoices {
  Expression<bool> notesLikePayload(String needle) {
    return CustomExpression<bool>(
      "(lower(COALESCE(json_extract(payload, '\$.public_notes'), '')) "
      "LIKE '$needle' OR "
      "lower(COALESCE(json_extract(payload, '\$.private_notes'), '')) "
      "LIKE '$needle')",
    );
  }
}
