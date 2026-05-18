import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:admin/data/models/api/recurring_invoice_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/recurring_invoices`. Mirrors `InvoicesApi`
/// minus the invoice-only actions (mark_paid / auto_bill / cancel) and
/// adds the recurring-specific `start` / `stop` lifecycle actions.
class RecurringInvoicesApi
    extends BaseEntityApi<RecurringInvoiceListApi, RecurringInvoiceItemApi> {
  RecurringInvoicesApi(super.client);

  @override
  String get basePath => '/api/v1/recurring_invoices';

  @override
  RecurringInvoiceListApi parseList(Object json) =>
      RecurringInvoiceListApi.fromJson(json as Map<String, dynamic>);

  @override
  RecurringInvoiceItemApi parseItem(Object json) =>
      RecurringInvoiceItemApi.fromJson(json as Map<String, dynamic>);

  Future<RecurringInvoiceItemApi?> markSent({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'mark_sent', idempotencyKey: idempotencyKey);

  Future<RecurringInvoiceItemApi?> start({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'start', idempotencyKey: idempotencyKey);

  Future<RecurringInvoiceItemApi?> stop({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'stop', idempotencyKey: idempotencyKey);

  Future<RecurringInvoiceItemApi?> sendNow({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'send_now', idempotencyKey: idempotencyKey);

  Future<RecurringInvoiceItemApi?> email({
    required String id,
    required String template,
    String? subject,
    String? body,
    String? ccEmail,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'email',
        idempotencyKey: idempotencyKey,
        payload: {
          'template': template,
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
          if (ccEmail != null) 'cc_email': ccEmail,
        },
      );

  Future<RecurringInvoiceItemApi?> scheduleEmail({
    required String id,
    required String template,
    required String sendAt,
    String? subject,
    String? body,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'email',
        idempotencyKey: idempotencyKey,
        payload: {
          'template': template,
          'send_at': sendAt,
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
        },
      );

  Future<RecurringInvoiceItemApi?> cloneTo({
    required String id,
    required String targetType,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'clone_to_$targetType',
        idempotencyKey: idempotencyKey,
      );

  Future<RecurringInvoiceItemApi?> runTemplate({
    required String id,
    required String templateId,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'template',
        idempotencyKey: idempotencyKey,
        payload: {'template_id': templateId},
      );

  /// Server-rendered PDF via `POST /api/v1/live_preview?entity=recurring_invoice
  /// [&entity_id=<id>]` with the full entity (`RecurringInvoice.toApiJson()`)
  /// as the body — see `InvoicesApi.downloadPdf` for why `/api/v1/preview` is
  /// wrong here.
  Future<Uint8List> downloadPdf({
    required Map<String, dynamic> entityJson,
    String? designId,
  }) {
    final id = (entityJson['id'] as String?) ?? '';
    final saved = id.isNotEmpty && !id.startsWith('tmp_');
    final path =
        StringBuffer('/api/v1/live_preview?entity=recurring_invoice')
          ..write(saved ? '&entity_id=$id' : '');
    return client.postRaw(
      path.toString(),
      readOnly: true,
      body: {
        ...entityJson,
        if (designId != null && designId.isNotEmpty) 'design_id': designId,
      },
    );
  }

  Future<RecurringInvoiceApi> uploadDocument({
    required String entityId,
    required String filePath,
    required String idempotencyKey,
  }) async {
    final file = await http.MultipartFile.fromPath('documents[]', filePath);
    final raw = await client.uploadMultipart(
      path: '$basePath/$entityId/upload',
      fields: const {'_method': 'POST'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object).data;
  }
}
