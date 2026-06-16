import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';

/// L8: archive/restore call `bulkActionOne`, which returns null when the
/// server's re-query finds zero rows for the id (e.g. it was purged
/// elsewhere). The optimistic flip left the local row `is_dirty=true`; without
/// reconciliation it stays dirty forever and every `/refresh` skips it (a
/// lingering "unsynced" badge). The dispatcher must clear the dirty flag.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  OutboxRow rowWith({required String kind, required String entityId}) =>
      OutboxRow(
        id: 1,
        companyId: 'co',
        entityType: 'client',
        entityId: entityId,
        mutationKind: kind,
        payload: jsonEncode({'id': entityId}),
        idempotencyKey: 'idk',
        state: 'pending',
        attempts: 0,
        nextAttemptAt: 0,
        createdAt: 0,
        requiresPassword: false,
      );

  for (final action in const ['archive', 'restore']) {
    test('$action: a null (no-entity) bulk response clears the optimistic '
        'dirty flag so the row is not refresh-skipped forever (L8)', () async {
      final api = _NullBulkClientsApi();
      final repo = ClientRepository(db: db, api: api);
      final dispatcher = BaseEntitySyncDispatcher<ClientItemApi, ClientApi>(
        api: api,
        repo: repo,
        dataOf: (item) => item.data,
      );

      // Seed a clean row, then flip the optimistic archive state
      // (archived_at + is_dirty=true) the way repo.archive()/restore() does.
      await repo.applyUpdateResponse(
        companyId: 'co',
        serverResponse: const ClientApi(id: 'c1', name: 'Acme'),
      );
      await db.clientDao.setArchived(
        companyId: 'co',
        id: 'c1',
        atEpochSeconds: 1700000000,
      );
      final before = await repo.watchByRealId(companyId: 'co', id: 'c1').first;
      expect(before!.isDirty, isTrue);

      await dispatcher.dispatch(
        row: rowWith(kind: action, entityId: 'c1'),
        kind: MutationKind.values.firstWhere((k) => k.wireName == action),
      );

      final after = await repo.watchByRealId(companyId: 'co', id: 'c1').first;
      expect(
        after!.isDirty,
        isFalse,
        reason: 'dirty flag must be cleared on a null bulk response',
      );
    });
  }
}

/// Fake whose `bulkActionOne` always returns null (the empty-data case).
class _NullBulkClientsApi implements ClientsApi {
  @override
  Future<ClientItemApi?> bulkActionOne({
    required String id,
    required String action,
    required String idempotencyKey,
    Map<String, dynamic>? extra,
    Map<String, String>? query,
    bool requiresPassword = false,
  }) async => null;

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '_NullBulkClientsApi.${invocation.memberName} not implemented',
  );
}
