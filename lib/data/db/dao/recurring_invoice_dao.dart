import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/base_entity_dao.dart';
import 'package:admin/data/db/dao/entity_query_helpers.dart';
import 'package:admin/data/db/tables/recurring_invoices_table.dart';
import 'package:admin/domain/entity_state.dart';

part 'recurring_invoice_dao.g.dart';

class RecurringInvoiceFieldIds {
  static const String number = 'number';
  static const String status = 'status_id';
  static const String clientId = 'client_id';
  static const String vendorId = 'vendor_id';
  static const String projectId = 'project_id';
  static const String date = 'date';
  static const String dueDate = 'due_date';
  static const String amount = 'amount';
  static const String balance = 'balance';
  static const String poNumber = 'po_number';
  static const String designId = 'design_id';
  static const String assignedUserId = 'assigned_user_id';
  static const String frequencyId = 'frequency_id';
  static const String nextSendDate = 'next_send_date';
  static const String remainingCycles = 'remaining_cycles';
  static const String autoBill = 'auto_bill';
  static const String publicNotes = 'public_notes';
  static const String privateNotes = 'private_notes';
  static const String updatedAt = 'updated_at';
  static const String createdAt = 'created_at';
  static const String customValue1 = 'custom_value1';
  static const String customValue2 = 'custom_value2';
  static const String customValue3 = 'custom_value3';
  static const String customValue4 = 'custom_value4';
}

@DriftAccessor(tables: [RecurringInvoices])
class RecurringInvoiceDao
    extends BaseEntityDao<$RecurringInvoicesTable, RecurringInvoiceRow>
    with _$RecurringInvoiceDaoMixin {
  RecurringInvoiceDao(super.db);

  @override
  $RecurringInvoicesTable get table => recurringInvoices;
  @override
  GeneratedColumn<String> get idColumn => recurringInvoices.id;
  @override
  GeneratedColumn<String> get companyIdColumn => recurringInvoices.companyId;
  @override
  GeneratedColumn<bool> get isDeletedColumn => recurringInvoices.isDeleted;
  @override
  GeneratedColumn<bool> get isDirtyColumn => recurringInvoices.isDirty;

  Stream<List<RecurringInvoiceRow>> watchPage({
    required String companyId,
    required int offset,
    required int limit,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = RecurringInvoiceFieldIds.number,
    bool sortAscending = false,
  }) {
    final q = select(recurringInvoices)
      ..where((e) => e.companyId.equals(companyId));
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

  Expression _sortExpression(RecurringInvoices e, String field) {
    switch (field) {
      case RecurringInvoiceFieldIds.number:
        return e.number.lower();
      case RecurringInvoiceFieldIds.status:
        return e.statusId;
      case RecurringInvoiceFieldIds.clientId:
        return e.clientId;
      case RecurringInvoiceFieldIds.vendorId:
        return e.vendorId;
      case RecurringInvoiceFieldIds.projectId:
        return e.projectId;
      case RecurringInvoiceFieldIds.date:
        return e.date;
      case RecurringInvoiceFieldIds.dueDate:
        return e.dueDate;
      case RecurringInvoiceFieldIds.amount:
        return e.amount.cast<double>();
      case RecurringInvoiceFieldIds.balance:
        return e.balance.cast<double>();
      case RecurringInvoiceFieldIds.poNumber:
        return e.poNumber.lower();
      case RecurringInvoiceFieldIds.designId:
        return e.designId;
      case RecurringInvoiceFieldIds.assignedUserId:
        return e.assignedUserId;
      case RecurringInvoiceFieldIds.frequencyId:
        return e.frequencyId;
      case RecurringInvoiceFieldIds.nextSendDate:
        return e.nextSendDate;
      case RecurringInvoiceFieldIds.remainingCycles:
        return e.remainingCycles;
      case RecurringInvoiceFieldIds.autoBill:
        return e.autoBill;
      case RecurringInvoiceFieldIds.updatedAt:
        return e.updatedAt;
      case RecurringInvoiceFieldIds.createdAt:
        return e.createdAt;
      case RecurringInvoiceFieldIds.customValue1:
        return e.customValue1.lower();
      case RecurringInvoiceFieldIds.customValue2:
        return e.customValue2.lower();
      case RecurringInvoiceFieldIds.customValue3:
        return e.customValue3.lower();
      case RecurringInvoiceFieldIds.customValue4:
        return e.customValue4.lower();
      default:
        throw ArgumentError(
          'Unknown sort field "$field" for RecurringInvoice — add a case in '
          '_sortExpression or stop exposing it as a sort option.',
        );
    }
  }

  Stream<List<RecurringInvoiceRow>> watchForClient({
    required String companyId,
    required String clientId,
    Set<EntityState> states = const {EntityState.active},
  }) {
    final q = select(recurringInvoices)
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
}

extension on RecurringInvoices {
  Expression<bool> notesLikePayload(String needle) {
    return CustomExpression<bool>(
      "(lower(COALESCE(json_extract(payload, '\$.public_notes'), '')) "
      "LIKE '$needle' OR "
      "lower(COALESCE(json_extract(payload, '\$.private_notes'), '')) "
      "LIKE '$needle')",
    );
  }
}
