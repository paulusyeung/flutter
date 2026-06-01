import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Contract test for the SAVE-PARAM seam. An edit-screen action that the
/// server performs *as part of* the save (mark_sent / paid / …) rides in
/// the outbox payload under [kSaveQueryPayloadKey]. On drain the dispatcher
/// must:
///   1. promote that map to the HTTP request's query string, and
///   2. strip the reserved key out of the JSON body the server receives.
/// Verified on both `create` (POST) and `update` (PUT).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  OutboxRow rowWith({
    required String kind,
    required String entityId,
    required Map<String, dynamic> payload,
  }) => OutboxRow(
    id: 1,
    companyId: 'co',
    entityType: 'client',
    entityId: entityId,
    mutationKind: kind,
    payload: jsonEncode(payload),
    idempotencyKey: 'idk',
    state: 'pending',
    attempts: 0,
    nextAttemptAt: 0,
    createdAt: 0,
    requiresPassword: false,
  );

  test(
    'create promotes __save_query to query and strips it from body',
    () async {
      final api = _RecordingClientsApi();
      final repo = ClientRepository(db: db, api: api);
      final dispatcher = BaseEntitySyncDispatcher<ClientItemApi, ClientApi>(
        api: api,
        repo: repo,
        dataOf: (item) => item.data,
      );

      final row = rowWith(
        kind: 'create',
        entityId: 'tmp_1',
        payload: {
          'name': 'Acme',
          kSaveQueryPayloadKey: {'mark_sent': 'true'},
        },
      );

      await dispatcher.dispatch(row: row, kind: MutationKind.create);

      expect(api.createQuery, {'mark_sent': 'true'});
      expect(api.createBody, containsPair('name', 'Acme'));
      expect(api.createBody!.containsKey(kSaveQueryPayloadKey), isFalse);
    },
  );

  test(
    'update promotes __save_query to query and strips it from body',
    () async {
      final api = _RecordingClientsApi();
      final repo = ClientRepository(db: db, api: api);
      final dispatcher = BaseEntitySyncDispatcher<ClientItemApi, ClientApi>(
        api: api,
        repo: repo,
        dataOf: (item) => item.data,
      );

      final row = rowWith(
        kind: 'update',
        entityId: 'c1',
        payload: {
          'name': 'Acme',
          kSaveQueryPayloadKey: {'paid': 'true'},
        },
      );

      await dispatcher.dispatch(row: row, kind: MutationKind.update);

      expect(api.updateQuery, {'paid': 'true'});
      expect(api.updateBody, containsPair('name', 'Acme'));
      expect(api.updateBody!.containsKey(kSaveQueryPayloadKey), isFalse);
    },
  );

  test('no __save_query => null query, body untouched', () async {
    final api = _RecordingClientsApi();
    final repo = ClientRepository(db: db, api: api);
    final dispatcher = BaseEntitySyncDispatcher<ClientItemApi, ClientApi>(
      api: api,
      repo: repo,
      dataOf: (item) => item.data,
    );

    await dispatcher.dispatch(
      row: rowWith(kind: 'create', entityId: 'tmp_2', payload: {'name': 'No'}),
      kind: MutationKind.create,
    );

    expect(api.createQuery, isNull);
    expect(api.createBody, containsPair('name', 'No'));
  });
}

class _RecordingClientsApi implements ClientsApi {
  Map<String, String>? createQuery;
  Map<String, dynamic>? createBody;
  Map<String, String>? updateQuery;
  Map<String, dynamic>? updateBody;

  @override
  Future<ClientItemApi> create({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    bool requiresPassword = false,
    Map<String, String>? query,
  }) async {
    createQuery = query;
    createBody = payload;
    return const ClientItemApi(
      data: ClientApi(id: 'c1', name: 'Acme'),
    );
  }

  @override
  Future<ClientItemApi> update({
    required String id,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    Map<String, String>? query,
    bool requiresPassword = false,
  }) async {
    updateQuery = query;
    updateBody = payload;
    return const ClientItemApi(
      data: ClientApi(id: 'c1', name: 'Acme'),
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '_RecordingClientsApi.${invocation.memberName} not implemented',
  );
}
