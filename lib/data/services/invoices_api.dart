import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/invoices`. The base class handles list/get/
/// create/update/delete/action; this subclass supplies the path, the
/// parsers, custom action endpoints (markSent / markPaid / email /
/// scheduleEmail / cloneTo / autoBill / cancel / runTemplate), and the
/// multipart document upload.
///
/// Named `InvoicesApi` (plural) to avoid collision with `InvoiceApi` (the
/// single-resource model class in `data/models/api/invoice_api_model.dart`).
class InvoicesApi extends BaseEntityApi<InvoiceListApi, InvoiceItemApi> {
  InvoicesApi(super.client);

  @override
  String get basePath => '/api/v1/invoices';

  @override
  InvoiceListApi parseList(Object json) =>
      InvoiceListApi.fromJson(json as Map<String, dynamic>);

  @override
  InvoiceItemApi parseItem(Object json) =>
      InvoiceItemApi.fromJson(json as Map<String, dynamic>);

  /// `POST /api/v1/invoices/{id}/mark_sent` — Draft → Sent. Server returns
  /// the updated invoice envelope.
  Future<InvoiceItemApi?> markSent({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'mark_sent', idempotencyKey: idempotencyKey);

  /// `POST /api/v1/invoices/{id}/mark_paid` — records a synthetic payment
  /// for the outstanding balance.
  Future<InvoiceItemApi?> markPaid({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'mark_paid', idempotencyKey: idempotencyKey);

  /// `POST /api/v1/invoices/{id}/email` — send the invoice using a named
  /// template (`invoice`, `reminder1`, `reminder2`, `reminder3`,
  /// `endless_reminder`, `custom1..3`). Optional subject/body overrides
  /// the company default for this send only.
  Future<InvoiceItemApi?> email({
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

  /// `POST /api/v1/invoices/{id}/email` with a `send_at` future date —
  /// queues the email for delivery later. Pro plan only on the server.
  Future<InvoiceItemApi?> scheduleEmail({
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

  /// `POST /api/v1/invoices/{id}/clone_to_<target>`. Target is one of
  /// `invoice`, `quote`, `credit`, `recurring_invoice`, `purchase_order`.
  /// Server returns the newly-created entity envelope; the caller (the
  /// dispatcher's customActions handler) navigates to its edit screen.
  Future<InvoiceItemApi?> cloneTo({
    required String id,
    required String targetType,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'clone_to_$targetType',
        idempotencyKey: idempotencyKey,
      );

  /// `POST /api/v1/invoices/{id}/auto_bill` — charge the stored payment
  /// token on the client. Server returns the updated invoice (status
  /// flips to Partial / Paid on success).
  Future<InvoiceItemApi?> autoBill({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'auto_bill', idempotencyKey: idempotencyKey);

  /// `POST /api/v1/invoices/{id}/cancel` — mark a sent invoice as
  /// cancelled. Server returns the updated invoice.
  Future<InvoiceItemApi?> cancel({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'cancel', idempotencyKey: idempotencyKey);

  /// `POST /api/v1/invoices/{id}/template` — apply a design or email
  /// template. Payload carries `template_id`.
  Future<InvoiceItemApi?> runTemplate({
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

  /// Fetch a server-rendered PDF for this invoice. `POST /api/v1/preview`
  /// is the live-preview endpoint admin-portal uses; pass `entity: 'invoice'`
  /// + `entity_id: id` and the server returns PDF bytes for the current
  /// (saved) state. Optional `designId` overrides the invoice's design;
  /// `deliveryNote` switches to the delivery-note layout. `readOnly: true`
  /// on the underlying call skips the demo-mode short circuit and avoids
  /// creating an outbox row (this is a read in effect even though the wire
  /// verb is POST).
  Future<Uint8List> downloadPdf({
    required String id,
    String? designId,
    bool deliveryNote = false,
  }) {
    return client.postRaw(
      '/api/v1/preview',
      readOnly: true,
      body: {
        'entity': 'invoice',
        'entity_id': id,
        if (designId != null && designId.isNotEmpty) 'design_id': designId,
        if (deliveryNote) 'delivery_note': true,
      },
    );
  }

  /// Upload a document attachment to an invoice. Returns the refreshed
  /// invoice envelope with the new document in its `documents` array.
  /// Mirrors `ClientsApi.uploadDocument` — same multipart field name.
  Future<InvoiceItemApi> uploadDocument({
    required String invoiceId,
    required String filePath,
    required String idempotencyKey,
  }) async {
    final file = await http.MultipartFile.fromPath('documents[]', filePath);
    final raw = await client.uploadMultipart(
      path: '$basePath/$invoiceId/upload',
      fields: const {'_method': 'POST'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object);
  }
}
