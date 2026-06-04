import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/user_api_model.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/user_repository.dart';
import 'package:admin/data/repositories/user_sync_dispatcher.dart';
import 'package:admin/data/services/users_api.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Regression guard for the launch bug where user archive/restore/delete were
/// dispatched to per-id routes (`POST /users/{id}/archive`, `DELETE
/// /users/{id}`) that don't exist server-side. Users expose these lifecycle
/// ops ONLY via `POST /users/bulk` (password-gated). The recording fake throws
/// on any per-id `action()` / `delete()`, so a regression fails loudly.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  OutboxRow rowFor(MutationKind kind) => OutboxRow(
    id: 1,
    companyId: 'co',
    entityType: 'user',
    entityId: 'u1',
    mutationKind: kind.wireName,
    payload: '{}',
    idempotencyKey: 'idk',
    state: 'pending',
    attempts: 0,
    nextAttemptAt: 0,
    createdAt: 0,
    requiresPassword: true,
  );

  Future<_RecordingUsersApi> dispatch(MutationKind kind) async {
    final api = _RecordingUsersApi();
    final repo = UserRepository(db: db, api: api);
    final dispatcher = UserSyncDispatcher(
      api: api,
      repo: repo,
      auth: _FakeAuth(),
    );
    await dispatcher.dispatch(row: rowFor(kind), kind: kind);
    return api;
  }

  test(
    'archive → POST /users/bulk with include=company_user + password',
    () async {
      final api = await dispatch(MutationKind.archive);
      expect(api.bulkCalls, hasLength(1));
      expect(api.bulkCalls.single.action, 'archive');
      expect(api.bulkCalls.single.id, 'u1');
      expect(api.bulkCalls.single.requiresPassword, isTrue);
      expect(api.bulkCalls.single.query, {'include': 'company_user'});
    },
  );

  test('restore → POST /users/bulk with password', () async {
    final api = await dispatch(MutationKind.restore);
    expect(api.bulkCalls.single.action, 'restore');
    expect(api.bulkCalls.single.requiresPassword, isTrue);
  });

  test(
    'delete → POST /users/bulk (no RESTful per-id DELETE for users)',
    () async {
      final api = await dispatch(MutationKind.delete);
      expect(api.bulkCalls.single.action, 'delete');
      expect(api.bulkCalls.single.requiresPassword, isTrue);
    },
  );
}

class _RecordingUsersApi implements UsersApi {
  final List<
    ({
      String action,
      String id,
      bool requiresPassword,
      Map<String, String>? query,
    })
  >
  bulkCalls = [];

  @override
  Future<UserItemApi?> bulkActionOne({
    required String id,
    required String action,
    required String idempotencyKey,
    Map<String, dynamic>? extra,
    Map<String, String>? query,
    bool requiresPassword = false,
  }) async {
    bulkCalls.add((
      action: action,
      id: id,
      requiresPassword: requiresPassword,
      query: query,
    ));
    return UserItemApi(
      data: UserApi(
        id: id,
        firstName: 'X',
        email: 'x@example.com',
        updatedAt: 1700000000,
        companyUser: const CompanyUserApi(
          permissions: 'view_client',
          isAdmin: false,
        ),
      ),
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Unexpected ${invocation.memberName} — user archive/restore/delete must '
    'route through bulkActionOne (POST /users/bulk), not per-id action()/'
    'delete().',
  );
}

class _FakeAuth implements AuthRepository {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
