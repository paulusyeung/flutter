import 'dart:convert';
import 'dart:typed_data';

import 'package:admin/data/services/upload_source.dart';

import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Result of `POST /api/v1/einvoice/validateEntity`. [passes] is the
/// server's overall verdict; [messages] flattens the per-entity issue
/// arrays into readable lines (empty when valid).
typedef EInvoiceValidation = ({bool passes, List<String> messages});

/// Parse the probe-verified validateEntity shape:
/// `{passes:bool, invoices:[], recurring_invoices:[], clients:[],
/// companies:[]}`. The issue-array *element* shape can't be confirmed
/// (the demo invoice passes — empty arrays), so extract a readable string
/// defensively: prefer a `message`/`label`/`field` key on a map, else
/// JSON-encode the element. Pure + unit-tested.
EInvoiceValidation parseEInvoiceValidation(Object? raw) {
  if (raw is! Map) return (passes: false, messages: const <String>[]);
  final passes = raw['passes'] == true;
  final messages = <String>[];
  for (final group in const [
    'invoices',
    'recurring_invoices',
    'clients',
    'companies',
  ]) {
    final list = raw[group];
    if (list is! List) continue;
    for (final e in list) {
      if (e is Map) {
        final m = e['message'] ?? e['label'] ?? e['field'];
        messages.add(m is String && m.isNotEmpty ? m : jsonEncode(e));
      } else if (e is String) {
        if (e.isNotEmpty) messages.add(e);
      } else {
        messages.add('$e');
      }
    }
  }
  return (passes: passes, messages: messages);
}

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

  /// Fetch a server-rendered PDF for this invoice.
  ///
  /// Two endpoints, picked by [deliveryNote]:
  ///
  /// * Normal layout — `POST /api/v1/live_preview?entity=invoice[&entity_id=<id>]`,
  ///   body = the **full invoice entity** (`Invoice.toApiJson()` — the same
  ///   shape the save/outbox path sends), exactly as React and admin-portal do.
  ///   The server resolves the design from the entity's `design_id`. (The old
  ///   `/api/v1/preview` is the design-editor endpoint and rejects an entity
  ///   body with "Invalid custom design object".) `entity_id` is sent only for
  ///   a saved invoice. Optional [designId] overrides the design.
  ///
  /// * Delivery note (`deliveryNote: true` **and** saved id) —
  ///   `GET /api/v1/invoices/{id}/delivery_note[?design_id=<id>]`. This is the
  ///   only path that actually renders the delivery-note layout: `live_preview`
  ///   ignores a `delivery_note` body field (it hardcodes the PDF type to
  ///   `product`). Matches React (`useGeneratePdfUrl.ts`) and admin-portal
  ///   (`lib/ui/invoice/invoice_pdf.dart`). Requires a real id — for unsaved
  ///   drafts the UI hides the toggle, but if called we fall through to the
  ///   live-preview path so the caller still gets a PDF instead of a 404.
  ///
  /// `readOnly: true` on both wire calls skips the demo-mode short-circuit
  /// and the outbox (reads in effect).
  Future<Uint8List> downloadPdf({
    required Map<String, dynamic> entityJson,
    String? designId,
    bool deliveryNote = false,
  }) {
    final id = (entityJson['id'] as String?) ?? '';
    final saved = id.isNotEmpty && !id.startsWith('tmp_');

    if (deliveryNote && saved) {
      final qs = (designId != null && designId.isNotEmpty)
          ? '?design_id=$designId'
          : '';
      return client.getRaw(
        '/api/v1/invoices/$id/delivery_note$qs',
        readOnly: true,
      );
    }

    final path = StringBuffer('/api/v1/live_preview?entity=invoice')
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

  /// `POST /api/v1/einvoice/peppol/send` `{entity:'invoice', entity_id}` —
  /// transmit the invoice via the configured e-invoice channel
  /// (PEPPOL / Verifactu-AEAT). React parity (`Verifactu.tsx`). The
  /// server owns the transmission; caller re-fetches the invoice after.
  Future<void> sendEInvoice({
    required String id,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'POST',
      path: '/api/v1/einvoice/peppol/send',
      idempotencyKey: idempotencyKey,
      body: {'entity': 'invoice', 'entity_id': id},
    );
  }

  /// `POST /api/v1/einvoice/validateEntity` `{entity:'invoices',
  /// entity_id}` — pre-flight validation (no transmission). `readOnly` —
  /// it validates, it doesn't submit. Probe-verified response shape:
  /// `{passes:bool, invoices:[], recurring_invoices:[], clients:[],
  /// companies:[]}` (issue arrays empty when valid).
  Future<EInvoiceValidation> validateEInvoice(String id) async {
    final raw = await client.postJson(
      '/api/v1/einvoice/validateEntity',
      body: {'entity': 'invoices', 'entity_id': id},
      readOnly: true,
    );
    return parseEInvoiceValidation(raw);
  }

  /// `GET /api/v1/invoices/{id}?show_schedule=true` — the only fetch that
  /// embeds the read-only `invoice.schedule[]` payment-schedule projection
  /// (probe-verified: absent on plain/list GETs). Used by the detail
  /// fetch + the payment-schedule custom-action re-fetch.
  Future<InvoiceItemApi> getWithSchedule(String id) async {
    final raw = await client.getOne('$basePath/$id?show_schedule=true');
    return parseItem(raw as Object);
  }

  /// `POST /api/v1/invoices/{id}/payment_schedule?show_schedule=true` —
  /// number-of-payments flow (server expands frequency + cycles into
  /// installments). Body mirrors React: `{template, next_run,
  /// remaining_cycles, frequency_id, parameters:{invoice_id, auto_bill,
  /// schedule:[]}}`. Returns the refreshed invoice (schedule embedded).
  Future<InvoiceApi> createPaymentSchedule({
    required String id,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '$basePath/$id/payment_schedule?show_schedule=true',
      idempotencyKey: idempotencyKey,
      body: body,
    );
    return parseItem(raw as Object).data;
  }

  /// `POST /api/v1/task_schedulers` — custom-rows flow (caller supplies the
  /// explicit `parameters.schedule[]` rows). The Schedule resource itself
  /// is returned/ignored; the caller re-fetches the invoice afterwards.
  Future<void> createCustomPaymentSchedule({
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'POST',
      path: '/api/v1/task_schedulers',
      idempotencyKey: idempotencyKey,
      body: body,
    );
  }

  /// `DELETE /api/v1/invoices/{id}/payment_schedule` — clears the invoice's
  /// payment schedule (React's remove flow).
  Future<void> deletePaymentSchedule({
    required String id,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'DELETE',
      path: '$basePath/$id/payment_schedule',
      idempotencyKey: idempotencyKey,
    );
  }

  /// Upload a document attachment to an invoice. Returns the refreshed
  /// invoice envelope with the new document in its `documents` array.
  /// Mirrors `ClientsApi.uploadDocument` — same multipart field name.
  Future<InvoiceApi> uploadDocument({
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
