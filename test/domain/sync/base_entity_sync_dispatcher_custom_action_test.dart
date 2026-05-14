import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Contract test for the `customActions` extension point. When a mutation
/// kind is registered in the map, the dispatcher must:
///   1. invoke the handler with the outbox row + decoded payload
///   2. skip the standard CRUD switch
///   3. throw a `StateError` if the kind is enqueued but no handler is
///      registered (caught here as a regression guard)
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  test('customActions handler intercepts addComment dispatch', () async {
    final api = _NoopClientsApi();
    final repo = ClientRepository(db: db, api: api);

    final received = <Map<String, dynamic>>[];
    final dispatcher = BaseEntitySyncDispatcher<ClientItemApi, ClientApi>(
      api: api,
      repo: repo,
      dataOf: (item) => item.data,
      customActions: {
        MutationKind.addComment: ({required row, required payload}) async {
          received.add(payload);
          return null;
        },
      },
    );

    final row = OutboxRow(
      id: 1,
      companyId: 'co',
      entityType: 'client',
      entityId: 'c1',
      mutationKind: 'add_comment',
      payload: jsonEncode({'entity_id': 'c1', 'notes': 'hi'}),
      idempotencyKey: 'idk',
      state: 'pending',
      attempts: 0,
      nextAttemptAt: 0,
      createdAt: 0,
      requiresPassword: false,
    );

    await dispatcher.dispatch(row: row, kind: MutationKind.addComment);

    expect(received, hasLength(1));
    expect(received.single['entity_id'], 'c1');
    expect(received.single['notes'], 'hi');
  });

  test(
    'addComment without a registered handler throws — surfaces the '
    'misconfiguration loudly instead of silently dropping the mutation',
    () async {
      final api = _NoopClientsApi();
      final repo = ClientRepository(db: db, api: api);
      final dispatcher = BaseEntitySyncDispatcher<ClientItemApi, ClientApi>(
        api: api,
        repo: repo,
        dataOf: (item) => item.data,
      );

      final row = OutboxRow(
        id: 1,
        companyId: 'co',
        entityType: 'client',
        entityId: 'c1',
        mutationKind: 'add_comment',
        payload: jsonEncode({'entity_id': 'c1', 'notes': 'hi'}),
        idempotencyKey: 'idk',
        state: 'pending',
        attempts: 0,
        nextAttemptAt: 0,
        createdAt: 0,
        requiresPassword: false,
      );

      expect(
        () => dispatcher.dispatch(row: row, kind: MutationKind.addComment),
        throwsA(isA<StateError>()),
      );
    },
  );
}

class _NoopClientsApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '_NoopClientsApi.${invocation.memberName} not implemented',
  );
}
