import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/bank_account_api_model.dart';
import 'package:admin/data/models/domain/bank_account.dart';
import 'package:admin/data/repositories/bank_account_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/bank_accounts_api.dart';
import 'package:admin/domain/sync/mutation.dart';

import '_base_entity_repository_contract.dart';

void main() {
  runEntityRepositoryContract(
    EntityRepositoryContractFixture<BankAccount, BankAccountApi>.build(
      entityType: 'bank_account',
      buildRepo: (db) =>
          BankAccountRepository(db: db, api: _FakeBankAccountsApi()),
      buildApiModel:
          ({
            required String id,
            String? displayValue,
            int updatedAt = 1700000000,
          }) => BankAccountApi(
            id: id,
            bankAccountName: displayValue ?? id,
            updatedAt: updatedAt,
          ),
      fromApi: BankAccount.fromApi,
      editCopy: (item, {required String displayValue}) =>
          item.copyWith(name: displayValue),
      idOf: (item) => item.id,
      isDirtyOf: (item) => item.isDirty,
      create: (repo, {required companyId, required draft}) =>
          (repo as BankAccountRepository).create(
            companyId: companyId,
            draft: draft,
          ),
      save: (repo, {required companyId, required entity}) =>
          (repo as BankAccountRepository).save(
            companyId: companyId,
            account: entity,
          ),
      delete: (repo, {required companyId, required id}) =>
          (repo as BankAccountRepository).delete(companyId: companyId, id: id),
    ),
  );

  group('BankAccountRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    BankAccountRepository makeRepo() =>
        BankAccountRepository(db: db, api: _FakeBankAccountsApi());

    test('refreshAccounts enqueues a refreshAccounts mutation row '
        'keyed under the synthetic kRefreshAccountsEntityId', () async {
      final repo = makeRepo();
      await repo.refreshAccounts(companyId: 'co');
      final rows = await db.outboxDao.watchAll('co').first;
      final row = rows.firstWhere(
        (r) => r.mutationKind == MutationKind.refreshAccounts.wireName,
      );
      // refresh isn't keyed to a single integration — verify the row
      // uses the synthetic id so the outbox screen doesn't pretend
      // otherwise.
      expect(row.entityId, kRefreshAccountsEntityId);
    });

    test(
      'save enqueues a minimal update patch — never resends '
      'provider-managed fields that would clobber the synced balance',
      () async {
        final repo = makeRepo();
        // A real (already-synced) account carrying provider-managed values.
        final account = BankAccount.fromApi(
          const BankAccountApi(
            id: 'bi_1',
            bankAccountName: 'Acme',
            bankAccountStatus: 'READY',
            bankAccountType: 'CHECKING',
            providerName: 'Chase',
            currency: 'USD',
          ),
        ).copyWith(balance: Decimal.parse('1234.56'), autoSync: true);

        await repo.save(companyId: 'co', account: account);

        final rows = await db.outboxDao.watchAll('co').first;
        final row = rows.firstWhere(
          (r) => r.mutationKind == MutationKind.update.wireName,
        );
        final payload = jsonDecode(row.payload) as Map<String, dynamic>;

        // Only user-editable keys travel; provider-managed fields are absent.
        expect(payload.keys.toSet(), {
          'bank_account_name',
          'from_date',
          'auto_sync',
        });
        expect(payload['bank_account_name'], 'Acme');
        expect(payload['auto_sync'], isTrue);
        for (final clobberable in const [
          'balance',
          'bank_account_status',
          'bank_account_type',
          'provider_name',
          'currency',
        ]) {
          expect(
            payload.containsKey(clobberable),
            isFalse,
            reason: '$clobberable must not be sent on update',
          );
        }
      },
    );

    test('disabledUpstream + integrationType drives needsReconnect', () {
      final yodleeBroken = BankAccount.fromApi(
        const BankAccountApi(
          id: 'b1',
          bankAccountName: 'Acme',
          disabledUpstream: true,
          integrationType: kBankIntegrationYodlee,
        ),
      );
      expect(yodleeBroken.needsReconnect, isTrue);

      final manualBroken = BankAccount.fromApi(
        const BankAccountApi(
          id: 'b2',
          bankAccountName: 'Manual',
          disabledUpstream: true,
          integrationType: '',
        ),
      );
      expect(manualBroken.needsReconnect, isFalse);

      final yodleeHealthy = BankAccount.fromApi(
        const BankAccountApi(
          id: 'b3',
          bankAccountName: 'Healthy',
          integrationType: kBankIntegrationYodlee,
        ),
      );
      expect(yodleeHealthy.needsReconnect, isFalse);
    });

    test('toApiJson drops id for tmp_ ids unless preserveTempId is true', () {
      final saved = BankAccount.fromApi(
        const BankAccountApi(id: 'bi_1', bankAccountName: 'Saved'),
      );
      final tmp = saved.copyWith(id: 'tmp_abc');
      expect(saved.toApiJson()['id'], 'bi_1');
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
            BankAccountApi(
              id: 'bi_a',
              bankAccountName: 'Alpha',
              updatedAt: 1700000100,
            ),
            BankAccountApi(
              id: 'bi_b',
              bankAccountName: 'Beta',
              updatedAt: 1700000200,
            ),
          ],
        );
        final rows = await repo
            .watchPage(companyId: 'co', loadedPages: 4)
            .first;
        expect(rows.map((a) => a.id).toSet(), {'bi_a', 'bi_b'});
        final cursor = await db.syncStateDao.read(
          companyId: 'co',
          entityType: 'bank_account',
        );
        expect(cursor.updatedAt, 1700000200);
        expect(cursor.id, 'bi_b');
      },
    );

    test('applyBundle is a no-op when the bundle is empty', () async {
      final repo = makeRepo();
      await repo.applyBundle(companyId: 'co', bundle: const []);
      final cursor = await db.syncStateDao.read(
        companyId: 'co',
        entityType: 'bank_account',
      );
      expect(cursor.isEmpty, isTrue);
    });

    test('applyBundle preserves the local payload of an is_dirty row '
        'so an offline edit is not clobbered by a re-bundle', () async {
      final repo = makeRepo();
      final draft = BankAccount.fromApi(
        const BankAccountApi(bankAccountName: 'Local Bank'),
      );
      await repo.create(companyId: 'co', draft: draft);
      final dirtyBefore = (await repo.watchPage(companyId: 'co').first).single;
      expect(dirtyBefore.isDirty, isTrue);

      await repo.applyBundle(
        companyId: 'co',
        bundle: const [
          BankAccountApi(
            id: 'bi_server',
            bankAccountName: 'Server Bank',
            updatedAt: 1700000500,
          ),
        ],
      );
      final all = await repo.watchPage(companyId: 'co').first;
      expect(all, hasLength(2));
      expect(all.map((a) => a.name).toSet(), {'Local Bank', 'Server Bank'});
      final stillDirty = all.firstWhere((a) => a.name == 'Local Bank');
      expect(stillDirty.isDirty, isTrue);
    });
  });

  // `ensureLoaded` backs `BankAccountNameLabel`'s cache-miss path (a
  // transaction referencing an unbundled/stale integration). Verifies
  // it fetches+upserts once, short-circuits when cached, and skips /
  // negative-caches non-fetchable ids.
  group('BankAccountRepository — ensureLoaded (lazy hydrate)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    test('cache miss → fetches by id, upserts, watch resolves', () async {
      final api = _GetBankAccountsApi({
        'bi_1': const BankAccountApi(id: 'bi_1', bankAccountName: 'Acme Bank'),
      });
      final repo = BankAccountRepository(db: db, api: api);
      await repo.ensureLoaded(companyId: 'co', id: 'bi_1');
      final a = await repo.watch(companyId: 'co', id: 'bi_1').first;
      expect(a?.name, 'Acme Bank');
      expect(api.getCalls, 1);
    });

    test('already cached → no second network fetch', () async {
      final api = _GetBankAccountsApi({
        'bi_1': const BankAccountApi(id: 'bi_1', bankAccountName: 'Acme Bank'),
      });
      final repo = BankAccountRepository(db: db, api: api);
      await repo.ensureLoaded(companyId: 'co', id: 'bi_1');
      await repo.ensureLoaded(companyId: 'co', id: 'bi_1');
      expect(api.getCalls, 1);
    });

    test('empty / tmp_ ids are no-ops (no network)', () async {
      final api = _GetBankAccountsApi(const {});
      final repo = BankAccountRepository(db: db, api: api);
      await repo.ensureLoaded(companyId: 'co', id: '');
      await repo.ensureLoaded(companyId: 'co', id: 'tmp_x');
      expect(api.getCalls, 0);
    });

    test('missing id is negative-cached — fetched at most once', () async {
      final api = _GetBankAccountsApi(const {});
      final repo = BankAccountRepository(db: db, api: api);
      await repo.ensureLoaded(companyId: 'co', id: 'gone');
      await repo.ensureLoaded(companyId: 'co', id: 'gone');
      expect(api.getCalls, 1);
    });
  });
}

/// Fake serving single-id GETs for the `ensureLoaded` tests; counts
/// calls so dedupe / negative-cache behaviour is observable.
class _GetBankAccountsApi implements BankAccountsApi {
  _GetBankAccountsApi(this._byId);

  final Map<String, BankAccountApi> _byId;
  int getCalls = 0;

  @override
  Future<BankAccountItemApi> get(String id) async {
    getCalls++;
    final a = _byId[id];
    if (a == null)
      throw const NotFoundException('404 — bank account not found');
    return BankAccountItemApi(data: a);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBankAccountsApi implements BankAccountsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
