import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/webhook_api_model.dart';
import 'package:admin/data/models/domain/webhook.dart';
import 'package:admin/data/repositories/webhook_repository.dart';
import 'package:admin/data/services/webhooks_api.dart';

import '_base_entity_repository_contract.dart';

void main() {
  runEntityRepositoryContract(
    EntityRepositoryContractFixture<Webhook, WebhookApi>.build(
      entityType: 'webhook',
      buildRepo: (db) => WebhookRepository(db: db, api: _FakeWebhooksApi()),
      buildApiModel:
          ({
            required String id,
            String? displayValue,
            int updatedAt = 1700000000,
          }) => WebhookApi(
            id: id,
            targetUrl: displayValue ?? 'https://example.test/$id',
            eventId: '1',
            updatedAt: updatedAt,
          ),
      fromApi: Webhook.fromApi,
      editCopy: (item, {required String displayValue}) =>
          item.copyWith(targetUrl: displayValue),
      idOf: (item) => item.id,
      isDirtyOf: (item) => item.isDirty,
      create: (repo, {required companyId, required draft}) =>
          (repo as WebhookRepository).create(
            companyId: companyId,
            draft: draft,
          ),
      save: (repo, {required companyId, required entity}) =>
          (repo as WebhookRepository).save(
            companyId: companyId,
            webhook: entity,
          ),
      delete: (repo, {required companyId, required id}) =>
          (repo as WebhookRepository).delete(companyId: companyId, id: id),
      // WebhookController applies no `password_protected` middleware.
      deleteRequiresPassword: false,
    ),
  );

  group('WebhookRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    WebhookRepository makeRepo() =>
        WebhookRepository(db: db, api: _FakeWebhooksApi());

    test('WebhookApi → Webhook round-trip preserves headers + format', () {
      const api = WebhookApi(
        id: 'w_1',
        eventId: '1',
        targetUrl: 'https://example.test/hook',
        format: 'JSON',
        restMethod: 'post',
        headers: {'X-Token': 'abc'},
        updatedAt: 1700000000,
      );
      final domain = Webhook.fromApi(api);
      expect(domain.id, 'w_1');
      expect(domain.targetUrl, 'https://example.test/hook');
      expect(domain.eventId, '1');
      expect(domain.restMethod, 'post');
      expect(domain.headers, {'X-Token': 'abc'});
      expect(domain.isDirty, isFalse);
    });

    test('fromApi defaults format and restMethod when empty', () {
      const api = WebhookApi(id: 'w_1', eventId: '1', targetUrl: 'x');
      final domain = Webhook.fromApi(api);
      expect(domain.format, kWebhookDefaultFormat);
      expect(domain.restMethod, kWebhookDefaultRestMethod);
    });

    test('fromApi normalizes a legacy uppercase rest_method to lowercase', () {
      // A row created before the server's lowercase `in:post,put` rule was
      // honored could carry 'POST'; the canonical domain value must be lowercase
      // so the edit screen's SegmentedButton highlights the right segment.
      const api = WebhookApi(
        id: 'w_1',
        eventId: '1',
        targetUrl: 'x',
        restMethod: 'POST',
      );
      expect(Webhook.fromApi(api).restMethod, 'post');
    });

    test('toApiJson emits id only for real ids, never for tmp_ ids', () {
      final saved = Webhook.fromApi(
        const WebhookApi(id: 'w_1', eventId: '1', targetUrl: 'x'),
      );
      final tmp = saved.copyWith(id: 'tmp_abc');
      expect(saved.toApiJson()['id'], 'w_1');
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
            WebhookApi(
              id: 'w_a',
              eventId: '1',
              targetUrl: 'https://a.test',
              updatedAt: 1700000100,
            ),
            WebhookApi(
              id: 'w_b',
              eventId: '2',
              targetUrl: 'https://b.test',
              updatedAt: 1700000200,
            ),
          ],
        );
        final rows = await repo
            .watchPage(companyId: 'co', loadedPages: 4)
            .first;
        expect(rows.map((w) => w.id).toSet(), {'w_a', 'w_b'});
        final cursor = await db.syncStateDao.read(
          companyId: 'co',
          entityType: 'webhook',
        );
        expect(cursor.updatedAt, 1700000200);
        expect(cursor.id, 'w_b');
      },
    );

    test('applyBundle is a no-op when the bundle is empty', () async {
      final repo = makeRepo();
      await repo.applyBundle(companyId: 'co', bundle: const []);
      final cursor = await db.syncStateDao.read(
        companyId: 'co',
        entityType: 'webhook',
      );
      expect(cursor.isEmpty, isTrue);
    });

    test('applyBundle preserves the local payload of an is_dirty row '
        'so an offline edit is not clobbered by a re-bundle', () async {
      final repo = makeRepo();
      final draft = Webhook.fromApi(
        const WebhookApi(eventId: '1', targetUrl: 'https://offline.test'),
      );
      await repo.create(companyId: 'co', draft: draft);
      final dirtyBefore = (await repo.watchPage(companyId: 'co').first).single;
      expect(dirtyBefore.isDirty, isTrue);

      await repo.applyBundle(
        companyId: 'co',
        bundle: const [
          WebhookApi(
            id: 'w_server',
            eventId: '2',
            targetUrl: 'https://server.test',
            updatedAt: 1700000500,
          ),
        ],
      );
      final all = await repo.watchPage(companyId: 'co').first;
      expect(all, hasLength(2));
      expect(all.map((w) => w.targetUrl).toSet(), {
        'https://offline.test',
        'https://server.test',
      });
      final stillDirty = all.firstWhere(
        (w) => w.targetUrl == 'https://offline.test',
      );
      expect(stillDirty.isDirty, isTrue);
    });
  });
}

class _FakeWebhooksApi implements WebhooksApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
