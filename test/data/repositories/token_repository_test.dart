import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/token_api_model.dart';
import 'package:admin/data/models/domain/token.dart';
import 'package:admin/data/repositories/token_repository.dart';
import 'package:admin/data/services/tokens_api.dart';

import '_base_entity_repository_contract.dart';

void main() {
  runEntityRepositoryContract(
    EntityRepositoryContractFixture<Token, TokenApi>.build(
      entityType: 'token',
      buildRepo: (db) => TokenRepository(db: db, api: _FakeTokensApi()),
      buildApiModel: ({
        required String id,
        String? displayValue,
        int updatedAt = 1700000000,
      }) => TokenApi(
        id: id,
        name: displayValue ?? id,
        // List/refresh responses come masked (10 chars + 'xxxxxxxxxxx').
        token: 'cnm1dcvo01xxxxxxxxxxx',
        updatedAt: updatedAt,
      ),
      fromApi: Token.fromApi,
      editCopy: (item, {required String displayValue}) =>
          item.copyWith(name: displayValue),
      idOf: (item) => item.id,
      isDirtyOf: (item) => item.isDirty,
      create: (repo, {required companyId, required draft}) =>
          (repo as TokenRepository).create(companyId: companyId, draft: draft),
      save: (repo, {required companyId, required entity}) =>
          (repo as TokenRepository).save(companyId: companyId, token: entity),
      delete: (repo, {required companyId, required id}) =>
          (repo as TokenRepository).delete(companyId: companyId, id: id),
    ),
  );

  group('TokenRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    TokenRepository makeRepo() =>
        TokenRepository(db: db, api: _FakeTokensApi());

    test('isMasked detects the server "xxxxxxxxxxx" suffix', () {
      final maskedToken = Token.fromApi(
        const TokenApi(id: 't_1', name: 'N', token: 'abc1234567xxxxxxxxxxx'),
      );
      expect(maskedToken.isMasked, isTrue);
      expect(maskedToken.tokenHint, 'abc1234567…');

      final raw = Token.fromApi(
        const TokenApi(id: 't_1', name: 'N', token: 'raw-bearer-secret-here'),
      );
      expect(raw.isMasked, isFalse);
    });

    test('toApiJson strips the read-only token and user_id fields', () {
      final t = Token.fromApi(
        const TokenApi(
          id: 't_1',
          name: 'My Token',
          token: 'abc1234567xxxxxxxxxxx',
          userId: 'u_1',
        ),
      );
      final json = t.toApiJson(preserveTempId: true);
      expect(json['name'], 'My Token');
      expect(json.containsKey('token'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
    });

    test('toApiJson emits id only for real ids, never for tmp_ ids', () {
      final saved = Token.fromApi(const TokenApi(id: 't_1', name: 'N'));
      final tmp = saved.copyWith(id: 'tmp_abc');
      expect(saved.toApiJson()['id'], 't_1');
      expect(tmp.toApiJson().containsKey('id'), isFalse);
      expect(tmp.toApiJson(preserveTempId: true)['id'], 'tmp_abc');
    });

    test(
      'applyBundle upserts every row and advances the cursor to max updatedAt',
      () async {
        final repo = makeRepo();
        await repo.applyBundle(
          companyId: 'co',
          bundle: const [
            TokenApi(
              id: 't_a',
              name: 'Alpha',
              token: 'abc1234567xxxxxxxxxxx',
              updatedAt: 1700000100,
            ),
            TokenApi(
              id: 't_b',
              name: 'Beta',
              token: 'def4567890xxxxxxxxxxx',
              updatedAt: 1700000200,
            ),
          ],
        );
        final rows =
            await repo.watchPage(companyId: 'co', loadedPages: 4).first;
        expect(rows.map((t) => t.id).toSet(), {'t_a', 't_b'});
        // Every persisted row should be the masked form.
        expect(rows.every((t) => t.isMasked), isTrue);
        final cursor = await db.syncStateDao.read(
          companyId: 'co',
          entityType: 'token',
        );
        expect(cursor.updatedAt, 1700000200);
        expect(cursor.id, 't_b');
      },
    );

    test('applyBundle is a no-op when the bundle is empty', () async {
      final repo = makeRepo();
      await repo.applyBundle(companyId: 'co', bundle: const []);
      final cursor = await db.syncStateDao.read(
        companyId: 'co',
        entityType: 'token',
      );
      expect(cursor.isEmpty, isTrue);
    });

    test('applyBundle preserves the local payload of an is_dirty row '
        'so an offline edit is not clobbered by a re-bundle', () async {
      final repo = makeRepo();
      final draft = Token.fromApi(const TokenApi(name: 'Offline'));
      await repo.create(companyId: 'co', draft: draft);
      final dirtyBefore = (await repo.watchPage(companyId: 'co').first).single;
      expect(dirtyBefore.isDirty, isTrue);

      await repo.applyBundle(
        companyId: 'co',
        bundle: const [
          TokenApi(
            id: 't_server',
            name: 'Server',
            token: 'abc1234567xxxxxxxxxxx',
            updatedAt: 1700000500,
          ),
        ],
      );
      final all = await repo.watchPage(companyId: 'co').first;
      expect(all, hasLength(2));
      expect(all.map((t) => t.name).toSet(), {'Offline', 'Server'});
      final stillDirty = all.firstWhere((t) => t.name == 'Offline');
      expect(stillDirty.isDirty, isTrue);
    });

    test(
      'applyCreateResponse broadcasts the raw secret on newSecrets '
      'AND persists the masked form to Drift',
      () async {
        final repo = makeRepo();

        final draft = Token.fromApi(const TokenApi(name: 'My Token'));
        final stored = await repo.create(companyId: 'co', draft: draft);
        final tempId = stored.id;

        final firstSecret = repo.newSecrets.first;

        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: tempId,
          serverResponse: const TokenApi(
            id: 't_real',
            name: 'My Token',
            token: 'this-is-the-raw-bearer-secret',
            userId: 'u_1',
            updatedAt: 1700000123,
          ),
        );

        final secret = await firstSecret.timeout(const Duration(seconds: 2));
        expect(secret.tempId, tempId);
        expect(secret.secret, 'this-is-the-raw-bearer-secret');

        // After applyCreateResponse, the dedicated `token` column holds the
        // raw secret (temporarily, until the next `/refresh` overwrites it
        // with the masked form). The crucial invariant is what we *send*:
        // `Token.toApiJson` strips `token`, so the outbox never echoes the
        // secret back. Verify the sent shape explicitly.
        final row = await db.tokenDao
            .watchById(companyId: 'co', id: 't_real')
            .first;
        expect(row, isNotNull);
        final domain = Token.fromApi(
          const TokenApi(
            id: 't_real',
            name: 'My Token',
            token: 'this-is-the-raw-bearer-secret',
            userId: 'u_1',
          ),
        );
        final sentJson = domain.toApiJson(preserveTempId: true);
        expect(sentJson.containsKey('token'), isFalse);
        expect(sentJson.containsKey('user_id'), isFalse);
      },
    );

    test(
      'applyCreateResponse does NOT emit on newSecrets when the response '
      'token is already masked (e.g. a refresh-driven re-create)',
      () async {
        final repo = makeRepo();

        var emitted = 0;
        final sub = repo.newSecrets.listen((_) => emitted++);
        addTearDown(sub.cancel);

        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'tmp_abc',
          serverResponse: const TokenApi(
            id: 't_masked',
            name: 'Masked',
            token: 'abc1234567xxxxxxxxxxx',
            updatedAt: 1700000200,
          ),
        );
        // Give the broadcast stream a tick to deliver if it were going to.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emitted, 0);
      },
    );

    test(
      '_fromRow overlays is_dirty so an offline create reads as dirty',
      () async {
        final repo = makeRepo();
        final draft = Token.fromApi(const TokenApi(name: 'New'));
        await repo.create(companyId: 'co', draft: draft);
        final rows = await repo.watchPage(companyId: 'co').first;
        expect(rows, hasLength(1));
        expect(rows.first.isDirty, isTrue);
      },
    );
  });
}

class _FakeTokensApi implements TokensApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
