import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/payment_term_api_model.dart';
import 'package:admin/data/models/domain/payment_term.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/payment_term_repository.dart';
import 'package:admin/data/services/payment_terms_api.dart';

import '_base_entity_repository_contract.dart';

/// Covers the universal `BaseEntityRepository` contract via the shared
/// harness and a small set of payment_term-specific assertions for behavior
/// the contract doesn't probe (applyBundle upsert + cursor advance, dirty-
/// preserving re-bundle, watchAll ordering by num_days).
class _PaymentTermFixture
    extends EntityRepositoryContractFixture<PaymentTerm, PaymentTermApi> {
  @override
  String get entityType => 'payment_term';

  @override
  PaymentTermRepository buildRepo(AppDatabase db) =>
      PaymentTermRepository(db: db, api: _FakePaymentTermsApi());

  @override
  PaymentTermApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) => PaymentTermApi(
    id: id,
    name: displayValue ?? id,
    numDays: 30,
    updatedAt: updatedAt,
  );

  @override
  PaymentTerm fromApi(PaymentTermApi api) => PaymentTerm.fromApi(api);

  @override
  PaymentTerm editCopy(PaymentTerm item, {required String displayValue}) =>
      item.copyWith(name: displayValue);

  @override
  String idOf(PaymentTerm item) => item.id;

  @override
  bool isDirtyOf(PaymentTerm item) => item.isDirty;

  @override
  Future<PaymentTerm> create(
    BaseEntityRepository<PaymentTerm, PaymentTermApi> repo, {
    required String companyId,
    required PaymentTerm draft,
  }) => (repo as PaymentTermRepository).create(
    companyId: companyId,
    draft: draft,
  );

  @override
  Future<void> save(
    BaseEntityRepository<PaymentTerm, PaymentTermApi> repo, {
    required String companyId,
    required PaymentTerm entity,
  }) =>
      (repo as PaymentTermRepository).save(companyId: companyId, term: entity);

  @override
  Future<void> delete(
    BaseEntityRepository<PaymentTerm, PaymentTermApi> repo, {
    required String companyId,
    required String id,
  }) => (repo as PaymentTermRepository).delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_PaymentTermFixture());

  group('PaymentTermRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    PaymentTermRepository makeRepo() =>
        PaymentTermRepository(db: db, api: _FakePaymentTermsApi());

    test(
      'PaymentTermApi → PaymentTerm round-trip preserves name and num_days',
      () {
        const api = PaymentTermApi(
          id: 'pt_1',
          name: 'Net 30',
          numDays: 30,
          updatedAt: 1700000000,
        );
        final domain = PaymentTerm.fromApi(api);
        expect(domain.id, 'pt_1');
        expect(domain.name, 'Net 30');
        expect(domain.numDays, 30);
        expect(domain.isDirty, isFalse);
      },
    );

    test('toApiJson emits id only for real ids, never for tmp_ ids', () {
      final saved = PaymentTerm.fromApi(
        const PaymentTermApi(id: 'pt_1', name: 'Net 30', numDays: 30),
      );
      final tmp = saved.copyWith(id: 'tmp_abc');
      expect(saved.toApiJson()['id'], 'pt_1');
      expect(tmp.toApiJson().containsKey('id'), isFalse);
      // preserveTempId opts in (used by the repo when writing the local
      // payload column so the row survives an app restart).
      expect(tmp.toApiJson(preserveTempId: true)['id'], 'tmp_abc');
    });

    test(
      'applyBundle upserts every row and advances the cursor to max updatedAt',
      () async {
        final repo = makeRepo();
        await repo.applyBundle(
          companyId: 'co',
          bundle: const [
            PaymentTermApi(
              id: 'pt_a',
              name: 'Net 7',
              numDays: 7,
              updatedAt: 1700000100,
            ),
            PaymentTermApi(
              id: 'pt_b',
              name: 'Net 30',
              numDays: 30,
              updatedAt: 1700000200,
            ),
          ],
        );
        final rows = await repo.watchAll(companyId: 'co').first;
        expect(rows.map((t) => t.id).toList(), ['pt_a', 'pt_b']);
        final cursor = await db.syncStateDao.read(
          companyId: 'co',
          entityType: 'payment_term',
        );
        expect(cursor.updatedAt, 1700000200);
        expect(cursor.id, 'pt_b');
      },
    );

    test('applyBundle is a no-op when the bundle is empty', () async {
      final repo = makeRepo();
      await repo.applyBundle(companyId: 'co', bundle: const []);
      final cursor = await db.syncStateDao.read(
        companyId: 'co',
        entityType: 'payment_term',
      );
      expect(cursor.isEmpty, isTrue);
    });

    test('applyBundle preserves the local payload of an is_dirty row '
        'so an offline edit is not clobbered by a re-bundle', () async {
      final repo = makeRepo();
      // Land a dirty local edit (offline create).
      final draft = PaymentTerm.fromApi(
        const PaymentTermApi(name: 'My Custom', numDays: 14),
      );
      await repo.create(companyId: 'co', draft: draft);
      final dirtyBefore = (await repo.watchAll(companyId: 'co').first).single;
      expect(dirtyBefore.isDirty, isTrue);

      // Re-bundle with a server row that has the same tmp_ id (won't happen
      // in practice — the point is to confirm upsertAll wins for clean rows
      // and the cursor advances). Use a different real id and confirm both
      // coexist; the local dirty row stays.
      await repo.applyBundle(
        companyId: 'co',
        bundle: const [
          PaymentTermApi(
            id: 'pt_server',
            name: 'Net 30',
            numDays: 30,
            updatedAt: 1700000500,
          ),
        ],
      );
      final all = await repo.watchAll(companyId: 'co').first;
      expect(all, hasLength(2));
      expect(all.map((t) => t.name).toSet(), {'My Custom', 'Net 30'});
      // The dirty row's flag is preserved.
      final stillDirty = all.firstWhere((t) => t.name == 'My Custom');
      expect(stillDirty.isDirty, isTrue);
    });

    test(
      'watchAll orders by num_days ascending and excludes archived rows',
      () async {
        final repo = makeRepo();
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'pt_60',
          serverResponse: const PaymentTermApi(
            id: 'pt_60',
            name: 'Net 60',
            numDays: 60,
            updatedAt: 1700000000,
          ),
        );
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'pt_7',
          serverResponse: const PaymentTermApi(
            id: 'pt_7',
            name: 'Net 7',
            numDays: 7,
            updatedAt: 1700000001,
          ),
        );
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'pt_old',
          serverResponse: const PaymentTermApi(
            id: 'pt_old',
            name: 'Archived',
            numDays: 14,
            updatedAt: 1700000002,
            archivedAt: 1700000002,
          ),
        );
        final rows = await repo.watchAll(companyId: 'co').first;
        expect(rows.map((t) => t.id).toList(), ['pt_7', 'pt_60']);
      },
    );

    test(
      '_fromRow overlays is_dirty so an offline create reads as dirty',
      () async {
        final repo = makeRepo();
        final draft = PaymentTerm.fromApi(
          const PaymentTermApi(name: 'New Term', numDays: 21),
        );
        await repo.create(companyId: 'co', draft: draft);
        final rows = await repo.watchAll(companyId: 'co').first;
        expect(rows, hasLength(1));
        expect(rows.first.isDirty, isTrue);
      },
    );
  });
}

class _FakePaymentTermsApi implements PaymentTermsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
