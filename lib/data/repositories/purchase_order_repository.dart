import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/purchase_order_dao.dart';
import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/api/purchase_order_api_model.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/purchase_orders_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('PurchaseOrderRepository');

class PurchaseOrderRepository
    extends BaseEntityRepository<PurchaseOrder, PurchaseOrderApi> {
  PurchaseOrderRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(entityType: EntityType.purchaseOrder);

  final PurchaseOrdersApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'purchase_order';

  @override
  bool requiresPasswordFor(MutationKind kind) =>
      kind == MutationKind.delete ||
      kind == MutationKind.purge ||
      kind == MutationKind.documentDelete;

  Stream<List<PurchaseOrder>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = PurchaseOrderFieldIds.number,
    bool sortAscending = false,
  }) {
    assert(loadedPages >= 1);
    return db.purchaseOrderDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: pageSize * loadedPages,
          search: search,
          states: states,
          sortField: sortField,
          sortAscending: sortAscending,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  Stream<int> watchCount({required String companyId}) =>
      db.purchaseOrderDao.watchCount(companyId: companyId);

  Stream<List<PurchaseOrder>> watchForVendor({
    required String companyId,
    required String vendorId,
  }) {
    if (vendorId.isEmpty) {
      return Stream<List<PurchaseOrder>>.value(const <PurchaseOrder>[]);
    }
    return db.purchaseOrderDao
        .watchForVendor(companyId: companyId, vendorId: vendorId)
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  @override
  Stream<PurchaseOrder?> watchByRealId({
    required String companyId,
    required String id,
  }) =>
      db.purchaseOrderDao
          .watchById(companyId: companyId, id: id)
          .map((row) => row == null ? null : _fromRow(row));

  Future<bool> ensurePageLoaded({
    required String companyId,
    required int page,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    Map<String, Set<String>> extraFilters = const {},
    bool ignoreCursor = false,
  }) async {
    final cursor = ignoreCursor
        ? null
        : await db.syncStateDao.read(
            companyId: companyId,
            entityType: entityTypeName,
          );
    final filters = <String, String>{
      ...stateQueryParams(states),
      'include': 'documents',
      for (final entry in extraFilters.entries)
        if (entry.value.isNotEmpty)
          entry.key: (entry.value.toList()..sort()).join(','),
    };
    final result = await api.list(
      page: page,
      perPage: pageSize,
      search: search,
      sinceUpdatedAt: cursor?.updatedAt,
      sinceId: cursor?.id,
      filters: filters,
    );
    final apiRows = result.data.data;
    if (apiRows.isEmpty) return false;
    await db.purchaseOrderDao.upsertAllPreservingDirty(
      companyId: companyId,
      byId: {for (final a in apiRows) a.id: _apiToCompanion(a, companyId)},
    );
    if (result.cursorUpdatedAt != null && result.cursorId != null) {
      await advanceCursor(
        companyId: companyId,
        updatedAt: result.cursorUpdatedAt!,
        id: result.cursorId!,
        wasFullSync: ignoreCursor && page == 1,
      );
    }
    return apiRows.length >= pageSize;
  }

  Future<void> refreshAll({
    required String companyId,
    bool full = false,
  }) async {
    if (full) {
      await db.syncStateDao.reset(
        companyId: companyId,
        entityType: entityTypeName,
      );
    }
    var page = 1;
    var hasMore = true;
    const maxPages = 1000;
    final allStates = EntityState.values.toSet();
    while (hasMore) {
      hasMore = await ensurePageLoaded(
        companyId: companyId,
        page: page,
        states: allStates,
        ignoreCursor: full && page == 1,
      );
      page++;
      if (page > maxPages) {
        _log.warning('refreshAll hit page cap for company $companyId');
        break;
      }
    }
  }

  Future<PurchaseOrder> create({
    required String companyId,
    required PurchaseOrder draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);
    await db.transaction(() async {
      await db.purchaseOrderDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: stored.toApiJson(),
      );
    });
    return stored;
  }

  Future<void> save({
    required String companyId,
    required PurchaseOrder purchaseOrder,
  }) async {
    final companion =
        _domainToCompanion(purchaseOrder, companyId, isDirty: true);
    await db.transaction(() async {
      await db.purchaseOrderDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: purchaseOrder.id,
        kind: MutationKind.update,
        payload: purchaseOrder.toApiJson(preserveTempId: true),
      );
    });
  }

  @override
  Future<void> delete({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.delete,
        payload: {'id': id},
      );

  @override
  Future<void> purge({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.purge,
        payload: {'id': id},
      );

  @override
  Future<void> archive({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.archive,
        payload: {'id': id},
      );

  @override
  Future<void> restore({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.restore,
        payload: {'id': id},
      );

  // ── Custom actions ─────────────────────────────────────────────────

  Future<void> markSent({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.markSent,
        payload: {'id': id},
      );

  Future<void> accept({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.acceptOrder,
        payload: {'id': id},
      );

  Future<void> cancel({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.cancelEntity,
        payload: {'id': id},
      );

  Future<void> convertToExpense({
    required String companyId,
    required String id,
  }) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.convertToExpense,
        payload: {'id': id},
      );

  Future<void> email({
    required String companyId,
    required String id,
    required String template,
    String? subject,
    String? body,
    String? ccEmail,
  }) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.emailEntity,
        payload: {
          'id': id,
          'template': template,
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
          if (ccEmail != null) 'cc_email': ccEmail,
        },
      );

  Future<void> scheduleEmail({
    required String companyId,
    required String id,
    required String template,
    required String sendAt,
    String? subject,
    String? body,
  }) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.scheduleEmail,
        payload: {
          'id': id,
          'template': template,
          'send_at': sendAt,
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
        },
      );

  Future<void> cloneTo({
    required String companyId,
    required String id,
    required String targetType,
  }) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: _cloneKindFor(targetType),
        payload: {'id': id, 'target': targetType},
      );

  Future<void> runTemplate({
    required String companyId,
    required String id,
    required String templateId,
  }) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.runTemplate,
        payload: {'id': id, 'template_id': templateId},
      );

  Future<void> addComment({
    required String companyId,
    required String purchaseOrderId,
    required String text,
  }) =>
      enqueueMutation(
        companyId: companyId,
        entityId: purchaseOrderId,
        kind: MutationKind.addComment,
        payload: {'entity_id': purchaseOrderId, 'notes': text.trim()},
      );

  // ── Documents ──────────────────────────────────────────────────────

  Future<void> uploadDocument({
    required String companyId,
    required String entityId,
    required String localPath,
  }) =>
      enqueueMutation(
        companyId: companyId,
        entityId: entityId,
        kind: MutationKind.documentUpload,
        payload: {'entity_id': entityId, 'local_path': localPath},
      );

  Future<void> deleteDocument({
    required String companyId,
    required String entityId,
    required String documentId,
  }) =>
      enqueueMutation(
        companyId: companyId,
        entityId: entityId,
        kind: MutationKind.documentDelete,
        payload: {'entity_id': entityId, 'document_id': documentId},
      );

  Future<void> setDocumentVisibility({
    required String companyId,
    required String entityId,
    required String documentId,
    required bool isPublic,
  }) =>
      enqueueMutation(
        companyId: companyId,
        entityId: entityId,
        kind: MutationKind.documentVisibility,
        payload: {
          'entity_id': entityId,
          'document_id': documentId,
          'is_public': isPublic,
        },
      );

  // ── Apply* response handlers ───────────────────────────────────────

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required PurchaseOrderApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.purchaseOrderDao
          .upsert(_apiToCompanion(serverResponse, companyId));
      if (realId != tempId) {
        await db.purchaseOrderDao.deleteById(companyId: companyId, id: tempId);
      }
      await recordCreateSuccess(
        companyId: companyId,
        tempId: tempId,
        realId: realId,
      );
    });
  }

  @override
  Future<void> applyUpdateResponse({
    required String companyId,
    required PurchaseOrderApi serverResponse,
  }) async {
    await db.purchaseOrderDao
        .upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.purchaseOrderDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.purchaseOrderDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  @override
  Future<void> applyPurgeResponse({
    required String companyId,
    required String id,
  }) async {
    await db.purchaseOrderDao.deleteById(companyId: companyId, id: id);
  }

  Future<void> applyDocumentDeleted({
    required String companyId,
    required String entityId,
    required String documentId,
  }) async {
    final row = await db.purchaseOrderDao
        .watchById(companyId: companyId, id: entityId)
        .first;
    if (row == null) return;
    final current = decodeRawDocumentsColumn(row.documents);
    final next = current.where((d) => d.id != documentId).toList();
    if (next.length == current.length) return;
    await (db.update(db.purchaseOrders)..where((e) => e.id.equals(entityId)))
        .write(
      PurchaseOrdersCompanion(
        documents: Value(jsonEncode(next.map((d) => d.toJson()).toList())),
      ),
    );
  }

  Future<void> applyDocumentChanged({
    required String companyId,
    required String entityId,
    required DocumentApi document,
  }) async {
    final row = await db.purchaseOrderDao
        .watchById(companyId: companyId, id: entityId)
        .first;
    if (row == null) return;
    final current = decodeRawDocumentsColumn(row.documents);
    final next = [
      for (final d in current)
        if (d.id == document.id) document else d,
    ];
    if (!current.any((d) => d.id == document.id)) {
      next.add(document);
    }
    await (db.update(db.purchaseOrders)..where((e) => e.id.equals(entityId)))
        .write(
      PurchaseOrdersCompanion(
        documents: Value(jsonEncode(next.map((d) => d.toJson()).toList())),
      ),
    );
  }

  // ── Conversions ────────────────────────────────────────────────────

  PurchaseOrdersCompanion _apiToCompanion(
    PurchaseOrderApi a,
    String companyId,
  ) {
    return PurchaseOrdersCompanion.insert(
      id: a.id,
      companyId: companyId,
      number: Value(a.number),
      statusId: Value(a.statusId),
      clientId: Value(a.clientId),
      vendorId: Value(a.vendorId),
      projectId: Value(a.projectId),
      expenseId: Value(a.expenseId),
      date: Value(a.date),
      dueDate: Value(a.dueDate),
      amount: Value(_moneyString(a.amount)),
      balance: Value(_moneyString(a.balance)),
      poNumber: Value(a.poNumber),
      designId: Value(a.designId),
      assignedUserId: Value(a.assignedUserId),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      customValue1: Value(a.customValue1),
      customValue2: Value(a.customValue2),
      customValue3: Value(a.customValue3),
      customValue4: Value(a.customValue4),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      documents: a.documents == null
          ? const Value.absent()
          : Value(jsonEncode(a.documents!.map((d) => d.toJson()).toList())),
      payload: jsonEncode(a.toJson()),
    );
  }

  PurchaseOrdersCompanion _domainToCompanion(
    PurchaseOrder p,
    String companyId, {
    required bool isDirty,
  }) {
    return PurchaseOrdersCompanion.insert(
      id: p.id,
      companyId: companyId,
      number: Value(p.number),
      statusId: Value(p.statusId.wireId),
      clientId: Value(p.clientId),
      vendorId: Value(p.vendorId),
      projectId: Value(p.projectId),
      expenseId: Value(p.expenseId),
      date: Value(p.date?.toIso() ?? ''),
      dueDate: Value(p.dueDate?.toIso() ?? ''),
      amount: Value(p.amount.toString()),
      balance: Value(p.balance.toString()),
      poNumber: Value(p.poNumber),
      designId: Value(p.designId),
      assignedUserId: Value(p.assignedUserId),
      updatedAt: dateToEpochSeconds(p.updatedAt),
      createdAt: Value(dateToEpochSeconds(p.createdAt)),
      archivedAt: p.archivedAt == null
          ? const Value.absent()
          : Value(dateToEpochSeconds(p.archivedAt!)),
      customValue1: Value(p.customValue1),
      customValue2: Value(p.customValue2),
      customValue3: Value(p.customValue3),
      customValue4: Value(p.customValue4),
      isDirty: Value(isDirty),
      isDeleted: Value(p.isDeleted),
      documents: Value(
        jsonEncode(p.documents.map((d) => d.toApi().toJson()).toList()),
      ),
      payload: jsonEncode(p.toApiJson(preserveTempId: true)),
    );
  }

  PurchaseOrder _fromRow(PurchaseOrderRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = PurchaseOrderApi.fromJson(json);
    return PurchaseOrder.fromApi(api).copyWith(
      isDirty: row.isDirty,
      documents: decodeDocumentsColumn(row.documents),
    );
  }
}

MutationKind _cloneKindFor(String targetType) {
  switch (targetType) {
    case 'invoice':
      return MutationKind.cloneToInvoice;
    case 'quote':
      return MutationKind.cloneToQuote;
    case 'credit':
      return MutationKind.cloneToCredit;
    case 'recurring_invoice':
      return MutationKind.cloneToRecurring;
    case 'purchase_order':
      return MutationKind.cloneToPurchaseOrder;
    default:
      throw ArgumentError(
        'Unknown clone target "$targetType" — must be one of '
        'invoice|quote|credit|recurring_invoice|purchase_order',
      );
  }
}

String _moneyString(Object raw) {
  if (raw is String) return raw;
  return raw.toString();
}
