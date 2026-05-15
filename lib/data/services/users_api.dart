import 'package:admin/data/models/api/user_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Talks to `/api/v1/users` — list / get / create / update / delete / bulk
/// for the Settings → User Management screen, plus the auth-user PUT and the
/// two OAuth disconnect actions.
///
/// All list/get/create/update/delete calls send `?include=company_user` so
/// the per-(user, company) permissions + notifications round-trip on every
/// response. The list call also sends `hideOwnerUsers=true&without=<authId>`
/// to mirror React's filter (excludes the owner and the auth user from
/// the management list).
///
/// Distinct from [UserSettingsApi] which hits `/api/v1/company_users/{id}`
/// for the table-columns-only flow.
class UsersApi extends BaseEntityApi<UserListApi, UserItemApi> {
  UsersApi(super.client);

  @override
  String get basePath => '/api/v1/users';

  @override
  UserListApi parseList(Object json) =>
      UserListApi.fromJson(json as Map<String, dynamic>);

  @override
  UserItemApi parseItem(Object json) =>
      UserItemApi.fromJson(json as Map<String, dynamic>);

  /// GET the user record (with embedded `company_user`). Password-gated —
  /// the server enforces `X-API-PASSWORD-BASE64` and returns 412 otherwise.
  /// The Settings → User Details screen reads the auth user via `/refresh`
  /// instead; this method is for the admin "edit another user" flow.
  Future<UserApi> getOne({required String id}) async {
    final raw = await client.getOneWithQuery(
      '/api/v1/users/$id',
      query: const {'include': 'company_user'},
    );
    return _parseEnvelope(raw, '/users/$id (GET)');
  }

  /// PUT the patched user. Same envelope shape as the create POST — the
  /// server echoes the patched record back inside `data` with the
  /// `company_user` block included.
  Future<UserApi> updateAuthUser({
    required String id,
    required Map<String, dynamic> body,
    required String idempotencyKey,
    bool requiresPassword = false,
  }) async {
    final raw = await client.mutate(
      method: 'PUT',
      path: '/api/v1/users/$id',
      query: const {'include': 'company_user'},
      idempotencyKey: idempotencyKey,
      body: body,
      requiresPassword: requiresPassword,
    );
    return _parseEnvelope(raw, '/users/$id (PUT)');
  }

  /// `POST /api/v1/users/{id}/invite` — resend the invitation email to a
  /// pending user. Returns no body on success.
  Future<void> resendEmail({
    required String id,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'POST',
      path: '$basePath/$id/invite',
      idempotencyKey: idempotencyKey,
    );
  }

  /// `DELETE /api/v1/users/{id}/detach_from_company` — remove the user
  /// from this company without deleting their record. Password-gated.
  Future<void> detachFromCompany({
    required String id,
    required String idempotencyKey,
    bool requiresPassword = true,
  }) async {
    await client.mutate(
      method: 'DELETE',
      path: '$basePath/$id/detach_from_company',
      idempotencyKey: idempotencyKey,
      requiresPassword: requiresPassword,
    );
  }

  /// Disconnect the user's OAuth provider (Google / Microsoft). Server
  /// clears `oauth_provider_id` + the refresh-token columns and returns
  /// the updated user record. Idempotent — a no-op if nothing was connected.
  Future<UserApi> disconnectOauth({
    required String id,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '/api/v1/users/$id/disconnect_oauth',
      idempotencyKey: idempotencyKey,
    );
    return _parseEnvelope(raw, '/users/$id/disconnect_oauth');
  }

  /// Disconnect the per-user send-and-receive mailer binding (Gmail or
  /// Microsoft mail). Same envelope shape as [disconnectOauth].
  Future<UserApi> disconnectMailer({
    required String id,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '/api/v1/users/$id/disconnect_mailer',
      idempotencyKey: idempotencyKey,
    );
    return _parseEnvelope(raw, '/users/$id/disconnect_mailer');
  }

  UserApi _parseEnvelope(Object? raw, String forLog) {
    if (raw is! Map<String, dynamic>) {
      throw StateError('Unexpected $forLog response shape: ${raw.runtimeType}');
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Missing data envelope in $forLog response');
    }
    return UserApi.fromJson(data);
  }
}
