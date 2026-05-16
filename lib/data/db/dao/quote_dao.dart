import 'package:drift/drift.dart';

import 'package:admin/data/db/dao/_distinct_stream.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/base_entity_dao.dart';
import 'package:admin/data/db/dao/entity_query_helpers.dart';
import 'package:admin/data/db/tables/quotes_table.dart';
import 'package:admin/domain/entity_state.dart';

part 'quote_dao.g.dart';

/// Stable field-id constants for column + sort selection. Mirrors
/// `InvoiceFieldIds` — same fields minus the invoice-only `paid_to_date`,
/// `partial_due_date`, `partial`.
class QuoteFieldIds {
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
  static const String invoiceId = 'invoice_id';
  static const String publicNotes = 'public_notes';
  static const String privateNotes = 'private_notes';
  static const String updatedAt = 'updated_at';
  static const String createdAt = 'created_at';
  static const String customValue1 = 'custom_value1';
  static const String customValue2 = 'custom_value2';
  static const String customValue3 = 'custom_value3';
  static const String customValue4 = 'custom_value4';
}

@DriftAccessor(tables: [Quotes])
class QuoteDao extends BaseEntityDao<$QuotesTable, QuoteRow>
    with _$QuoteDaoMixin {
  QuoteDao(super.db);

  @override
  $QuotesTable get table => quotes;
  @override
  GeneratedColumn<String> get idColumn => quotes.id;
  @override
  GeneratedColumn<String> get companyIdColumn => quotes.companyId;
  @override
  GeneratedColumn<bool> get isDeletedColumn => quotes.isDeleted;
  @override
  GeneratedColumn<bool> get isDirtyColumn => quotes.isDirty;

  Stream<List<QuoteRow>> watchPage({
    required String companyId,
    required int offset,
    required int limit,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = QuoteFieldIds.number,
    bool sortAscending = false,
    String? clientId,
  }) {
    final q = select(quotes)..where((e) => e.companyId.equals(companyId));

    if (clientId != null && clientId.isNotEmpty) {
      q.where((e) => e.clientId.equals(clientId));
    }

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
    return q.watch().distinctRows();
  }

  Expression _sortExpression(Quotes e, String field) {
    switch (field) {
      case QuoteFieldIds.number:
        return e.number.lower();
      case QuoteFieldIds.status:
        return e.statusId;
      case QuoteFieldIds.clientId:
        return e.clientId;
      case QuoteFieldIds.vendorId:
        return e.vendorId;
      case QuoteFieldIds.projectId:
        return e.projectId;
      case QuoteFieldIds.date:
        return e.date;
      case QuoteFieldIds.dueDate:
        return e.dueDate;
      case QuoteFieldIds.amount:
        return e.amount.cast<double>();
      case QuoteFieldIds.balance:
        return e.balance.cast<double>();
      case QuoteFieldIds.poNumber:
        return e.poNumber.lower();
      case QuoteFieldIds.designId:
        return e.designId;
      case QuoteFieldIds.assignedUserId:
        return e.assignedUserId;
      case QuoteFieldIds.invoiceId:
        return e.invoiceId;
      case QuoteFieldIds.updatedAt:
        return e.updatedAt;
      case QuoteFieldIds.createdAt:
        return e.createdAt;
      case QuoteFieldIds.customValue1:
        return e.customValue1.lower();
      case QuoteFieldIds.customValue2:
        return e.customValue2.lower();
      case QuoteFieldIds.customValue3:
        return e.customValue3.lower();
      case QuoteFieldIds.customValue4:
        return e.customValue4.lower();
      default:
        throw ArgumentError(
          'Unknown sort field "$field" for Quote — add a case in '
          '_sortExpression or stop exposing it as a sort option.',
        );
    }
  }

  Stream<List<QuoteRow>> watchForClient({
    required String companyId,
    required String clientId,
    Set<EntityState> states = const {EntityState.active},
  }) {
    final q = select(quotes)
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
    return q.watch().distinctRows();
  }

  Stream<List<QuoteRow>> watchForProject({
    required String companyId,
    required String projectId,
    Set<EntityState> states = const {EntityState.active},
  }) {
    final q = select(quotes)
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
    return q.watch().distinctRows();
  }
}

extension on Quotes {
  Expression<bool> notesLikePayload(String needle) {
    return CustomExpression<bool>(
      "(lower(COALESCE(json_extract(payload, '\$.public_notes'), '')) "
      "LIKE '$needle' OR "
      "lower(COALESCE(json_extract(payload, '\$.private_notes'), '')) "
      "LIKE '$needle')",
    );
  }
}
