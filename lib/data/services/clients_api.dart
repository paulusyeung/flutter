import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/clients`. The base class handles list/get/create/
/// update/delete/action; this subclass only supplies the path and the
/// parsers that lift `Map<String, dynamic>` into typed envelopes.
///
/// Named `ClientsApi` (plural) to avoid collision with `ClientApi` (the
/// single-resource model class in `data/models/api/client_api_model.dart`).
class ClientsApi extends BaseEntityApi<ClientListApi, ClientItemApi> {
  ClientsApi(super.client);

  @override
  String get basePath => '/api/v1/clients';

  @override
  ClientListApi parseList(Object json) =>
      ClientListApi.fromJson(json as Map<String, dynamic>);

  @override
  ClientItemApi parseItem(Object json) =>
      ClientItemApi.fromJson(json as Map<String, dynamic>);

  /// Fetch the client statement PDF. Returns raw bytes; the caller hands them
  /// to `PdfPreview`. The endpoint is `POST /api/v1/client_statement` but is a
  /// server-side read (no mutation) — flagged [readOnly] so demo builds work
  /// and no outbox row is created.
  Future<Uint8List> getStatement({
    required String clientId,
    required Date startDate,
    required Date endDate,
    required String status,
    required bool showPayments,
    required bool showCredits,
    required bool showAging,
  }) {
    return client.postRaw(
      '/api/v1/client_statement',
      readOnly: true,
      body: {
        'client_id': clientId,
        'start_date': startDate.toIso(),
        'end_date': endDate.toIso(),
        'show_payments_table': showPayments,
        'show_credits_table': showCredits,
        'show_aging_table': showAging,
        'status': status,
      },
    );
  }

  /// Upload a document attachment to a client. Returns the refreshed client
  /// envelope with the new document in its `documents` array. Mirrors the
  /// `CompaniesApi.uploadDocument` shape — same multipart field name.
  Future<ClientApi> uploadDocument({
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

  /// Merge two clients: absorb [mergeFromId] into [mergeIntoId] (the
  /// survivor). `POST /api/v1/clients/{into}/{from}/merge`, no body.
  /// Password-gated server-side (412) — `client.mutate` injects
  /// `X-API-PASSWORD-BASE64` from the cache (or raises
  /// `PasswordRequiredException`, which the sync gate turns into the
  /// ConfirmPasswordSheet). Returns the surviving client envelope.
  Future<ClientApi> merge({
    required String mergeIntoId,
    required String mergeFromId,
    required String idempotencyKey,
    bool requiresPassword = true,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '$basePath/$mergeIntoId/$mergeFromId/merge',
      idempotencyKey: idempotencyKey,
      requiresPassword: requiresPassword,
    );
    return parseItem(raw as Object).data;
  }
}
