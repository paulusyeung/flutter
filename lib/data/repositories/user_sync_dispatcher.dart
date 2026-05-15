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
/// Routes by [MutationKind]:
///   * [MutationKind.create] → `POST /api/v1/users`
///   * [MutationKind.update] → `PUT /api/v1/users/{id}` (with body `_action`
///     escape hatch for `disconnect_oauth` / `disconnect_mailer`)
///   * [MutationKind.delete] → `DELETE /api/v1/users/{id}` (soft)
///   * [MutationKind.archive] / [MutationKind.restore] → `POST .../<action>`
///   * [MutationKind.purge] → `POST /api/v1/users/{id}/purge` (hard)
///   * [MutationKind.inviteUser] → `POST /api/v1/users/{id}/invite`
///   * [MutationKind.detachFromCompany] →
///     `DELETE /api/v1/users/{id}/detach_from_company`
///
/// On success, [UserRepository.applyApiResponse] persists the canonical
/// envelope and [AuthRepository.applyUserUpdate] propagates name/email/phone
/// to the topbar / company picker for the auth user (no-op for any other
/// user — the picker only renders the auth user's profile).
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
    final body = row.payload.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(row.payload) as Map<String, dynamic>;

    switch (kind) {
      case MutationKind.update:
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
            response = await api.updateAuthUser(
              id: row.entityId,
              body: body,
              idempotencyKey: row.idempotencyKey,
              requiresPassword: row.requiresPassword,
            );
        }
        await repo.applyApiResponse(companyId: row.companyId, api: response);
        auth.applyUserUpdate(response);

      case MutationKind.create:
        final item = await api.create(
          payload: body,
          idempotencyKey: row.idempotencyKey,
          requiresPassword: row.requiresPassword,
        );
        await repo.applyCreateResponse(
          companyId: row.companyId,
          tempId: row.entityId,
          serverResponse: item.data,
        );

      case MutationKind.delete:
        await api.delete(
          id: row.entityId,
          idempotencyKey: row.idempotencyKey,
          requiresPassword: row.requiresPassword,
        );
        await repo.applyDeleteResponse(
          companyId: row.companyId,
          id: row.entityId,
        );

      case MutationKind.archive:
        final item = await api.action(
          id: row.entityId,
          action: 'archive',
          idempotencyKey: row.idempotencyKey,
        );
        if (item != null) {
          await repo.applyUpdateResponse(
            companyId: row.companyId,
            serverResponse: item.data,
          );
        }

      case MutationKind.restore:
        final item = await api.action(
          id: row.entityId,
          action: 'restore',
          idempotencyKey: row.idempotencyKey,
        );
        if (item != null) {
          await repo.applyUpdateResponse(
            companyId: row.companyId,
            serverResponse: item.data,
          );
        }

      case MutationKind.purge:
        await api.action(
          id: row.entityId,
          action: 'purge',
          idempotencyKey: row.idempotencyKey,
          requiresPassword: row.requiresPassword,
        );
        await repo.applyPurgeResponse(
          companyId: row.companyId,
          id: row.entityId,
        );

      case MutationKind.inviteUser:
        await api.resendEmail(
          id: row.entityId,
          idempotencyKey: row.idempotencyKey,
        );

      case MutationKind.detachFromCompany:
        await api.detachFromCompany(
          id: row.entityId,
          idempotencyKey: row.idempotencyKey,
          requiresPassword: row.requiresPassword,
        );
        await repo.applyDetachResponse(
          companyId: row.companyId,
          id: row.entityId,
        );

      // Kinds that don't apply to users — reaching here is a wiring bug.
      // ignore: no_default_cases
      default:
        throw StateError(
          'UserSyncDispatcher received unsupported kind ${kind.wireName}',
        );
    }
  }
}

/// Composite dispatcher under `EntityType.user`. Routes outbox rows by their
/// `entity_type` wire name to the right sub-dispatcher:
///   * `'user_settings'` → the per-(user, company) settings PUT to
///     `/company_users/{id}` (existing flow, [userSettings]).
///   * `'user'` → the full-user PUT / disconnect / management flows on
///     `/users/{id}` (existing + new flow, [user]).
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
