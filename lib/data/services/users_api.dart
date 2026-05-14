import 'package:admin/data/models/api/user_api_model.dart';
import 'package:admin/data/services/api_client.dart';

/// Talks to `/api/v1/users/{id}` — the full user record (user-level fields +
/// embedded `company_user` for the active company). Pairs with
/// `UserRepository` and `UserSyncDispatcher`.
///
/// Distinct from [UserSettingsApi] which hits `/api/v1/company_users/{id}` for
/// the table-columns-only flow. The two endpoints overlap in shape (the
/// company_user nested settings) but represent different write semantics:
/// `users` is for the user record as a whole; `company_users` is for
/// per-(user, company) overrides. Keeping the two API clients separate
/// matches admin-portal's `web_client.dart` and avoids one-flow-clobbers-the-other
/// races when the table-column picker and the User Details Save button both
/// fire in quick succession.
class UsersApi {
  UsersApi(this._client);

  final ApiClient _client;

  /// GET the user record (with embedded `company_user` for the active
  /// company). Mirrors the PUT envelope — same `?include=company_user` so
  /// the response carries the per-user settings blob.
  Future<UserApi> get({required String id}) async {
    final raw = await _client.getOneWithQuery(
      '/api/v1/users/$id',
      query: const {'include': 'company_user'},
    );
    return _parseEnvelope(raw, '/users/$id (GET)');
  }

  /// PUT the patched user. The dispatcher routes the request through
  /// [ApiClient.mutate] so retries are idempotent and password-required
  /// branches surface the right exception.
  ///
  /// `body` is a serialised [UserApi]; the caller is responsible for merging
  /// `rawCompanyUserSettings` into the `company_user.settings` map so unknown
  /// server-only keys round-trip.
  Future<UserApi> update({
    required String id,
    required Map<String, dynamic> body,
    required String idempotencyKey,
    bool requiresPassword = false,
  }) async {
    final raw = await _client.mutate(
      method: 'PUT',
      path: '/api/v1/users/$id',
      query: const {'include': 'company_user'},
      idempotencyKey: idempotencyKey,
      body: body,
      requiresPassword: requiresPassword,
    );
    return _parseEnvelope(raw, '/users/$id (PUT)');
  }

  /// Disconnect the user's OAuth provider (Google / Microsoft). Server clears
  /// `oauth_provider_id` + the refresh-token columns and returns the updated
  /// user record. Idempotent — a no-op if nothing was connected.
  Future<UserApi> disconnectOauth({
    required String id,
    required String idempotencyKey,
  }) async {
    final raw = await _client.mutate(
      method: 'POST',
      path: '/api/v1/users/$id/disconnect_oauth',
      idempotencyKey: idempotencyKey,
    );
    return _parseEnvelope(raw, '/users/$id/disconnect_oauth');
  }

  /// Disconnect the per-user send-and-receive mailer binding (Gmail or
  /// Microsoft mail). Server clears the mailer columns; same envelope shape
  /// as [disconnectOauth].
  Future<UserApi> disconnectMailer({
    required String id,
    required String idempotencyKey,
  }) async {
    final raw = await _client.mutate(
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
