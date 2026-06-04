import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/user_api_model.dart';
import 'package:admin/data/models/domain/user.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/user_repository.dart';
import 'package:admin/data/services/users_api.dart';
import 'package:admin/domain/sync/mutation.dart';

import '_base_entity_repository_contract.dart';

class _UserFixture extends EntityRepositoryContractFixture<User, UserApi> {
  @override
  String get entityType => 'user';

  /// `POST /api/v1/users` is password-gated server-side — admins must
  /// confirm the password before creating a teammate. The User repo puts
  /// `MutationKind.create` in `requiresPasswordFor` and the contract test
  /// honors that override here.
  @override
  bool get createRequiresPassword => true;

  @override
  UserRepository buildRepo(AppDatabase db) =>
      UserRepository(db: db, api: _FakeUsersApi());

  @override
  UserApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) => UserApi(
    id: id,
    firstName: displayValue ?? id,
    lastName: 'User',
    email: '${displayValue ?? id}@example.com',
    updatedAt: updatedAt,
  );

  @override
  User fromApi(UserApi api) => User.fromApi(api);

  @override
  User editCopy(User item, {required String displayValue}) =>
      item.copyWith(firstName: displayValue);

  @override
  String idOf(User item) => item.id;

  @override
  bool isDirtyOf(User item) => item.isDirty;

  @override
  Future<SaveResult<User>> create(
    BaseEntityRepository<User, UserApi> repo, {
    required String companyId,
    required User draft,
  }) => (repo as UserRepository).create(companyId: companyId, draft: draft);

  @override
  Future<SaveResult<User>> save(
    BaseEntityRepository<User, UserApi> repo, {
    required String companyId,
    required User entity,
  }) => (repo as UserRepository).save(companyId: companyId, user: entity);

  @override
  Future<void> delete(
    BaseEntityRepository<User, UserApi> repo, {
    required String companyId,
    required String id,
  }) => (repo as UserRepository).delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_UserFixture());

  group('UserRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    UserRepository makeRepo() => UserRepository(db: db, api: _FakeUsersApi());

    test('admin permissions round-trip via Drift overlay', () async {
      final repo = makeRepo();
      const api = UserApi(
        id: 'u_1',
        firstName: 'Admin',
        lastName: 'User',
        email: 'admin@example.com',
        updatedAt: 1700000000,
        companyUser: CompanyUserApi(
          permissions: 'view_client,edit_invoice,create_all',
          isAdmin: true,
          isOwner: false,
          notifications: NotificationsApi(email: ['invoice_viewed_all']),
        ),
      );
      await repo.applyApiResponse(companyId: 'co_1', api: api);
      final user = await repo.get(companyId: 'co_1', userId: 'u_1');
      expect(user, isNotNull);
      expect(user!.companyUser.isAdmin, isTrue);
      expect(
        user.companyUser.permissions,
        'view_client,edit_invoice,create_all',
      );
      expect(user.permissions.length, 3);
      expect(user.notificationsEmail, ['invoice_viewed_all']);
    });

    test(
      'resendEmail enqueues an inviteUser outbox row keyed by user id',
      () async {
        final repo = makeRepo();
        await repo.resendEmail(companyId: 'co_1', userId: 'u_2');
        final rows = await db.outboxDao.watchAll('co_1').first;
        expect(rows.length, 1);
        expect(rows.first.entityType, 'user');
        expect(rows.first.entityId, 'u_2');
        expect(rows.first.mutationKind, MutationKind.inviteUser.wireName);
      },
    );

    test(
      'detachFromCompany enqueues a detach outbox row with requiresPassword=true',
      () async {
        final repo = makeRepo();
        await repo.detachFromCompany(companyId: 'co_1', userId: 'u_2');
        final rows = await db.outboxDao.watchAll('co_1').first;
        expect(rows.length, 1);
        expect(
          rows.first.mutationKind,
          MutationKind.detachFromCompany.wireName,
        );
        expect(rows.first.requiresPassword, isTrue);
      },
    );

    test('archive / restore enqueue outbox rows with requiresPassword=true '
        '(POST /users/bulk is password-gated)', () async {
      final repo = makeRepo();
      await repo.archive(companyId: 'co_1', id: 'u_a');
      await repo.restore(companyId: 'co_1', id: 'u_b');
      final rows = await db.outboxDao.watchAll('co_1').first;
      final archiveRow = rows.firstWhere(
        (r) => r.mutationKind == MutationKind.archive.wireName,
      );
      final restoreRow = rows.firstWhere(
        (r) => r.mutationKind == MutationKind.restore.wireName,
      );
      expect(archiveRow.requiresPassword, isTrue);
      expect(restoreRow.requiresPassword, isTrue);
    });

    test('applyUpdateResponse preserves company_user when the bulk echo omits '
        'it (archive/restore include guard)', () async {
      final repo = makeRepo();
      await repo.applyApiResponse(
        companyId: 'co_1',
        api: const UserApi(
          id: 'u_arch',
          firstName: 'Arch',
          email: 'arch@example.com',
          updatedAt: 1700000000,
          companyUser: CompanyUserApi(permissions: 'create_all', isAdmin: true),
        ),
      );
      // Simulate a /users/bulk archive echo: archived user, no company_user.
      await repo.applyUpdateResponse(
        companyId: 'co_1',
        serverResponse: const UserApi(
          id: 'u_arch',
          firstName: 'Arch',
          email: 'arch@example.com',
          updatedAt: 1700000100,
          archivedAt: 1700000100,
        ),
      );
      final user = await repo.get(companyId: 'co_1', userId: 'u_arch');
      expect(user, isNotNull);
      expect(user!.companyUser.isAdmin, isTrue);
      expect(user.companyUser.permissions, 'create_all');
      expect(user.archivedAt, 1700000100); // the archive still landed
    });

    test('applyPurgeResponse hard-deletes the local row', () async {
      final repo = makeRepo();
      await repo.applyApiResponse(
        companyId: 'co_1',
        api: const UserApi(
          id: 'u_3',
          firstName: 'Doomed',
          email: 'doomed@example.com',
          updatedAt: 1700000000,
        ),
      );
      expect(await repo.get(companyId: 'co_1', userId: 'u_3'), isNotNull);
      await repo.applyPurgeResponse(companyId: 'co_1', id: 'u_3');
      expect(await repo.get(companyId: 'co_1', userId: 'u_3'), isNull);
    });

    test(
      'applyDetachResponse drops the local row so list stops surfacing it',
      () async {
        final repo = makeRepo();
        await repo.applyApiResponse(
          companyId: 'co_1',
          api: const UserApi(
            id: 'u_4',
            firstName: 'Leaving',
            email: 'leaving@example.com',
            updatedAt: 1700000000,
          ),
        );
        await repo.applyDetachResponse(companyId: 'co_1', id: 'u_4');
        expect(await repo.get(companyId: 'co_1', userId: 'u_4'), isNull);
      },
    );

    test('is_admin / is_owner / permissions are overlaid from indexed columns '
        'on _fromRow', () async {
      final repo = makeRepo();
      await repo.applyApiResponse(
        companyId: 'co_1',
        api: const UserApi(
          id: 'u_5',
          firstName: 'Indexed',
          email: 'indexed@example.com',
          updatedAt: 1700000000,
          companyUser: CompanyUserApi(
            permissions: 'view_invoice',
            isAdmin: false,
            isOwner: false,
          ),
        ),
      );
      final user = await repo.get(companyId: 'co_1', userId: 'u_5');
      expect(user, isNotNull);
      expect(user!.companyUser.permissions, 'view_invoice');
      expect(user.companyUser.isAdmin, isFalse);
      expect(user.companyUser.isOwner, isFalse);
    });

    test('User.toApi → fromApi round-trip preserves company_user', () {
      const api = UserApi(
        id: 'u_6',
        firstName: 'Round',
        lastName: 'Trip',
        email: 'round@example.com',
        updatedAt: 1700000000,
        companyUser: CompanyUserApi(
          permissions: 'view_client',
          isAdmin: false,
          notifications: NotificationsApi(email: ['payment_success_all']),
        ),
      );
      final domain = User.fromApi(api);
      final json = jsonEncode(domain.toApi().toJson());
      final decoded = UserApi.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(decoded.id, 'u_6');
      expect(decoded.companyUser?.permissions, 'view_client');
      expect(decoded.companyUser?.notifications.email, ['payment_success_all']);
    });

    test('notification placement — login flag top-level, special codes in '
        'notifications.email, none leak into company_user.settings', () {
      final user = const User().copyWith(
        id: 'u_7',
        userLoggedInNotification: true,
        notificationsEmail: const ['task_assigned', 'invoice_sent_all'],
        companyUserSettings: const CompanyUserSettings(accentColor: '#ff0000'),
      );
      // Encode+decode so nested objects materialize as maps (json_serializable
      // defaults to explicit_to_json: false).
      final json =
          jsonDecode(jsonEncode(user.toApi().toJson())) as Map<String, dynamic>;
      final companyUser = json['company_user'] as Map<String, dynamic>;

      // Top-level boolean (matches React / the server), not a settings key.
      expect(json['user_logged_in_notification'], isTrue);

      // Bare codes ride in the email array beside per-event subscriptions.
      expect(
        companyUser['notifications']['email'],
        containsAll(<String>['task_assigned', 'invoice_sent_all']),
      );

      // accent_color still round-trips through the settings blob…
      final settings = companyUser['settings'] as Map<String, dynamic>;
      expect(settings['accent_color'], '#ff0000');
      // …but the dead notification keys no longer leak into it.
      expect(settings.containsKey('task_assigned_notification'), isFalse);
      expect(settings.containsKey('user_logged_in_notification'), isFalse);
    });
  });
}

class _FakeUsersApi implements UsersApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
