import 'package:admin/data/services/upload_source.dart';

import 'package:admin/data/models/api/recurring_expense_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/recurring_expenses`. Mirrors `ExpensesApi`,
/// plus:
///   * `get` / `create` / `update` append `?show_dates=true` so the
///     server includes the previewed `recurring_dates` array (consumed by
///     the detail screen's Schedule card and the edit screen's
///     next-send-date preview).
///   * `start(id)` / `stop(id)` hit `PUT /recurring_expenses/{id}?start=true`
///     (or `&stop=true`) with the full entity body (parity with admin-portal +
///     React) — the query flag transitions the row's `status_id` to
///     Active / Paused server-side.
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
    Map<String, String>? query,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: basePath,
      query: {if (query != null) ...query, 'show_dates': 'true'},
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
  /// → Active. Sends the full entity body (`payload`) like admin-portal +
  /// React; the `?start=true` flag drives the status flip server-side.
  /// Returns the refreshed envelope.
  Future<RecurringExpenseItemApi> start({
    required String id,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'PUT',
      path: '$basePath/$id',
      query: const {'start': 'true', 'show_dates': 'true'},
      idempotencyKey: idempotencyKey,
      body: payload,
    );
    return parseItem(raw as Object);
  }

  /// `PUT /recurring_expenses/{id}?stop=true` — Active / Pending → Paused.
  /// Sends the full entity body (`payload`), matching the references.
  Future<RecurringExpenseItemApi> stop({
    required String id,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'PUT',
      path: '$basePath/$id',
      query: const {'stop': 'true', 'show_dates': 'true'},
      idempotencyKey: idempotencyKey,
      body: payload,
    );
    return parseItem(raw as Object);
  }

  /// Upload a document attachment. Same multipart shape as
  /// `ExpensesApi.uploadDocument` — the document handlers factory routes
  /// through this method via `MutationKind.documentUpload`.
  Future<RecurringExpenseApi> uploadDocument({
    required String entityId,
    required UploadSource source,
    required String idempotencyKey,
  }) async {
    final file = await source.toMultipartFile('documents[]');
    final raw = await client.uploadMultipart(
      path: '$basePath/$entityId/upload',
      fields: const {'_method': 'PUT'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object).data;
  }
}
