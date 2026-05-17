import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/billing_extra_filters.dart';
import 'package:admin/data/db/dao/payment_dao.dart';
import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/api/payment_api_model.dart';
import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/document_bearing_repository.dart';
import 'package:admin/data/services/payments_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('PaymentRepository');

/// Source of truth for Payment data. UI watches Drift via [watchPage] and
/// [watch]; network only writes. Every mutation goes through the outbox.
///
/// Mirrors `ExpenseRepository`: document-bearing, password-gated
/// delete/purge/documentDelete. Adds two payment-only flows — `refund`
/// (`POST /payments/refund`) and `apply` (`PUT /payments/{id}` with an
/// `invoices` allocations array) — enqueued as their own `MutationKind`
/// variants and dispatched via `customActions`.
class PaymentRepository extends BaseEntityRepository<Payment, PaymentApi>
    implements DocumentBearingRepository {
  PaymentRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(
         entityType: EntityType.payment,
         requiresPasswordFor: const {
           MutationKind.delete,
           MutationKind.purge,
           MutationKind.documentDelete,
         },
       );

  final PaymentsApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'payment';

  /// Watch the first [loadedPages] pages of payment rows. Filters and sort
  /// mirror what the list ViewModel exposes; the dedicated
  /// `hasUnappliedFundsOnly` flag matches the "Has unapplied funds" chip.
  Stream<List<Payment>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    Set<String> statusIds = const {},
    bool hasUnappliedFundsOnly = false,
    String sortField = PaymentFieldIds.date,
    bool sortAscending = false,
    String? clientId,
    Map<String, Set<String>> extraFilters = const {},
  }) {
    assert(
      loadedPages >= 1,
      'loadedPages is 1-based; pass 1 for the first page',
    );
    final dateRange = parseDateRangeFilter(extraFilters, partCount: 3);
    // Fold the `client_status` filter into `statusIds` — the DAO already
    // resolves numeric ('1'..'6') + virtual ('-1'/'-2') discriminators,
    // and `parsePaymentStatusFilter` maps the wire labels onto them.
    final mergedStatusIds = {
      ...statusIds,
      ...parsePaymentStatusFilter(extraFilters),
    };
    return db.paymentDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: pageSize * loadedPages,
          search: search,
          states: states,
          statusIds: mergedStatusIds,
          hasUnappliedFundsOnly: hasUnappliedFundsOnly,
          sortField: sortField,
          sortAscending: sortAscending,
          clientId: clientId,
          clientIds: parseClientIdFilter(extraFilters),
          dateStart: dateRange.start,
          dateEnd: dateRange.end,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  Stream<int> watchCount({required String companyId}) =>
      db.paymentDao.watchCount(companyId: companyId);

  Stream<List<Payment>> watchForClient({
    required String companyId,
    required String clientId,
  }) {
    if (clientId.isEmpty) {
      return Stream<List<Payment>>.value(const <Payment>[]);
    }
    return db.paymentDao
        .watchForClient(companyId: companyId, clientId: clientId)
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  Stream<List<Payment>> watchForInvoice({
    required String companyId,
    required String invoiceId,
  }) {
    if (invoiceId.isEmpty) {
      return Stream<List<Payment>>.value(const <Payment>[]);
    }
    return db.paymentDao
        .watchForInvoice(companyId: companyId, invoiceId: invoiceId)
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  @override
  Stream<Payment?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.paymentDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Fetch one page from the server and upsert into Drift. Includes
  /// `client,invoices,paymentables` so the detail + refund screens have
  /// everything they need.
  Future<bool> ensurePageLoaded({
    required String companyId,
    required int page,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    Map<String, Set<String>> extraFilters = const {},
    bool ignoreCursor = false,
  }) => ensurePageLoadedTemplate(
    companyId: companyId,
    page: page,
    pageSize: pageSize,
    search: search,
    states: states,
    extraFilters: extraFilters,
    ignoreCursor: ignoreCursor,
    staticFilters: const {'include': 'client,invoices,paymentables,documents'},
    listCall: api.list,
    itemsOf: (l) => l.data,
    idOf: (a) => a.id,
    toCompanion: (a) => _apiToCompanion(a, companyId),
    upsert: (byId) => db.paymentDao.upsertAllPreservingDirty(
      companyId: companyId,
      byId: byId,
    ),
  );

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
        _log.warning(
          'refreshAll hit the $maxPages page safety cap for company '
          '$companyId — cursor will resume on the next sync trigger.',
        );
        break;
      }
    }
  }

  /// Create a new payment offline. [sendEmail] threads through the
  /// outbox as a synthetic `_send_email` flag that [PaymentsApi.create]
  /// lifts to `?email_receipt=…` (always-appended on create).
  Future<Payment> create({
    required String companyId,
    required Payment draft,
    required bool sendEmail,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);

    await db.transaction(() async {
      await db.paymentDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: <String, dynamic>{
          ...stored.toApiJson(),
          kPaymentSendEmailKey: sendEmail,
        },
      );
    });
    return stored;
  }

  Future<void> save({
    required String companyId,
    required Payment payment,
    required bool sendEmail,
  }) async {
    final companion = _domainToCompanion(payment, companyId, isDirty: true);
    await db.transaction(() async {
      await db.paymentDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: payment.id,
        kind: MutationKind.update,
        payload: <String, dynamic>{
          ...payment.toApiJson(preserveTempId: true),
          kPaymentSendEmailKey: sendEmail,
        },
      );
    });
  }

  /// Refund a payment. Posts `POST /payments/refund` via the outbox.
  /// [invoices] entries shape: `{invoice_id, amount}` per row.
  Future<void> refund({
    required String companyId,
    required String paymentId,
    required String date,
    required List<Map<String, dynamic>> invoices,
    required bool sendEmail,
    required bool gatewayRefund,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: paymentId,
      kind: MutationKind.refundPayment,
      payload: <String, dynamic>{
        'id': paymentId,
        'date': date,
        'invoices': invoices,
        'send_email': sendEmail,
        'gateway_refund': gatewayRefund,
      },
    );
  }

  /// Apply unapplied payment funds to one or more invoices. Hits
  /// `PUT /payments/{id}` with body `{invoices: [...]}`.
  Future<void> apply({
    required String companyId,
    required String paymentId,
    required List<Map<String, dynamic>> allocations,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: paymentId,
      kind: MutationKind.applyPayment,
      payload: <String, dynamic>{
        'id': paymentId,
        'invoices': allocations,
      },
    );
  }

  /// Append a user comment to this payment's activity stream.
  Future<void> addComment({
    required String companyId,
    required String paymentId,
    required String text,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: paymentId,
      kind: MutationKind.addComment,
      payload: {'entity_id': paymentId, 'notes': text.trim()},
    );
  }

  @override
  Future<void> uploadDocument({
    required String companyId,
    required String entityId,
    required String localPath,
  }) {
    return enqueueMutation(
      companyId: companyId,
      entityId: entityId,
      kind: MutationKind.documentUpload,
      payload: {'entity_id': entityId, 'local_path': localPath},
    );
  }

  @override
  Future<void> deleteDocument({
    required String companyId,
    required String entityId,
    required String documentId,
  }) {
    return enqueueMutation(
      companyId: companyId,
      entityId: entityId,
      kind: MutationKind.documentDelete,
      payload: {'entity_id': entityId, 'document_id': documentId},
    );
  }

  @override
  Future<void> setDocumentVisibility({
    required String companyId,
    required String entityId,
    required String documentId,
    required bool isPublic,
  }) {
    return enqueueMutation(
      companyId: companyId,
      entityId: entityId,
      kind: MutationKind.documentVisibility,
      payload: {
        'entity_id': entityId,
        'document_id': documentId,
        'is_public': isPublic,
      },
    );
  }

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required PaymentApi serverResponse,
  }) => applyCreateResponseTemplate(
    companyId: companyId,
    tempId: tempId,
    realId: serverResponse.id,
    companion: _apiToCompanion(serverResponse, companyId),
    upsert: db.paymentDao.upsert,
    deleteById: (id) => db.paymentDao.deleteById(companyId: companyId, id: id),
  );

  @override
  Future<void> applyUpdateResponse({
    required String companyId,
    required PaymentApi serverResponse,
  }) async {
    await db.paymentDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.paymentDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.paymentDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  Future<void> applyDocumentDeleted({
    required String companyId,
    required String entityId,
    required String documentId,
  }) async {
    final row = await db.paymentDao
        .watchById(companyId: companyId, id: entityId)
        .first;
    if (row == null) return;
    final current = decodeRawDocumentsColumn(row.documents);
    final next = current.where((d) => d.id != documentId).toList();
    if (next.length == current.length) return;
    await (db.update(db.payments)..where((p) => p.id.equals(entityId))).write(
      PaymentsCompanion(
        documents: Value(jsonEncode(next.map((d) => d.toJson()).toList())),
      ),
    );
  }

  Future<void> applyDocumentChanged({
    required String companyId,
    required String entityId,
    required DocumentApi document,
  }) async {
    final row = await db.paymentDao
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
    await (db.update(db.payments)..where((p) => p.id.equals(entityId))).write(
      PaymentsCompanion(
        documents: Value(jsonEncode(next.map((d) => d.toJson()).toList())),
      ),
    );
  }

  // -------------------- conversions --------------------

  PaymentsCompanion _apiToCompanion(PaymentApi a, String companyId) {
    return PaymentsCompanion.insert(
      id: a.id,
      companyId: companyId,
      number: Value(a.number),
      date: Value(a.date),
      amount: Value(_moneyString(a.amount)),
      applied: Value(_moneyString(a.applied)),
      refunded: Value(_moneyString(a.refunded)),
      exchangeRate: Value(_moneyString(a.exchangeRate)),
      statusId: Value(a.statusId),
      typeId: Value(a.typeId),
      clientId: Value(a.clientId),
      vendorId: Value(a.vendorId),
      projectId: Value(a.projectId),
      companyGatewayId: Value(a.companyGatewayId),
      gatewayTypeId: Value(a.gatewayTypeId),
      currencyId: Value(a.currencyId),
      exchangeCurrencyId: Value(a.exchangeCurrencyId),
      transactionReference: Value(a.transactionReference),
      isManual: Value(a.isManual),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      customValue1: Value(a.customValue1),
      customValue2: Value(a.customValue2),
      customValue3: Value(a.customValue3),
      customValue4: Value(a.customValue4),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      paymentables: a.paymentables == null
          ? const Value.absent()
          : Value(jsonEncode(a.paymentables!.map((p) => p.toJson()).toList())),
      invoices: a.invoices == null
          ? const Value.absent()
          : Value(jsonEncode(a.invoices!.map((i) => i.toJson()).toList())),
      credits: a.credits == null
          ? const Value.absent()
          : Value(jsonEncode(a.credits!.map((c) => c.toJson()).toList())),
      documents: a.documents == null
          ? const Value.absent()
          : Value(jsonEncode(a.documents!.map((d) => d.toJson()).toList())),
      payload: jsonEncode(a.toJson()),
    );
  }

  PaymentsCompanion _domainToCompanion(
    Payment p,
    String companyId, {
    required bool isDirty,
  }) {
    return PaymentsCompanion.insert(
      id: p.id,
      companyId: companyId,
      number: Value(p.number),
      date: Value(p.date?.toIso() ?? ''),
      amount: Value(p.amount.toString()),
      applied: Value(p.applied.toString()),
      refunded: Value(p.refunded.toString()),
      exchangeRate: Value(p.exchangeRate.toString()),
      statusId: Value(p.statusId),
      typeId: Value(p.typeId),
      clientId: Value(p.clientId),
      vendorId: Value(p.vendorId),
      projectId: Value(p.projectId),
      companyGatewayId: Value(p.companyGatewayId),
      gatewayTypeId: Value(p.gatewayTypeId),
      currencyId: Value(p.currencyId),
      exchangeCurrencyId: Value(p.exchangeCurrencyId),
      transactionReference: Value(p.transactionReference),
      isManual: Value(p.isManual),
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
      paymentables: Value(
        jsonEncode(
          p.paymentables
              .map(
                (pa) => <String, dynamic>{
                  'id': pa.id,
                  'invoice_id': pa.invoiceId,
                  'credit_id': pa.creditId,
                  'amount': pa.amount.toString(),
                  'refunded': pa.refunded.toString(),
                  'created_at': pa.createdAt,
                  'updated_at': pa.updatedAt,
                  'archived_at': pa.archivedAt,
                },
              )
              .toList(),
        ),
      ),
      invoices: Value(
        jsonEncode(
          p.invoices
              .map(
                (i) => <String, dynamic>{
                  'id': i.id,
                  'number': i.number,
                  'amount': i.amount.toString(),
                  'balance': i.balance.toString(),
                  'paid_to_date': i.paidToDate.toString(),
                },
              )
              .toList(),
        ),
      ),
      credits: Value(
        jsonEncode(
          p.credits
              .map(
                (c) => <String, dynamic>{
                  'id': c.id,
                  'number': c.number,
                  'amount': c.amount.toString(),
                  'balance': c.balance.toString(),
                },
              )
              .toList(),
        ),
      ),
      documents: Value(
        jsonEncode(p.documents.map((d) => d.toApi().toJson()).toList()),
      ),
      payload: jsonEncode(p.toApiJson(preserveTempId: true)),
    );
  }

  Payment _fromRow(PaymentRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    // Overlay the nested-array columns onto the payload so the domain
    // factory sees the freshest data without re-parsing payload-embedded
    // arrays that may have aged behind a server-include refresh.
    final paymentables = _decodeList(row.paymentables);
    final invoices = _decodeList(row.invoices);
    final credits = _decodeList(row.credits);
    if (paymentables != null) json['paymentables'] = paymentables;
    if (invoices != null) json['invoices'] = invoices;
    if (credits != null) json['credits'] = credits;
    final api = PaymentApi.fromJson(json);
    return Payment.fromApi(api).copyWith(
      isDirty: row.isDirty,
      documents: decodeDocumentsColumn(row.documents),
    );
  }
}

List<dynamic>? _decodeList(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded;
  } catch (_) {}
  return null;
}

String _moneyString(Object raw) {
  if (raw is String) return raw;
  return raw.toString();
}
