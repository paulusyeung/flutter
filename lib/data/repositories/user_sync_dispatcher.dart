import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/user_api_model.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/user_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/services/users_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';

/// Drains outbox rows whose `entity_type` is `kUserWireName` (`'user'`).
///
/// The payload's `_action` key (if any) selects the endpoint:
///   * absent → `PUT /api/v1/users/{id}` with the full user body.
///   * `disconnect_oauth` → `POST /api/v1/users/{id}/disconnect_oauth`.
///   * `disconnect_mailer` → `POST /api/v1/users/{id}/disconnect_mailer`.
///
/// On success, [UserRepository.applyApiResponse] persists the canonical user
/// envelope and [AuthRepository.applyUserUpdate] propagates the patched
/// name/email/phone to the topbar / company picker so the UI reflects the
/// change without waiting for the next `/refresh`.
class UserSyncDispatcher implements SyncDispatcher {
  UserSyncDispatcher({
    required this.api,
    required this.repo,
    required this.auth,
  });

  final UsersApi api;
  final UserRepository repo;
  final AuthRepository auth;

  @override
  Future<void> dispatch({
    required OutboxRow row,
    required MutationKind kind,
  }) async {
    // Only `update` is produced today; if a future feature adds disconnect
    // actions through a different kind, slot them into the switch below.
    assert(kind == MutationKind.update);

    final body = jsonDecode(row.payload) as Map<String, dynamic>;
    final action = body['_action'] as String?;

    final UserApi response;
    switch (action) {
      case 'disconnect_oauth':
        response = await api.disconnectOauth(
          id: row.entityId,
          idempotencyKey: row.idempotencyKey,
        );
      case 'disconnect_mailer':
        response = await api.disconnectMailer(
          id: row.entityId,
          idempotencyKey: row.idempotencyKey,
        );
      default:
        response = await api.update(
          id: row.entityId,
          body: body,
          idempotencyKey: row.idempotencyKey,
          requiresPassword: row.requiresPassword,
        );
    }

    await repo.applyApiResponse(companyId: row.companyId, api: response);
    auth.applyUserUpdate(response);
  }
}

/// Composite dispatcher under `EntityType.user`. Routes outbox rows by their
/// `entity_type` wire name to the right sub-dispatcher:
///   * `'user_settings'` → the per-(user, company) settings PUT to
///     `/company_users/{id}` (existing flow, [userSettings]).
///   * `'user'` → the full-user PUT / disconnect flows on `/users/{id}`
///     (new flow, [user]).
///
/// Needed because [EntityType] is the registry's per-entity key but the user
/// slot now hosts two distinct write paths. The `EntityHandlers.extraWireNames`
/// list pairs both wire names with this composite — see
/// `lib/domain/entity_registry.dart`.
class CompositeUserDispatcher implements SyncDispatcher {
  CompositeUserDispatcher({required this.userSettings, required this.user});

  final SyncDispatcher userSettings;
  final SyncDispatcher user;

  @override
  Future<void> dispatch({required OutboxRow row, required MutationKind kind}) {
    switch (row.entityType) {
      case kUserSettingsWireName:
        return userSettings.dispatch(row: row, kind: kind);
      case kUserWireName:
        return user.dispatch(row: row, kind: kind);
      default:
        throw StateError(
          'CompositeUserDispatcher: unknown wire name "${row.entityType}"',
        );
    }
  }
}
