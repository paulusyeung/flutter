import 'dart:convert';

import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/user_settings_api.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';

/// Drains `user_settings` outbox rows by PUTting them to
/// `/api/v1/company_users/{userId}` and writing the canonical response back
/// into the local cache.
class UserSettingsSyncDispatcher implements SyncDispatcher {
  UserSettingsSyncDispatcher({required this.api, required this.repo});

  final UserSettingsApi api;
  final UserSettingsRepository repo;

  @override
  Future<void> dispatch({
    required OutboxRow row,
    required MutationKind kind,
  }) async {
    // User settings only support `update`; the registry never produces other
    // kinds here. Ignore [kind] but assert in debug.
    assert(kind == MutationKind.update);
    final body = jsonDecode(row.payload) as Map<String, dynamic>;
    final response = await api.update(
      userId: row.entityId,
      body: body,
      idempotencyKey: row.idempotencyKey,
    );
    if (response != null) {
      await repo.applyServerResponse(
        companyId: row.companyId,
        response: response,
      );
    }
  }
}
