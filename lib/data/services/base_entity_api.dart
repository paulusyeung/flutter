import 'api_client.dart';

/// Generic API contract every entity-specific `*Api` implements (by extension
/// or by composition with [ApiClient]). The shape is uniform so the sync
/// engine, outbox dispatcher, and registry don't need entity-specific code
/// paths.
///
/// Concrete classes (`ClientApi`, `InvoiceApi`, etc.) supply the path and the
/// parsers that lift raw `Map<String, dynamic>` into typed list/item envelopes.
abstract class BaseEntityApi<TList, TItem> {
  BaseEntityApi(this.client);
  final ApiClient client;

  /// The collection path, e.g. `/api/v1/clients`.
  String get basePath;

  TList parseList(Object json);
  TItem parseItem(Object json);

  Future<({TList data, int? cursorUpdatedAt, String? cursorId})> list({
    required int page,
    int perPage = 50,
    String? search,
    int? sinceUpdatedAt,
    String? sinceId,
    Map<String, String> filters = const {},
  }) async {
    final result = await client.getList(
      basePath,
      page: page,
      perPage: perPage,
      search: search,
      sinceUpdatedAt: sinceUpdatedAt,
      sinceId: sinceId,
      filters: filters,
    );
    return (
      data: parseList(result.data as Object),
      cursorUpdatedAt: result.cursorUpdatedAt,
      cursorId: result.cursorId,
    );
  }

  Future<TItem> get(String id) async {
    final raw = await client.getOne('$basePath/$id');
    return parseItem(raw as Object);
  }

  Future<TItem> create({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    bool requiresPassword = false,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: basePath,
      idempotencyKey: idempotencyKey,
      body: payload,
      requiresPassword: requiresPassword,
    );
    return parseItem(raw as Object);
  }

  Future<TItem> update({
    required String id,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    bool requiresPassword = false,
  }) async {
    final raw = await client.mutate(
      method: 'PUT',
      path: '$basePath/$id',
      idempotencyKey: idempotencyKey,
      body: payload,
      requiresPassword: requiresPassword,
    );
    return parseItem(raw as Object);
  }

  Future<void> delete({
    required String id,
    required String idempotencyKey,
    bool requiresPassword = true,
  }) async {
    await client.mutate(
      method: 'DELETE',
      path: '$basePath/$id',
      idempotencyKey: idempotencyKey,
      requiresPassword: requiresPassword,
    );
  }

  /// Open-ended entity actions: `/api/v1/clients/<id>/email`,
  /// `/api/v1/invoices/<id>/mark_paid`, `/api/v1/invoices/bulk`, etc.
  ///
  /// `mutation_kind = 'action:<name>'` in the outbox, so adding new server
  /// actions never requires a schema migration.
  Future<TItem?> action({
    required String id,
    required String action,
    required String idempotencyKey,
    Map<String, dynamic>? payload,
    bool requiresPassword = false,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '$basePath/$id/$action',
      idempotencyKey: idempotencyKey,
      body: payload,
      requiresPassword: requiresPassword,
    );
    return raw == null ? null : parseItem(raw as Object);
  }
}
