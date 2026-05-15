import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:admin/data/models/api/purchase_order_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/purchase_orders`. Mirrors `QuotesApi` /
/// `CreditsApi` shape, vendor-centric. Adds two PO-specific actions:
/// `accept` (server-side mark-accepted) and `expense` (convert PO →
/// receipt → expense).
class PurchaseOrdersApi
    extends BaseEntityApi<PurchaseOrderListApi, PurchaseOrderItemApi> {
  PurchaseOrdersApi(super.client);

  @override
  String get basePath => '/api/v1/purchase_orders';

  @override
  PurchaseOrderListApi parseList(Object json) =>
      PurchaseOrderListApi.fromJson(json as Map<String, dynamic>);

  @override
  PurchaseOrderItemApi parseItem(Object json) =>
      PurchaseOrderItemApi.fromJson(json as Map<String, dynamic>);

  Future<PurchaseOrderItemApi?> markSent({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'mark_sent', idempotencyKey: idempotencyKey);

  Future<PurchaseOrderItemApi?> accept({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'accept', idempotencyKey: idempotencyKey);

  Future<PurchaseOrderItemApi?> cancel({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'cancel', idempotencyKey: idempotencyKey);

  Future<PurchaseOrderItemApi?> expense({
    required String id,
    required String idempotencyKey,
  }) =>
      action(id: id, action: 'expense', idempotencyKey: idempotencyKey);

  Future<PurchaseOrderItemApi?> email({
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

  Future<PurchaseOrderItemApi?> scheduleEmail({
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

  Future<PurchaseOrderItemApi?> cloneTo({
    required String id,
    required String targetType,
    required String idempotencyKey,
  }) =>
      action(
        id: id,
        action: 'clone_to_$targetType',
        idempotencyKey: idempotencyKey,
      );

  Future<PurchaseOrderItemApi?> runTemplate({
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

  Future<Uint8List> downloadPdf({
    required String id,
    String? designId,
  }) {
    return client.postRaw(
      '/api/v1/preview',
      readOnly: true,
      body: {
        'entity': 'purchase_order',
        'entity_id': id,
        if (designId != null && designId.isNotEmpty) 'design_id': designId,
      },
    );
  }

  Future<PurchaseOrderApi> uploadDocument({
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
