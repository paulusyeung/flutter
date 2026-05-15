import 'package:http/http.dart' as http;

import 'package:admin/data/models/api/recurring_expense_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/recurring_expenses`. Mirrors `ExpensesApi`,
/// plus:
///   * `get` / `create` / `update` append `?show_dates=true` so the
///     server includes the previewed `recurring_dates` array (consumed by
///     the detail screen's Schedule card and the edit screen's
///     next-send-date preview).
///   * `start(id)` / `stop(id)` hit `PUT /recurring_expenses/{id}?start=true`
///     (or `&stop=true`) with an empty body, the standard idempotency
///     header, and no payload — the server transitions the row's
///     `status_id` to Active / Paused.
class RecurringExpensesApi
    extends BaseEntityApi<RecurringExpenseListApi, RecurringExpenseItemApi> {
  RecurringExpensesApi(super.client);

  @override
  String get basePath => '/api/v1/recurring_expenses';

  @override
  RecurringExpenseListApi parseList(Object json) =>
      RecurringExpenseListApi.fromJson(json as Map<String, dynamic>);

  @override
  RecurringExpenseItemApi parseItem(Object json) =>
      RecurringExpenseItemApi.fromJson(json as Map<String, dynamic>);

  /// Override the read URL to request `?show_dates=true`. The list endpoint
  /// does **not** need this — the previewed `recurring_dates` array would
  /// bloat every list response; only single-resource fetches care.
  @override
  Future<RecurringExpenseItemApi> get(String id) async {
    final raw = await client.getOneWithQuery(
      '$basePath/$id',
      query: const {'show_dates': 'true'},
    );
    return parseItem(raw as Object);
  }

  @override
  Future<RecurringExpenseItemApi> create({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    bool requiresPassword = false,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: basePath,
      query: const {'show_dates': 'true'},
      idempotencyKey: idempotencyKey,
      body: payload,
      requiresPassword: requiresPassword,
    );
    return parseItem(raw as Object);
  }

  @override
  Future<RecurringExpenseItemApi> update({
    required String id,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    bool requiresPassword = false,
    Map<String, String>? query,
  }) async {
    final mergedQuery = <String, String>{
      'show_dates': 'true',
      if (query != null) ...query,
    };
    final raw = await client.mutate(
      method: 'PUT',
      path: '$basePath/$id',
      query: mergedQuery,
      idempotencyKey: idempotencyKey,
      body: payload,
      requiresPassword: requiresPassword,
    );
    return parseItem(raw as Object);
  }

  /// `PUT /recurring_expenses/{id}?start=true` — transition Draft / Paused
  /// → Active. Empty body. Returns the refreshed envelope.
  Future<RecurringExpenseItemApi> start({
    required String id,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'PUT',
      path: '$basePath/$id',
      query: const {'start': 'true', 'show_dates': 'true'},
      idempotencyKey: idempotencyKey,
      body: const <String, dynamic>{},
    );
    return parseItem(raw as Object);
  }

  /// `PUT /recurring_expenses/{id}?stop=true` — Active / Pending → Paused.
  Future<RecurringExpenseItemApi> stop({
    required String id,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'PUT',
      path: '$basePath/$id',
      query: const {'stop': 'true', 'show_dates': 'true'},
      idempotencyKey: idempotencyKey,
      body: const <String, dynamic>{},
    );
    return parseItem(raw as Object);
  }

  /// Upload a document attachment. Same multipart shape as
  /// `ExpensesApi.uploadDocument` — the document handlers factory routes
  /// through this method via `MutationKind.documentUpload`.
  Future<RecurringExpenseItemApi> uploadDocument({
    required String recurringExpenseId,
    required String filePath,
    required String idempotencyKey,
  }) async {
    final file = await http.MultipartFile.fromPath('documents[]', filePath);
    final raw = await client.uploadMultipart(
      path: '$basePath/$recurringExpenseId/upload',
      fields: const {'_method': 'POST'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object);
  }
}
