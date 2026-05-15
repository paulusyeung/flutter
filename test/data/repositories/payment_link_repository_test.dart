import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/payment_link_dao.dart';
import 'package:admin/data/models/api/subscription_api_model.dart';
import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/payment_link_repository.dart';
import 'package:admin/data/services/subscriptions_api.dart';

import '_base_entity_repository_contract.dart';

/// Covers the universal BaseEntityRepository contract via the shared
/// harness plus payment-link-specific behavior: webhook + steps +
/// plan_map round-trip, applyBundle upsert/cursor, priceCents numeric
/// denormalization. The wire DTO is still `SubscriptionApi` (the API
/// boundary).
class _PaymentLinkFixture
    extends EntityRepositoryContractFixture<PaymentLink, SubscriptionApi> {
  @override
  String get entityType => 'payment_link';

  @override
  PaymentLinkRepository buildRepo(AppDatabase db) =>
      PaymentLinkRepository(db: db, api: _FakeSubscriptionsApi());

  @override
  SubscriptionApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) => SubscriptionApi(
    id: id,
    name: displayValue ?? id,
    price: '9.50',
    updatedAt: updatedAt,
  );

  @override
  PaymentLink fromApi(SubscriptionApi api) => PaymentLink.fromApi(api);

  @override
  PaymentLink editCopy(PaymentLink item, {required String displayValue}) =>
      item.copyWith(name: displayValue);

  @override
  String idOf(PaymentLink item) => item.id;

  @override
  bool isDirtyOf(PaymentLink item) => item.isDirty;

  @override
  Future<PaymentLink> create(
    BaseEntityRepository<PaymentLink, SubscriptionApi> repo, {
    required String companyId,
    required PaymentLink draft,
  }) => (repo as PaymentLinkRepository)
      .create(companyId: companyId, draft: draft);

  @override
  Future<void> save(
    BaseEntityRepository<PaymentLink, SubscriptionApi> repo, {
    required String companyId,
    required PaymentLink entity,
  }) => (repo as PaymentLinkRepository)
      .save(companyId: companyId, paymentLink: entity);

  @override
  Future<void> delete(
    BaseEntityRepository<PaymentLink, SubscriptionApi> repo, {
    required String companyId,
    required String id,
  }) =>
      (repo as PaymentLinkRepository).delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_PaymentLinkFixture());

  group('PaymentLinkRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    PaymentLinkRepository makeRepo() =>
        PaymentLinkRepository(db: db, api: _FakeSubscriptionsApi());

    test('webhook_configuration headers round-trip through Drift save→load',
        () async {
      final repo = makeRepo();
      final draft = emptyPaymentLink().copyWith(
        name: 'Hooked',
        webhookConfiguration: const PaymentLinkWebhook(
          returnUrl: 'https://example.test/return',
          postPurchaseUrl: 'https://example.test/hook',
          postPurchaseRestMethod: 'post',
          postPurchaseHeaders: {'X-Custom': 'value', 'Authorization': 'Bearer'},
          postPurchaseBody: 'legacy-body',
        ),
      );
      final created = await repo.create(companyId: 'co', draft: draft);
      final reloaded = await repo
          .watch(companyId: 'co', id: created.id)
          .first;
      expect(reloaded, isNotNull);
      expect(reloaded!.webhookConfiguration.postPurchaseUrl,
          'https://example.test/hook');
      expect(reloaded.webhookConfiguration.postPurchaseRestMethod, 'post');
      expect(
        reloaded.webhookConfiguration.postPurchaseHeaders,
        {'X-Custom': 'value', 'Authorization': 'Bearer'},
      );
      expect(reloaded.webhookConfiguration.postPurchaseBody, 'legacy-body');
    });

    test('steps comma-joined string round-trips through Drift', () async {
      final repo = makeRepo();
      final draft = emptyPaymentLink().copyWith(
        name: 'Ordered',
        steps: 'auth.login,cart,custom.confirmation',
      );
      final created = await repo.create(companyId: 'co', draft: draft);
      final reloaded = await repo
          .watch(companyId: 'co', id: created.id)
          .first;
      expect(reloaded?.steps, 'auth.login,cart,custom.confirmation');
    });

    test('plan_map round-trips opaquely (no editor, no loss)', () async {
      final repo = makeRepo();
      final draft = emptyPaymentLink().copyWith(
        name: 'PlanMapped',
        planMap: 'opaque-internal-blob',
      );
      final created = await repo.create(companyId: 'co', draft: draft);
      final reloaded = await repo
          .watch(companyId: 'co', id: created.id)
          .first;
      expect(reloaded?.planMap, 'opaque-internal-blob');
    });

    test('priceCents denormalization: price=9.50 → priceCents=950 → '
        'sortable numerically', () async {
      final repo = makeRepo();
      // Land two rows: one priced at 9.50 (950 cents), one at 100.00
      // (10000 cents). A TEXT sort would put '100.00' before '9.50' —
      // priceCents sorts as integers so we get the numeric order.
      await repo.applyBundle(
        companyId: 'co',
        bundle: const [
          SubscriptionApi(
            id: 's_cheap',
            name: 'Cheap',
            price: '9.50',
            updatedAt: 1700000100,
          ),
          SubscriptionApi(
            id: 's_expensive',
            name: 'Expensive',
            price: '100.00',
            updatedAt: 1700000200,
          ),
        ],
      );
      final rows = await repo
          .watchPage(
            companyId: 'co',
            sortField: PaymentLinkFieldIds.price,
            sortAscending: true,
          )
          .first;
      expect(rows.map((s) => s.id).toList(), ['s_cheap', 's_expensive']);
      // Cheap is first (950 < 10000). Confirm the canonical Decimal
      // also survived round-trip.
      expect(rows[0].price, Decimal.parse('9.50'));
      expect(rows[1].price, Decimal.parse('100.00'));
    });

    test('applyBundle upserts every row and advances the cursor to max '
        'updatedAt', () async {
      final repo = makeRepo();
      await repo.applyBundle(
        companyId: 'co',
        bundle: const [
          SubscriptionApi(
            id: 's_a',
            name: 'Plan A',
            updatedAt: 1700000100,
          ),
          SubscriptionApi(
            id: 's_b',
            name: 'Plan B',
            updatedAt: 1700000300,
          ),
        ],
      );
      final rows = await repo.watchPage(companyId: 'co').first;
      expect(rows.map((s) => s.id).toSet(), {'s_a', 's_b'});
      final cursor = await db.syncStateDao.read(
        companyId: 'co',
        entityType: 'payment_link',
      );
      expect(cursor.updatedAt, 1700000300);
      expect(cursor.id, 's_b');
    });

    test('applyBundle preserves the local payload of an is_dirty row '
        'so an offline edit is not clobbered by a re-bundle', () async {
      final repo = makeRepo();
      final draft = emptyPaymentLink().copyWith(name: 'Local');
      await repo.create(companyId: 'co', draft: draft);
      final dirtyBefore = (await repo.watchPage(companyId: 'co').first).single;
      expect(dirtyBefore.isDirty, isTrue);

      await repo.applyBundle(
        companyId: 'co',
        bundle: const [
          SubscriptionApi(
            id: 's_server',
            name: 'Server Plan',
            updatedAt: 1700000500,
          ),
        ],
      );
      final all = await repo.watchPage(companyId: 'co').first;
      expect(all, hasLength(2));
      expect(all.map((s) => s.name).toSet(), {'Local', 'Server Plan'});
      final stillDirty = all.firstWhere((s) => s.name == 'Local');
      expect(stillDirty.isDirty, isTrue);
    });

    test('local round-trip preserves createdAt / updatedAt / isDeleted '
        '(toApiJson(preserveTempId: true) emits the timestamp + identity '
        'fields the repo would otherwise lose)', () async {
      final repo = makeRepo();
      // Server hands us a row with real timestamps.
      const api = SubscriptionApi(
        id: 's_existing',
        name: 'Existing',
        createdAt: 1700000100,
        updatedAt: 1700000200,
      );
      await repo.applyUpdateResponse(companyId: 'co', serverResponse: api);

      // Local save (simulates an offline edit). The payload column now
      // carries `toApiJson(preserveTempId: true)`.
      final loaded =
          await repo.watch(companyId: 'co', id: 's_existing').first;
      await repo.save(
        companyId: 'co',
        paymentLink: loaded!.copyWith(name: 'Edited'),
      );

      // Reload from Drift via _fromRow. Timestamps must survive.
      final after = await repo.watch(companyId: 'co', id: 's_existing').first;
      expect(after, isNotNull);
      expect(after!.name, 'Edited');
      expect(after.createdAt.millisecondsSinceEpoch ~/ 1000, 1700000100);
      expect(after.updatedAt.millisecondsSinceEpoch ~/ 1000, 1700000200);
      expect(after.isDeleted, isFalse);
    });
  });
}

class _FakeSubscriptionsApi implements SubscriptionsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
