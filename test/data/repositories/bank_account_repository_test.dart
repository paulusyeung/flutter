import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/bank_account_api_model.dart';
import 'package:admin/data/models/domain/bank_account.dart';
import 'package:admin/data/repositories/bank_account_repository.dart';
import 'package:admin/data/services/bank_accounts_api.dart';
import 'package:admin/domain/sync/mutation.dart';

import '_base_entity_repository_contract.dart';

void main() {
  runEntityRepositoryContract(
    EntityRepositoryContractFixture<BankAccount, BankAccountApi>.build(
      entityType: 'bank_account',
      buildRepo: (db) =>
          BankAccountRepository(db: db, api: _FakeBankAccountsApi()),
      buildApiModel: ({
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
          (repo as BankAccountRepository)
              .create(companyId: companyId, draft: draft),
      save: (repo, {required companyId, required entity}) =>
          (repo as BankAccountRepository)
              .save(companyId: companyId, account: entity),
      delete: (repo, {required companyId, required id}) =>
          (repo as BankAccountRepository)
              .delete(companyId: companyId, id: id),
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

    test(
      'refreshAccounts enqueues a refreshAccounts mutation row '
      'keyed under the synthetic kRefreshAccountsEntityId',
      () async {
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
  });
}

class _FakeBankAccountsApi implements BankAccountsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
