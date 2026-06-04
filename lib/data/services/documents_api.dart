import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/services/api_client.dart';

/// Server-side document operations that are addressed by document id, not
/// by parent entity. The per-entity upload (`POST /<entity>/{id}/upload`)
/// lives on the entity api because the URL is entity-scoped — see
/// `ClientsApi.uploadDocument` and `ProductsApi.uploadDocument`.
///
/// All methods go through `ApiClient.mutate` so they share the standard
/// idempotency-key header, password gating, and `x-minimum-client-version`
/// negotiation with the rest of the app.
class DocumentsApi {
  DocumentsApi(this._client);

  final ApiClient _client;

  String get _basePath => '/api/v1/documents';

  /// `DELETE /api/v1/documents/{id}`. Server gates on
  /// `X-API-PASSWORD-BASE64` — caller passes `requiresPassword: true`,
  /// which is also wired through `requiresPasswordFor` on the parent
  /// entity's repo so the sync engine fires `ConfirmPasswordSheet`.
  Future<void> delete({
    required String id,
    required String idempotencyKey,
    required bool requiresPassword,
  }) async {
    await _client.mutate(
      method: 'DELETE',
      path: '$_basePath/$id',
      idempotencyKey: idempotencyKey,
      requiresPassword: requiresPassword,
    );
  }

  /// `PUT /api/v1/documents/{id}` with `{is_public: bool}`. Server returns
  /// the updated document; callers patch the parent entity's `documents`
  /// array locally instead of refetching the whole entity.
  Future<DocumentApi?> setVisibility({
    required String id,
    required bool isPublic,
    required String idempotencyKey,
  }) async {
    final raw = await _client.mutate(
      method: 'PUT',
      path: '$_basePath/$id',
      idempotencyKey: idempotencyKey,
      body: {'is_public': isPublic},
    );
    if (raw == null) return null;
    // The server wraps the response in a `{data: {...}}` envelope — same
    // shape every other PUT uses.
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return DocumentApi.fromJson(data);
      }
    }
    return null;
  }

  /// `POST /api/v1/documents/bulk {action:'download', ids}` — server-side
  /// export: the server zips the documents and emails them to the user, so
  /// there's nothing to download client-side (parity with admin-portal +
  /// React; the caller toasts `exported_data`). The response is a document
  /// list we don't need, so this returns void.
  Future<void> bulkDownload({
    required List<String> ids,
    required String idempotencyKey,
  }) async {
    await _client.mutate(
      method: 'POST',
      path: '$_basePath/bulk',
      idempotencyKey: idempotencyKey,
      body: {'action': 'download', 'ids': ids},
    );
  }
}
