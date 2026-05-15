import 'package:http/http.dart' as http;

import 'package:admin/data/models/api/company_api_model.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/companies`. Companies are a singleton-per-tenant
/// (no list/create/delete from this app) but we still extend [BaseEntityApi]
/// so the outbox dispatcher can use the same `update` method as everything
/// else.
///
/// `list` is unused in M1 — companies arrive via `/auth/me`. Multipart
/// uploads for logo + document attachments use [uploadLogo] / [uploadDocument]
/// because the outbox payload format doesn't naturally carry binary.
class CompaniesApi extends BaseEntityApi<CompanyItemApi, CompanyItemApi> {
  CompaniesApi(super.client);

  @override
  String get basePath => '/api/v1/companies';

  ApiClient get apiClient => client;

  @override
  CompanyItemApi parseList(Object json) =>
      CompanyItemApi.fromJson(json as Map<String, dynamic>);

  @override
  CompanyItemApi parseItem(Object json) =>
      CompanyItemApi.fromJson(json as Map<String, dynamic>);

  /// Upload a new company logo. Server replaces the existing one; the response
  /// is a refreshed company envelope whose `settings.company_logo` carries
  /// the new URL.
  Future<CompanyItemApi> uploadLogo({
    required String companyId,
    required String filePath,
    required String idempotencyKey,
  }) async {
    final file = await http.MultipartFile.fromPath('company_logo', filePath);
    final raw = await client.uploadMultipart(
      path: '$basePath/$companyId/upload',
      fields: const {'_method': 'POST'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object);
  }

  /// Upload a document attachment to the company. Server returns the
  /// refreshed company envelope (documents nested inside).
  Future<CompanyItemApi> uploadDocument({
    required String companyId,
    required String filePath,
    required String idempotencyKey,
  }) async {
    final file = await http.MultipartFile.fromPath('documents[]', filePath);
    final raw = await client.uploadMultipart(
      path: '$basePath/$companyId/upload',
      fields: const {'_method': 'POST'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object);
  }

  /// Permanently delete a company. Requires the user's password (the
  /// `requiresPassword: true` flag routes the cached password into
  /// `X-API-PASSWORD-BASE64`). Legacy admin-portal sends the
  /// `cancellation_message` in the body; React drops it on the floor.
  ///
  /// Named distinctly from `BaseEntityApi.delete` because the company
  /// destructive flow carries a `cancellation_message` body that the
  /// generic signature doesn't accept.
  /// Probe the server for subdomain availability. Returns `true` when the
  /// subdomain is free, `false` when it's already taken or otherwise rejected
  /// by validation. Network errors / 5xx propagate so the UI shows
  /// "couldn't check" rather than a false positive.
  ///
  /// The Client Portal Settings tab calls this on a debounce as the user
  /// types — see `_SubdomainField`. Save is **not** gated on the result;
  /// the server is authoritative and rejects on PUT if needed.
  Future<bool> checkSubdomainAvailable(String subdomain) async {
    try {
      await client.postJson(
        '/api/v1/check_subdomain',
        body: {'subdomain': subdomain},
        readOnly: true,
      );
      return true;
    } on ValidationException {
      return false;
    } on ServerException catch (e) {
      if (e.statusCode >= 400 && e.statusCode < 500) return false;
      rethrow;
    }
  }

  Future<void> deleteWithBody({
    required String id,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'DELETE',
      path: '$basePath/$id',
      idempotencyKey: idempotencyKey,
      body: body,
      requiresPassword: true,
    );
  }
}
