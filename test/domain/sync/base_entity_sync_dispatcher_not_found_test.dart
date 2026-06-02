import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Contract test for the 404-on-destructive-mutation seam. `ApiClient` maps a
/// 404 to [NotFoundException] (a [ConflictException] subtype). For an
/// idempotent destructive mutation (delete / purge) a 404 means the entity is
/// already gone server-side — the desired end state — so the dispatcher must
/// swallow it and apply the local delete (success), NOT let it bubble to the
/// drain's `ConflictException` catch (which parks the row a year and offers a
/// nonsensical "recreate"). For update the 404 must STILL surface as a
/// conflict (the row was deleted under us).
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

  BaseEntitySyncDispatcher<ClientItemApi, ClientApi> dispatcherFor(
    ClientsApi api,
  ) => BaseEntitySyncDispatcher<ClientItemApi, ClientApi>(
    api: api,
    repo: ClientRepository(db: db, api: api),
    dataOf: (item) => item.data,
  );

  test(
    'delete: a 404 is treated as idempotent success (not a conflict)',
    () async {
      final api = _NotFoundClientsApi();

      // Must complete normally — the entity is already gone, so the delete's
      // goal is achieved. (Pre-fix this threw ConflictException → parked.)
      await dispatcherFor(api).dispatch(
        row: rowWith(kind: 'delete', entityId: 'c1', payload: {'id': 'c1'}),
        kind: MutationKind.delete,
      );

      expect(api.deleteCalled, isTrue);
    },
  );

  test(
    'purge: a 404 is treated as idempotent success (not a conflict)',
    () async {
      final api = _NotFoundClientsApi();

      await dispatcherFor(api).dispatch(
        row: rowWith(kind: 'purge', entityId: 'c1', payload: {'id': 'c1'}),
        kind: MutationKind.purge,
      );

      expect(api.purgeCalled, isTrue);
    },
  );

  test('update: a 404 still surfaces as a conflict', () async {
    final api = _NotFoundClientsApi();

    await expectLater(
      () => dispatcherFor(api).dispatch(
        row: rowWith(kind: 'update', entityId: 'c1', payload: {'name': 'x'}),
        kind: MutationKind.update,
      ),
      throwsA(isA<ConflictException>()),
    );
  });
}

/// Fake whose mutating endpoints all 404 (→ [NotFoundException]).
class _NotFoundClientsApi implements ClientsApi {
  bool deleteCalled = false;
  bool purgeCalled = false;

  @override
  Future<void> delete({
    required String id,
    required String idempotencyKey,
    bool requiresPassword = true,
  }) async {
    deleteCalled = true;
    throw const NotFoundException();
  }

  @override
  Future<ClientItemApi?> action({
    required String id,
    required String action,
    required String idempotencyKey,
    Map<String, dynamic>? payload,
    bool requiresPassword = false,
  }) async {
    if (action == 'purge') purgeCalled = true;
    throw const NotFoundException();
  }

  @override
  Future<ClientItemApi> update({
    required String id,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    Map<String, String>? query,
    bool requiresPassword = false,
  }) async {
    throw const NotFoundException();
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '_NotFoundClientsApi.${invocation.memberName} not implemented',
  );
}
