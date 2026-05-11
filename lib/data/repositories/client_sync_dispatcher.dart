import 'dart:convert';

import '../../domain/sync/mutation.dart';
import '../../domain/sync/sync_dispatcher.dart';
import '../db/app_database.dart';
import '../services/clients_api.dart';
import 'client_repository.dart';

/// Wires `ClientsApi` (the network) to `ClientRepository` (the cache).
///
/// On success, calls the repo's `applyCreateResponse` / `applyUpdateResponse`
/// so the canonical server state lands in Drift. The sync engine handles
/// outbox row cleanup and error branches around this dispatcher.
class ClientSyncDispatcher implements SyncDispatcher {
  ClientSyncDispatcher({required this.api, required this.repo});

  final ClientsApi api;
  final ClientRepository repo;

  @override
  Future<void> dispatch({
    required OutboxRow row,
    required MutationKind kind,
  }) async {
    final payload = jsonDecode(row.payload) as Map<String, dynamic>;
    switch (kind) {
      case MutationKind.create:
        final response = await api.create(
          payload: payload,
          idempotencyKey: row.idempotencyKey,
        );
        await repo.applyCreateResponse(
          companyId: row.companyId,
          tempId: row.entityId,
          serverResponse: response.data,
        );
      case MutationKind.update:
        final response = await api.update(
          id: row.entityId,
          payload: payload,
          idempotencyKey: row.idempotencyKey,
        );
        await repo.applyUpdateResponse(
          companyId: row.companyId,
          serverResponse: response.data,
        );
      case MutationKind.delete:
        await api.delete(
          id: row.entityId,
          idempotencyKey: row.idempotencyKey,
          requiresPassword: row.requiresPassword,
        );
        // Mark the local row as deleted immediately so the list hides it
        // without waiting for the next pull-to-refresh.
        await repo.applyDeleteResponse(
          companyId: row.companyId,
          id: row.entityId,
        );
      case MutationKind.archive:
        final response = await api.action(
          id: row.entityId,
          action: 'archive',
          idempotencyKey: row.idempotencyKey,
        );
        if (response != null) {
          await repo.applyUpdateResponse(
            companyId: row.companyId,
            serverResponse: response.data,
          );
        }
      case MutationKind.restore:
        final response = await api.action(
          id: row.entityId,
          action: 'restore',
          idempotencyKey: row.idempotencyKey,
        );
        if (response != null) {
          await repo.applyUpdateResponse(
            companyId: row.companyId,
            serverResponse: response.data,
          );
        }
    }
  }
}

