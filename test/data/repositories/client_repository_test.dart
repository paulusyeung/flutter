import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import '_base_entity_repository_contract.dart';

/// These tests target ClientRepository's behavioral contracts that other
/// layers depend on:
///   * mutations land in the outbox with a fresh idempotency key
///   * delete needs requiresPassword=true (server policy)
///   * offline create assigns a tmp id and tracks it
///   * watch(tmpId) survives the tmp→real swap
///   * page-by-page loading advances the cursor and stops at hasMore=false
///   * search routes to the API's `filter` param
/// They do NOT test Drift, http, or the freezed-generated code.

class _FakeClientsApi implements ClientsApi {
  _FakeClientsApi(this._pages);

  /// Pages by their requested page number (1-indexed).
  final Map<int, List<ClientApi>> _pages;

  final List<
    ({
      int page,
      String? search,
      int? since,
      String? sinceId,
      Map<String, String> filters,
    })
  >
  calls = [];

  @override
  Future<({ClientListApi data, int? cursorUpdatedAt, String? cursorId})> list({
    required int page,
    int perPage = 50,
    String? search,
    int? sinceUpdatedAt,
    String? sinceId,
    Map<String, String> filters = const {},
  }) async {
    calls.add((
      page: page,
      search: search,
      since: sinceUpdatedAt,
      sinceId: sinceId,
      filters: Map<String, String>.from(filters),
    ));
    final rows = _pages[page] ?? <ClientApi>[];
    return (
      data: ClientListApi(data: rows),
      cursorUpdatedAt: rows.isNotEmpty ? rows.last.updatedAt : null,
      cursorId: rows.isNotEmpty ? rows.last.id : null,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _ClientFixture
    extends EntityRepositoryContractFixture<Client, ClientApi> {
  @override
  String get entityType => 'client';

  @override
  ClientRepository buildRepo(AppDatabase db) =>
      ClientRepository(db: db, api: _FakeClientsApi(const {}));

  @override
  ClientApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) => ClientApi(id: id, name: displayValue ?? id, updatedAt: updatedAt);

  @override
  Client fromApi(ClientApi api) => Client.fromApi(api);

  @override
  Client editCopy(Client item, {required String displayValue}) =>
      item.copyWith(name: displayValue, displayName: displayValue);

  @override
  String idOf(Client item) => item.id;

  @override
  bool isDirtyOf(Client item) => item.isDirty;

  @override
  Future<Client> create(
    BaseEntityRepository<Client, ClientApi> repo, {
    required String companyId,
    required Client draft,
  }) => (repo as ClientRepository).create(companyId: companyId, draft: draft);

  @override
  Future<void> save(
    BaseEntityRepository<Client, ClientApi> repo, {
    required String companyId,
    required Client entity,
  }) => (repo as ClientRepository).save(companyId: companyId, client: entity);

  @override
  Future<void> delete(
    BaseEntityRepository<Client, ClientApi> repo, {
    required String companyId,
    required String id,
  }) => (repo as ClientRepository).delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_ClientFixture());

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  /// Build a repo with a fake API and deterministic uuid + clock so we can
  /// assert outbox row fields exactly.
  ({ClientRepository repo, _FakeClientsApi api}) makeRepo({
    Map<int, List<ClientApi>> pages = const {},
  }) {
    final api = _FakeClientsApi(pages);
    final repo = ClientRepository(
      db: db,
      api: api,
      uuid: const Uuid(),
      now: () => DateTime.utc(2026, 5, 11, 12),
    );
    return (repo: repo, api: api);
  }

  ClientApi apiClient(
    String id, {
    String name = '',
    int updatedAt = 1700000000,
  }) => ClientApi(id: id, name: name.isEmpty ? id : name, updatedAt: updatedAt);

  group('save', () {
    test(
      'writes locally with is_dirty=true and enqueues an update outbox row',
      () async {
        final (:repo, :api) = makeRepo();
        final c = Client.fromApi(
          apiClient('c1', name: 'Acme'),
        ).copyWith(name: 'Acme Renamed');

        await repo.save(companyId: 'co', client: c);

        final row = await db.clientDao
            .watchById(companyId: 'co', id: 'c1')
            .first;
        expect(row, isNotNull);
        expect(row!.name, 'Acme Renamed');
        expect(row.isDirty, isTrue);

        final pending = await db.outboxDao.nextReady(
          companyId: 'co',
          now: 1 << 60,
        );
        expect(pending, hasLength(1));
        expect(pending.single.mutationKind, MutationKind.update.wireName);
        expect(pending.single.entityType, 'client');
        expect(pending.single.idempotencyKey, isNotEmpty);
        expect(pending.single.requiresPassword, isFalse);
      },
    );
  });

  group('delete', () {
    test('flags requiresPassword=true per server policy', () async {
      final (:repo, :api) = makeRepo();
      await repo.delete(companyId: 'co', id: 'c1');

      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(pending.single.mutationKind, 'delete');
      expect(
        pending.single.requiresPassword,
        isTrue,
        reason: 'delete must surface ConfirmPasswordSheet',
      );
    });
  });

  group('purge', () {
    test('enqueues a purge outbox row with requiresPassword=true so the sync '
        'engine prompts before hitting POST /clients/:id/purge', () async {
      final (:repo, :api) = makeRepo();
      await repo.purge(companyId: 'co', id: 'c1');

      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(pending.single.mutationKind, MutationKind.purge.wireName);
      expect(pending.single.entityType, 'client');
      expect(pending.single.idempotencyKey, isNotEmpty);
      expect(
        pending.single.requiresPassword,
        isTrue,
        reason: 'purge must surface ConfirmPasswordSheet',
      );
    });

    test(
      'applyPurgeResponse hard-deletes the local row — purge is irreversible '
      'so the row should not linger like applyDeleteResponse leaves it',
      () async {
        final (:repo, :api) = makeRepo();
        await repo.save(
          companyId: 'co',
          client: Client.fromApi(apiClient('c1', name: 'Acme')),
        );

        await repo.applyPurgeResponse(companyId: 'co', id: 'c1');

        final byId = await repo.watch(companyId: 'co', id: 'c1').first;
        expect(byId, isNull, reason: 'detail watcher should emit null');

        final visible = await repo
            .watchPage(
              companyId: 'co',
              loadedPages: 1,
              states: EntityState.values.toSet(),
            )
            .first;
        expect(
          visible,
          isEmpty,
          reason: 'every state filter should stop surfacing the row',
        );
      },
    );
  });

  group('merge', () {
    test('enqueues a merge outbox row (entityId = absorbed client) with '
        'requiresPassword=true and the into/from payload', () async {
      final (:repo, :api) = makeRepo();
      await repo.merge(
        companyId: 'co',
        mergeIntoId: 'survivor',
        mergeFromId: 'absorbed',
      );

      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(pending.single.mutationKind, MutationKind.merge.wireName);
      expect(pending.single.entityType, 'client');
      expect(
        pending.single.entityId,
        'absorbed',
        reason: 'the row belongs to the client being deleted',
      );
      expect(pending.single.idempotencyKey, isNotEmpty);
      expect(
        pending.single.requiresPassword,
        isTrue,
        reason: 'merge is password-gated like delete/purge',
      );
      final payload =
          jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expect(payload['merge_into_id'], 'survivor');
      expect(payload['merge_from_id'], 'absorbed');
    });
  });

  group('locations', () {
    Future<Map<String, dynamic>> drainPayload() async {
      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      return jsonDecode(pending.single.payload) as Map<String, dynamic>;
    }

    test('createLocation enqueues a location_create row keyed to the client',
        () async {
      final (:repo, :api) = makeRepo();
      await repo.createLocation(
        companyId: 'co',
        clientId: 'cl1',
        body: const {'name': 'HQ', 'client_id': 'cl1'},
      );
      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(
        pending.single.mutationKind,
        MutationKind.locationCreate.wireName,
      );
      expect(pending.single.entityId, 'cl1');
      expect(pending.single.idempotencyKey, isNotEmpty);
      final payload = await drainPayload();
      expect(payload['client_id'], 'cl1');
      expect((payload['body'] as Map)['name'], 'HQ');
    });

    test('updateLocation carries the location id + body', () async {
      final (:repo, :api) = makeRepo();
      await repo.updateLocation(
        companyId: 'co',
        clientId: 'cl1',
        locationId: 'loc9',
        body: const {'name': 'Warehouse'},
      );
      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(
        pending.single.mutationKind,
        MutationKind.locationUpdate.wireName,
      );
      expect(pending.single.entityId, 'cl1');
      final payload = await drainPayload();
      expect(payload['location_id'], 'loc9');
      expect((payload['body'] as Map)['name'], 'Warehouse');
    });

    test('deleteLocation enqueues a location_delete row', () async {
      final (:repo, :api) = makeRepo();
      await repo.deleteLocation(
        companyId: 'co',
        clientId: 'cl1',
        locationId: 'loc9',
      );
      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(
        pending.single.mutationKind,
        MutationKind.locationDelete.wireName,
      );
      expect(pending.single.entityId, 'cl1');
      final payload = await drainPayload();
      expect(payload['location_id'], 'loc9');
    });
  });

  group('create (offline)', () {
    test('mints a tmp_ id, stores it, and outbox payload omits id', () async {
      final (:repo, :api) = makeRepo();
      final draft = Client.fromApi(apiClient('', name: 'New Co'));

      final created = await repo.create(companyId: 'co', draft: draft);
      expect(created.id, startsWith('tmp_'));

      final stored = await db.clientDao
          .watchById(companyId: 'co', id: created.id)
          .first;
      expect(stored, isNotNull);
      expect(stored!.name, 'New Co');

      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      final payload =
          jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expect(
        payload.containsKey('id'),
        isFalse,
        reason: 'server allocates the real id — never send a tmp_',
      );
      expect(payload['name'], 'New Co');
    });

    test(
      'watch(tmpId) keeps emitting after the sync engine remaps the id',
      () async {
        final (:repo, :api) = makeRepo();
        final created = await repo.create(
          companyId: 'co',
          draft: Client.fromApi(apiClient('', name: 'New Co')),
        );

        // Sync lands: the sync engine receives the server's response
        // (canonical entity with real id) and calls applyCreateResponse.
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: created.id,
          serverResponse: apiClient('real_xyz', name: 'New Co'),
        );

        // The detail screen was opened with `tmp_...`; the URL never changes.
        final stream = repo.watch(companyId: 'co', id: created.id);
        final landed = await stream.first;
        expect(
          landed?.id,
          'real_xyz',
          reason: 'watch must resolve through id_remap',
        );
      },
    );
  });

  group('pagination', () {
    test(
      'ensurePageLoaded upserts a page and advances cursor; hasMore reflects '
      'page size',
      () async {
        final fullPage = [for (var i = 0; i < 50; i++) apiClient('c$i')];
        final partialPage = [apiClient('c50')];
        final (:repo, :api) = makeRepo(pages: {1: fullPage, 2: partialPage});

        final hasMore1 = await repo.ensurePageLoaded(companyId: 'co', page: 1);
        expect(hasMore1, isTrue);

        final cursor1 = await db.syncStateDao.read(
          companyId: 'co',
          entityType: 'client',
        );
        expect(cursor1.id, 'c49');

        final hasMore2 = await repo.ensurePageLoaded(companyId: 'co', page: 2);
        expect(hasMore2, isFalse, reason: 'partial page means end of list');

        // Subsequent calls send the cursor.
        expect(api.calls.last.sinceId, isNotNull);
      },
    );

    test(
      'search term routes to the API filter param (server-side search)',
      () async {
        final (:repo, :api) = makeRepo(
          pages: {
            1: [apiClient('c1', name: 'Acme')],
          },
        );

        await repo.ensurePageLoaded(companyId: 'co', page: 1, search: 'acme');

        expect(
          api.calls.single.search,
          'acme',
          reason: 'local LIKE alone misses pages we have not fetched yet',
        );
      },
    );

    test(
      'ensurePageLoaded passes client_status filter for non-default state sets',
      () async {
        final (:repo, :api) = makeRepo(pages: {1: const <ClientApi>[]});

        await repo.ensurePageLoaded(
          companyId: 'co',
          page: 1,
          states: {EntityState.archived, EntityState.deleted},
        );

        expect(
          api.calls.single.filters['client_status'],
          'archived,deleted',
          reason: 'server needs the state filter to surface non-active rows',
        );
      },
    );

    test(
      'ensurePageLoaded omits client_status when every state is requested',
      () async {
        final (:repo, :api) = makeRepo(pages: {1: const <ClientApi>[]});

        await repo.ensurePageLoaded(
          companyId: 'co',
          page: 1,
          states: EntityState.values.toSet(),
        );

        expect(api.calls.single.filters.containsKey('client_status'), isFalse);
      },
    );

    test(
      'ensurePageLoaded threads extraFilters as flat query params (not bracketed)',
      () async {
        final (:repo, :api) = makeRepo(pages: {1: const <ClientApi>[]});

        await repo.ensurePageLoaded(
          companyId: 'co',
          page: 1,
          extraFilters: {
            // Multi-value: comma-joined deterministically (sorted).
            'country_id': {'840', '124'},
            'group_settings_id': {'g1'},
          },
        );

        // The v2 API takes flat snake_case keys, NOT `filter[country_id]=…`.
        expect(api.calls.single.filters['country_id'], '124,840');
        expect(api.calls.single.filters['group_settings_id'], 'g1');
      },
    );

    test('ensurePageLoaded drops empty extraFilter sets', () async {
      final (:repo, :api) = makeRepo(pages: {1: const <ClientApi>[]});

      await repo.ensurePageLoaded(
        companyId: 'co',
        page: 1,
        extraFilters: const {'country_id': <String>{}},
      );

      expect(api.calls.single.filters.containsKey('country_id'), isFalse);
    });

    test('ensurePageLoaded preserves is_dirty=true rows so a paged refresh '
        "doesn't clobber the user's pending offline edit", () async {
      // Seed a clean row, then dirty it via save() (simulating an offline
      // edit), then refresh page 1 with a stale server payload for the same
      // id. The dirty row must survive — both the local edit (`name`) and
      // the dirty flag.
      const id = 'c_persist';
      final (:repo, :api) = makeRepo(
        pages: {
          1: [apiClient(id, name: 'Server Name')],
        },
      );

      await repo.applyCreateResponse(
        companyId: 'co',
        tempId: id,
        serverResponse: apiClient(id, name: 'Server Name'),
      );
      final loaded = await db.clientDao
          .watchById(companyId: 'co', id: id)
          .first;
      expect(loaded!.isDirty, isFalse);

      await repo.save(
        companyId: 'co',
        client: Client.fromApi(
          apiClient(id, name: 'Server Name'),
        ).copyWith(name: 'User Edit'),
      );
      final dirty = await db.clientDao
          .watchById(companyId: 'co', id: id)
          .first;
      expect(dirty!.isDirty, isTrue);
      expect(dirty.name, 'User Edit');

      await repo.ensurePageLoaded(companyId: 'co', page: 1);

      final after = await db.clientDao
          .watchById(companyId: 'co', id: id)
          .first;
      expect(
        after!.isDirty,
        isTrue,
        reason: 'page refresh must not clear the dirty flag',
      );
      expect(
        after.name,
        'User Edit',
        reason: "page refresh must not overwrite the user's local edit",
      );
    });

    test(
      'refreshAll pulls every state so the local cache covers archived/deleted '
      'without the user pulling-to-refresh again',
      () async {
        final (:repo, :api) = makeRepo(pages: {1: const <ClientApi>[]});

        await repo.refreshAll(companyId: 'co');

        // No client_status filter — the server returns all states.
        expect(api.calls.first.filters.containsKey('client_status'), isFalse);
      },
    );

    test(
      'refreshAll(full: true) clears the cursor and re-pulls from page 1',
      () async {
        await db.syncStateDao.writeCursor(
          companyId: 'co',
          entityType: 'client',
          updatedAt: 100,
          id: 'old',
          now: 0,
        );
        final (:repo, :api) = makeRepo(pages: {1: <ClientApi>[]});

        await repo.refreshAll(companyId: 'co', full: true);

        expect(api.calls.first.since, isNull);
        expect(api.calls.first.sinceId, isNull);
      },
    );
  });

  group('Drift row round-trip', () {
    test(
      'email column projects the primary contact for fast filtering',
      () async {
        final (:repo, :api) = makeRepo();
        final c = Client.fromApi(
          ClientApi.fromJson({
            'id': 'c1',
            'name': 'Acme',
            'balance': '0',
            'contacts': [
              {'id': 'a', 'email': 'secondary@a.test', 'is_primary': false},
              {'id': 'b', 'email': 'primary@a.test', 'is_primary': true},
            ],
          }),
        );

        await repo.save(companyId: 'co', client: c);
        final row = await db.clientDao
            .watchById(companyId: 'co', id: 'c1')
            .first;
        expect(
          row!.email,
          'primary@a.test',
          reason: 'list filters use the projected email — must be the primary',
        );
      },
    );

    test(
      'Decimal balance survives the storage round-trip without precision loss',
      () async {
        final (:repo, :api) = makeRepo();
        final c = Client.fromApi(
          ClientApi.fromJson({
            'id': 'c1',
            'name': 'Acme',
            'balance': '12345.67',
          }),
        );

        await repo.save(companyId: 'co', client: c);
        final got = await repo.watch(companyId: 'co', id: 'c1').first;
        expect(got!.balance, Decimal.parse('12345.67'));
      },
    );

    test(
      'isDirty survives the storage round-trip so the "Unsynced" chip renders '
      'after restart',
      () async {
        // Regression: _fromRow used to discard the row's is_dirty column
        // because Client.fromApi only sees the API payload.
        final (:repo, :api) = makeRepo();
        final c = Client.fromApi(apiClient('c1', name: 'Acme'));
        await repo.save(companyId: 'co', client: c);

        final got = await repo.watch(companyId: 'co', id: 'c1').first;
        expect(got!.isDirty, isTrue);

        // Server confirms the save → applyUpdateResponse clears the flag.
        await repo.applyUpdateResponse(
          companyId: 'co',
          serverResponse: apiClient('c1', name: 'Acme'),
        );
        final clean = await repo.watch(companyId: 'co', id: 'c1').first;
        expect(clean!.isDirty, isFalse);
      },
    );

    test('applyDeleteResponse marks the local row is_deleted=true so the list '
        'hides it immediately', () async {
      // Regression: the dispatcher used to wait for the next pull-to-refresh
      // to remove deleted rows from the visible list.
      final (:repo, :api) = makeRepo();
      await repo.save(
        companyId: 'co',
        client: Client.fromApi(apiClient('c1', name: 'Acme')),
      );

      await repo.applyDeleteResponse(companyId: 'co', id: 'c1');

      final visible = await repo
          .watchPage(companyId: 'co', loadedPages: 1)
          .first;
      expect(
        visible.map((c) => c.id),
        isEmpty,
        reason: 'is_deleted=true rows are filtered out of watchPage',
      );
    });
  });

  group('watchPage extraFilters[name]', () {
    test('applies a substring `name` filter locally so the list narrows in '
        'lockstep with the server', () async {
      // Regression: previously the local watch ignored `extraFilters`,
      // so applying a name chip left every cached row visible even
      // though the server returned only the matching subset.
      final (:repo, :api) = makeRepo();
      await repo.save(
        companyId: 'co',
        client: Client.fromApi(apiClient('c1', name: 'Alpha')),
      );
      await repo.save(
        companyId: 'co',
        client: Client.fromApi(apiClient('c2', name: 'Beta')),
      );
      await repo.save(
        companyId: 'co',
        client: Client.fromApi(apiClient('c3', name: 'Gamma')),
      );

      final filtered = await repo
          .watchPage(
            companyId: 'co',
            loadedPages: 1,
            extraFilters: const {
              'name': {'ma'},
            },
          )
          .first;
      expect(
        filtered.map((c) => c.name),
        ['Gamma'],
        reason: 'SQL LIKE %ma% on the `name` column matches only Gamma',
      );

      // Sanity: with no filter, all three are visible.
      final unfiltered = await repo
          .watchPage(companyId: 'co', loadedPages: 1)
          .first;
      expect(unfiltered.map((c) => c.name).toList()..sort(), [
        'Alpha',
        'Beta',
        'Gamma',
      ]);
    });

    test('empty value set is treated as no filter', () async {
      final (:repo, :api) = makeRepo();
      await repo.save(
        companyId: 'co',
        client: Client.fromApi(apiClient('c1', name: 'Alpha')),
      );
      final result = await repo
          .watchPage(
            companyId: 'co',
            loadedPages: 1,
            extraFilters: const {'name': <String>{}},
          )
          .first;
      expect(result.map((c) => c.name), ['Alpha']);
    });
  });

  group('watchPage extraFilters[balance]', () {
    // Fixture: four clients with balances spanning the demo data shape.
    // The DAO casts the TEXT column to REAL for numeric comparison.
    Future<ClientRepository> seedBalances(ClientRepository repo) async {
      for (final (id, name, balance) in const [
        ('c1', 'Alpha', '100'),
        ('c2', 'Beta', '500'),
        ('c3', 'Gamma', '1000'),
        ('c4', 'Delta', '2000'),
      ]) {
        await repo.save(
          companyId: 'co',
          client: Client.fromApi(
            ClientApi.fromJson({'id': id, 'name': name, 'balance': balance}),
          ),
        );
      }
      return repo;
    }

    test(
      'applies `value:gt` locally — balance > 500 narrows to two rows',
      () async {
        final (:repo, :api) = makeRepo();
        await seedBalances(repo);
        final result = await repo
            .watchPage(
              companyId: 'co',
              loadedPages: 1,
              extraFilters: const {
                'balance': {'500:gt'},
              },
            )
            .first;
        expect(result.map((c) => c.name).toList()..sort(), ['Delta', 'Gamma']);
      },
    );

    test(
      'applies `value:lt` locally — balance < 500 narrows to one row',
      () async {
        final (:repo, :api) = makeRepo();
        await seedBalances(repo);
        final result = await repo
            .watchPage(
              companyId: 'co',
              loadedPages: 1,
              extraFilters: const {
                'balance': {'500:lt'},
              },
            )
            .first;
        expect(result.map((c) => c.name), ['Alpha']);
      },
    );

    test('numeric cast — 100 < 1000 lexicographically would invert; cast '
        'ensures the comparison is correct', () async {
      // String comparison would put '1000' < '500' < '100'. CAST as
      // REAL gives the expected 100 < 500 < 1000 < 2000.
      final (:repo, :api) = makeRepo();
      await seedBalances(repo);
      final result = await repo
          .watchPage(
            companyId: 'co',
            loadedPages: 1,
            extraFilters: const {
              'balance': {'1500:lt'},
            },
          )
          .first;
      expect(result.map((c) => c.name).toList()..sort(), [
        'Alpha',
        'Beta',
        'Gamma',
      ]);
    });

    test('legacy prefix `gt:value` is still parsed (upgrade path for '
        'persisted state from older app versions)', () async {
      final (:repo, :api) = makeRepo();
      await seedBalances(repo);
      final result = await repo
          .watchPage(
            companyId: 'co',
            loadedPages: 1,
            extraFilters: const {
              'balance': {'gt:500'},
            },
          )
          .first;
      expect(result.map((c) => c.name).toList()..sort(), ['Delta', 'Gamma']);
    });

    test('empty value set is treated as no filter', () async {
      final (:repo, :api) = makeRepo();
      await seedBalances(repo);
      final result = await repo
          .watchPage(
            companyId: 'co',
            loadedPages: 1,
            extraFilters: const {'balance': <String>{}},
          )
          .first;
      expect(result, hasLength(4));
    });

    test('unparseable wire is ignored — no rows are filtered out', () async {
      final (:repo, :api) = makeRepo();
      await seedBalances(repo);
      final result = await repo
          .watchPage(
            companyId: 'co',
            loadedPages: 1,
            extraFilters: const {
              'balance': {'garbage'},
            },
          )
          .first;
      expect(result, hasLength(4));
    });
  });

  group('addComment', () {
    test('enqueues a single add_comment outbox row with trimmed notes and '
        'the entity_id payload — no local Drift write', () async {
      final (:repo, :api) = makeRepo();

      await repo.addComment(
        companyId: 'co',
        clientId: 'c1',
        text: '  hello world  ',
      );

      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(pending, hasLength(1));
      final row = pending.single;
      expect(row.entityType, 'client');
      expect(row.entityId, 'c1');
      expect(row.mutationKind, 'add_comment');
      expect(row.idempotencyKey, isNotEmpty);
      expect(row.requiresPassword, isFalse);

      final payload = jsonDecode(row.payload) as Map<String, dynamic>;
      expect(payload['entity_id'], 'c1');
      expect(
        payload['notes'],
        'hello world',
        reason: 'whitespace must be trimmed before the server sees it',
      );

      // Comments do not touch the clients table.
      final clientRow = await db.clientDao
          .watchById(companyId: 'co', id: 'c1')
          .first;
      expect(clientRow, isNull);
    });

    test('watchPendingForEntity streams the row until it lands', () async {
      final (:repo, :api) = makeRepo();
      await repo.addComment(companyId: 'co', clientId: 'c1', text: 'hi');

      final pending = await db.outboxDao
          .watchPendingForEntity(
            companyId: 'co',
            entityType: 'client',
            entityId: 'c1',
            kind: MutationKind.addComment,
          )
          .first;
      expect(pending, hasLength(1));
      expect(pending.single.mutationKind, 'add_comment');
    });

    test('watchPendingForEntity[kind] excludes rows of other mutation kinds '
        'on the same entity — a parallel `update` does not leak into the '
        'Activity tab', () async {
      final (:repo, :api) = makeRepo();
      // Two pending mutations on the same client: an update + an
      // addComment. The Activity tab should only see the comment.
      await repo.save(
        companyId: 'co',
        client: Client.fromApi(apiClient('c1', name: 'Acme')),
      );
      await repo.addComment(companyId: 'co', clientId: 'c1', text: 'note');

      final scoped = await db.outboxDao
          .watchPendingForEntity(
            companyId: 'co',
            entityType: 'client',
            entityId: 'c1',
            kind: MutationKind.addComment,
          )
          .first;
      expect(scoped, hasLength(1));
      expect(scoped.single.mutationKind, 'add_comment');

      // Sanity: without the kind filter, both rows surface.
      final unfiltered = await db.outboxDao
          .watchPendingForEntity(
            companyId: 'co',
            entityType: 'client',
            entityId: 'c1',
          )
          .first;
      expect(unfiltered, hasLength(2));
    });
  });
}
