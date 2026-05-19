import 'package:admin/data/services/upload_source.dart';

import 'package:admin/data/models/api/payment_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Synthetic payload key the repository uses to thread the
/// `?email_receipt=…` query flag through the outbox without inflating the
/// `PaymentApi` DTO. Stripped + lifted to a query param in [PaymentsApi.create]
/// and [PaymentsApi.update].
const String kPaymentSendEmailKey = '_send_email';

/// Concrete API for `/api/v1/payments`. The base class handles list/get/
/// create/update/delete/action; this subclass overrides create + update to
/// thread the `email_receipt` query flag and adds the refund + apply +
/// document-upload entry points.
class PaymentsApi extends BaseEntityApi<PaymentListApi, PaymentItemApi> {
  PaymentsApi(super.client);

  @override
  String get basePath => '/api/v1/payments';

  @override
  PaymentListApi parseList(Object json) =>
      PaymentListApi.fromJson(json as Map<String, dynamic>);

  @override
  PaymentItemApi parseItem(Object json) =>
      PaymentItemApi.fromJson(json as Map<String, dynamic>);

  /// Override create so the outbox-supplied `_send_email` synthetic flag is
  /// lifted out of the body and onto the `email_receipt` query parameter.
  /// The flag is **always** appended on create (matches the legacy Flutter
  /// admin-portal `payment_repository.dart:82` — old clients sent
  /// `?email_receipt=false` literally rather than omitting the param).
  @override
  Future<PaymentItemApi> create({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    bool requiresPassword = false,
    Map<String, String>? query,
  }) async {
    final body = Map<String, dynamic>.of(payload);
    final sendEmail = body.remove(kPaymentSendEmailKey) == true;
    final raw = await client.mutate(
      method: 'POST',
      path: basePath,
      idempotencyKey: idempotencyKey,
      query: {
        if (query != null) ...query,
        'email_receipt': sendEmail.toString(),
      },
      body: body,
      requiresPassword: requiresPassword,
    );
    return parseItem(raw as Object);
  }

  /// Override update so the synthetic `_send_email` flag is lifted out and
  /// — when true — appended as `?email_receipt=true`. On update the query
  /// param is conditional (matches the legacy admin-portal behavior).
  @override
  Future<PaymentItemApi> update({
    required String id,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    bool requiresPassword = false,
    Map<String, String>? query,
  }) async {
    final body = Map<String, dynamic>.of(payload);
    final sendEmail = body.remove(kPaymentSendEmailKey) == true;
    final mergedQuery = <String, String>{
      ...?query,
      if (sendEmail) 'email_receipt': 'true',
    };
    final raw = await client.mutate(
      method: 'PUT',
      path: '$basePath/$id',
      idempotencyKey: idempotencyKey,
      query: mergedQuery.isEmpty ? null : mergedQuery,
      body: body,
      requiresPassword: requiresPassword,
    );
    return parseItem(raw as Object);
  }

  /// `POST /payments/refund?email_receipt=<bool>[&gateway_refund=true]`.
  ///
  /// Body: `{id, date, invoices: [{invoice_id, amount, id: ""}], ...}`.
  /// Returns the updated payment envelope.
  Future<PaymentApi> refund({
    required String id,
    required Map<String, dynamic> body,
    required String idempotencyKey,
    bool sendEmail = false,
    bool gatewayRefund = false,
  }) async {
    final query = <String, String>{
      'email_receipt': sendEmail.toString(),
      if (gatewayRefund) 'gateway_refund': 'true',
    };
    final raw = await client.mutate(
      method: 'POST',
      path: '$basePath/refund',
      idempotencyKey: idempotencyKey,
      query: query,
      body: body,
    );
    return parseItem(raw as Object).data;
  }

  /// `PUT /payments/{id}` with `{invoices: [{_id, amount, invoice_id, ...}]}`
  /// — distributes unapplied funds across one or more invoices.
  Future<PaymentApi> apply({
    required String id,
    required List<Map<String, dynamic>> allocations,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'PUT',
      path: '$basePath/$id',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{'invoices': allocations},
    );
    return parseItem(raw as Object).data;
  }

  /// Upload a document attachment to a payment. Mirrors `ExpensesApi`.
  Future<PaymentApi> uploadDocument({
    required String entityId,
    required UploadSource source,
    required String idempotencyKey,
  }) async {
    final file = await source.toMultipartFile('documents[]');
    final raw = await client.uploadMultipart(
      path: '$basePath/$entityId/upload',
      fields: const {'_method': 'POST'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object).data;
  }
}
