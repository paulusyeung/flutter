import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:admin/data/models/api/credit_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/credits`. Mirrors `QuotesApi` minus the
/// `approve`/`convertToInvoice`/`convertToProject` quote-only actions.
/// Credits share the full email/clone/PDF/upload surface every billing
/// doc has.
class CreditsApi extends BaseEntityApi<CreditListApi, CreditItemApi> {
  CreditsApi(super.client);

  @override
  String get basePath => '/api/v1/credits';

  @override
  CreditListApi parseList(Object json) =>
      CreditListApi.fromJson(json as Map<String, dynamic>);

  @override
  CreditItemApi parseItem(Object json) =>
      CreditItemApi.fromJson(json as Map<String, dynamic>);

  Future<CreditItemApi?> markSent({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'mark_sent', idempotencyKey: idempotencyKey);

  Future<CreditItemApi?> email({
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

  Future<CreditItemApi?> scheduleEmail({
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

  Future<CreditItemApi?> cloneTo({
    required String id,
    required String targetType,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'clone_to_$targetType',
        idempotencyKey: idempotencyKey,
      );

  Future<CreditItemApi?> runTemplate({
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

  /// Server-rendered PDF via `POST /api/v1/live_preview?entity=credit
  /// [&entity_id=<id>]` with the full credit entity (`Credit.toApiJson()`) as
  /// the body — see `InvoicesApi.downloadPdf` for why `/api/v1/preview` is
  /// wrong here.
  Future<Uint8List> downloadPdf({
    required Map<String, dynamic> entityJson,
    String? designId,
  }) {
    final id = (entityJson['id'] as String?) ?? '';
    final saved = id.isNotEmpty && !id.startsWith('tmp_');
    final path = StringBuffer('/api/v1/live_preview?entity=credit')
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

  Future<CreditApi> uploadDocument({
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
