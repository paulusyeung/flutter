import 'dart:typed_data';

import 'package:admin/data/services/upload_source.dart';

import 'package:admin/data/models/api/quote_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/quotes`. Mirrors `InvoicesApi` — same custom
/// actions where they apply (markSent / email / scheduleEmail / cloneTo /
/// cancel / runTemplate / uploadDocument), plus quote-specific
/// `approve` / `convertToInvoice` / `convertToProject`.
///
/// Quotes have **no** mark-paid / auto-bill (those are payment-side
/// actions only relevant to invoices). Cancel is supported on the server
/// for quotes but rarely used in practice.
class QuotesApi extends BaseEntityApi<QuoteListApi, QuoteItemApi> {
  QuotesApi(super.client);

  @override
  String get basePath => '/api/v1/quotes';

  @override
  QuoteListApi parseList(Object json) =>
      QuoteListApi.fromJson(json as Map<String, dynamic>);

  @override
  QuoteItemApi parseItem(Object json) =>
      QuoteItemApi.fromJson(json as Map<String, dynamic>);

  Future<QuoteItemApi?> markSent({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'mark_sent', idempotencyKey: idempotencyKey);

  Future<QuoteItemApi?> approve({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'approve', idempotencyKey: idempotencyKey);

  Future<QuoteItemApi?> convertToInvoice({
    required String id,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'convert_to_invoice',
        idempotencyKey: idempotencyKey,
      );

  Future<QuoteItemApi?> convertToProject({
    required String id,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'convert_to_project',
        idempotencyKey: idempotencyKey,
      );

  Future<QuoteItemApi?> email({
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

  Future<QuoteItemApi?> scheduleEmail({
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

  Future<QuoteItemApi?> cloneTo({
    required String id,
    required String targetType,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'clone_to_$targetType',
        idempotencyKey: idempotencyKey,
      );

  Future<QuoteItemApi?> cancel({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'cancel', idempotencyKey: idempotencyKey);

  Future<QuoteItemApi?> runTemplate({
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

  /// Server-rendered PDF via `POST /api/v1/live_preview?entity=quote
  /// [&entity_id=<id>]` with the full quote entity (`Quote.toApiJson()`) as
  /// the body — see `InvoicesApi.downloadPdf` for why `/api/v1/preview` is
  /// wrong here.
  Future<Uint8List> downloadPdf({
    required Map<String, dynamic> entityJson,
    String? designId,
  }) {
    final id = (entityJson['id'] as String?) ?? '';
    final saved = id.isNotEmpty && !id.startsWith('tmp_');
    final path = StringBuffer('/api/v1/live_preview?entity=quote')
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

  Future<QuoteApi> uploadDocument({
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
