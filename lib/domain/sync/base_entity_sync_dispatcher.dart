import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/base_entity_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';

/// Generic CRUD-list dispatcher. Drives every entity whose API extends
/// `BaseEntityApi<TList, TItem>` and whose repository extends
/// `BaseEntityRepository<TDomain, TInner>`. `TItem` is the envelope returned
/// by the server (`{ data: <entity> }`); `TInner` is the inner DTO the repo
/// upserts. The DI block passes `dataOf` as a one-liner tear-off, e.g.
/// `dataOf: (item) => item.data`.
///
/// Non-standard flows (multipart uploads, settings-only PUT) keep their own
/// dispatcher — see `CompanySyncDispatcher` and `UserSettingsSyncDispatcher`.
class BaseEntitySyncDispatcher<TItem, TInner> implements SyncDispatcher {
  BaseEntitySyncDispatcher({
    required this.api,
    required this.repo,
    required this.dataOf,
  });

  final BaseEntityApi<dynamic, TItem> api;
  final BaseEntityRepository<dynamic, TInner> repo;
  final TInner Function(TItem item) dataOf;

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
          serverResponse: dataOf(response),
        );
      case MutationKind.update:
        final response = await api.update(
          id: row.entityId,
          payload: payload,
          idempotencyKey: row.idempotencyKey,
        );
        await repo.applyUpdateResponse(
          companyId: row.companyId,
          serverResponse: dataOf(response),
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
        final response = await api.action(
          id: row.entityId,
          action: 'archive',
          idempotencyKey: row.idempotencyKey,
        );
        if (response != null) {
          await repo.applyUpdateResponse(
            companyId: row.companyId,
            serverResponse: dataOf(response),
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
            serverResponse: dataOf(response),
          );
        }
    }
  }
}
