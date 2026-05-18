import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests target the ClientListViewModel's contract — what the UI
/// depends on. They DON'T re-test the repository, Drift, or ChangeNotifier
/// itself; we use a fake ClientsApi + a real in-memory ClientRepository so
/// the dataflow we actually wire in production is exercised.

class _FakeClientsApi implements ClientsApi {
  _FakeClientsApi();
  final Map<int, List<ClientApi>> pages = {};
  final List<
    ({
      int page,
      String? search,
      Map<String, String> filters,
      int? sinceUpdatedAt,
    })
  >
  calls = [];
  Object? nextError;

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
      filters: Map<String, String>.from(filters),
      sinceUpdatedAt: sinceUpdatedAt,
    ));
    if (nextError != null) {
      final err = nextError;
      nextError = null;
      throw err!;
    }
    final rows = pages[page] ?? const <ClientApi>[];
    return (
      data: ClientListApi(data: rows),
      cursorUpdatedAt: rows.isNotEmpty ? rows.last.updatedAt : null,
      cursorId: rows.isNotEmpty ? rows.last.id : null,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ClientApi _row(String id, {String name = ''}) =>
    ClientApi(id: id, name: name.isEmpty ? id : name, updatedAt: 100);

void main() {
  late AppDatabase db;
  late _FakeClientsApi api;
  late ClientRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _FakeClientsApi();
    repo = ClientRepository(db: db, api: api);
  });
  tearDown(() async {
    await db.close();
  });

  ClientListViewModel vmFor(String companyId) => ClientListViewModel(
    repo: repo,
    navStateDao: db.navStateDao,
    userSettings: UserSettingsRepository(db: db),
    companyId: companyId,
    // Keep the debounce tiny so tests don't sleep needlessly.
    searchDebounce: const Duration(milliseconds: 1),
    persistDebounce: const Duration(milliseconds: 1),
  );

  /// Pump the event loop a few times — enough for the constructor's
  /// `unawaited(_loadInitialPage())` and any chained `notifyListeners()`
  /// to settle.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('initial load', () {
    test('triggers an ensurePageLoaded(1) on construction', () async {
      api.pages[1] = [_row('c1'), _row('c2')];
      final vm = vmFor('co');
      await settle();

      expect(api.calls, hasLength(1));
      expect(api.calls.single.page, 1);
      expect(api.calls.single.search, isNull);
      expect(vm.items.map((c) => c.id), ['c1', 'c2']);
      vm.dispose();
    });

    test('captures error so the screen can render ErrorView', () async {
      api.nextError = Exception('boom');
      final vm = vmFor('co');
      await settle();

      expect(vm.initialError, isNotNull);
      expect(vm.items, isEmpty);

      // retryInitial flows through the same path and clears the error
      // on success.
      api.pages[1] = [_row('c1')];
      await vm.retryInitial();
      await settle();

      expect(vm.initialError, isNull);
      expect(vm.items.map((c) => c.id), ['c1']);
      vm.dispose();
    });
  });

  group('loadMore', () {
    test('only widens loadedPages on a successful fetch', () async {
      api.pages[1] = [for (var i = 0; i < 50; i++) _row('c$i')]; // full page
      api.pages[2] = [_row('c50')]; // partial → hasMore=false
      final vm = vmFor('co');
      await settle();
      expect(vm.loadedPages, 1);
      expect(vm.hasMore, isTrue);

      await vm.loadMore();
      await settle();
      expect(vm.loadedPages, 2);
      expect(vm.hasMore, isFalse);

      // Calling again after hasMore=false is a no-op (no API call).
      final callsBefore = api.calls.length;
      await vm.loadMore();
      expect(api.calls.length, callsBefore);
      vm.dispose();
    });

    test('errors on subsequent pages do not bump loadedPages', () async {
      api.pages[1] = [for (var i = 0; i < 50; i++) _row('c$i')];
      final vm = vmFor('co');
      await settle();

      api.nextError = Exception('flake');
      await vm.loadMore();
      await settle();
      expect(vm.loadedPages, 1, reason: 'window must not widen on error');
      vm.dispose();
    });
  });

  group('state filter', () {
    test(
      'setStates resets pagination and passes the lifecycle `status` param',
      () async {
        api.pages[1] = [_row('c1')];
        final vm = vmFor('co');
        await settle();
        api.calls.clear();

        await vm.setStates({EntityState.active, EntityState.archived});
        await settle();

        expect(vm.loadedPages, 1);
        expect(api.calls.single.page, 1);
        expect(api.calls.single.filters['status'], 'active,archived');
        expect(
          api.calls.single.filters.containsKey('client_status'),
          isFalse,
        );
      },
    );

    test('widening states fetches with ignoreCursor so previously-uncovered '
        'rows can be pulled', () async {
      api.pages[1] = [_row('c1')];
      final vm = vmFor('co');
      await settle();
      // After initial load the cursor is advanced; the next call would
      // normally include sinceUpdatedAt. Widening the state set must
      // clear the cursor for that request.
      api.calls.clear();

      await vm.setStates({EntityState.active, EntityState.archived});
      await settle();

      expect(api.calls.single.sinceUpdatedAt, isNull);
    });

    test(
      'empty set is allowed and omits the lifecycle `status` param ("All")',
      () async {
        api.pages[1] = [_row('c1')];
        final vm = vmFor('co');
        await settle();

        await vm.setStates(<EntityState>{});
        await settle();

        expect(vm.states, isEmpty);
        expect(api.calls.last.filters.containsKey('status'), isFalse);
        // No transient notice on the new "All" path.
        expect(vm.consumeTransientNotice(), isNull);
      },
    );

    test('toggleState mirrors setStates with one entity flipped', () async {
      api.pages[1] = [_row('c1')];
      final vm = vmFor('co');
      await settle();

      vm.toggleState(EntityState.archived);
      await settle();

      expect(vm.states, {EntityState.active, EntityState.archived});
    });
  });

  group('sort', () {
    test('setSort resets pagination and notifies', () async {
      api.pages[1] = [_row('c1')];
      final vm = vmFor('co');
      await settle();

      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.setSort(field: ClientFieldIds.balance, ascending: false);
      await settle();

      expect(vm.sortField, ClientFieldIds.balance);
      expect(vm.sortAscending, isFalse);
      expect(notifications, greaterThan(0));
      expect(vm.loadedPages, 1);
    });

    test('setSort with same field+direction is a no-op', () async {
      api.pages[1] = [_row('c1')];
      final vm = vmFor('co');
      await settle();
      api.calls.clear();

      await vm.setSort(field: ClientFieldIds.name, ascending: true);
      await settle();

      expect(api.calls, isEmpty);
    });
  });

  group('custom filters', () {
    test('setCustomFilter records selection and resets pagination', () async {
      api.pages[1] = [_row('c1')];
      final vm = vmFor('co');
      await settle();

      await vm.setCustomFilter(columnIndex: 2, values: {'VIP'});
      await settle();

      expect(vm.customFilters[2], {'VIP'});
      expect(vm.loadedPages, 1);
    });

    test('setCustomFilter with empty set removes that column', () async {
      api.pages[1] = [_row('c1')];
      final vm = vmFor('co');
      await settle();
      await vm.setCustomFilter(columnIndex: 1, values: {'A'});
      await settle();
      expect(vm.customFilters.containsKey(1), isTrue);

      await vm.setCustomFilter(columnIndex: 1, values: const {});
      await settle();
      expect(vm.customFilters.containsKey(1), isFalse);
    });
  });

  group('clearAllFilters', () {
    test('returns the VM to defaults and re-fetches', () async {
      api.pages[1] = [_row('c1')];
      final vm = vmFor('co');
      await settle();
      await vm.setStates({EntityState.archived});
      await vm.setSort(field: ClientFieldIds.balance, ascending: false);
      await vm.setCustomFilter(columnIndex: 3, values: {'X'});
      await settle();
      api.calls.clear();

      await vm.clearAllFilters();
      await settle();

      // clearAllFilters drops the state dimension entirely (`{}`) rather than
      // resetting to `{active}` — an `{active}` reset re-emits a removable
      // "State: Active" chip right after the user asked to clear everything.
      expect(vm.states, isEmpty);
      expect(vm.sortField, ClientFieldIds.name);
      expect(vm.sortAscending, isTrue);
      expect(vm.customFilters, isEmpty);
      expect(api.calls, isNotEmpty);
    });

    test('is a no-op when everything is already cleared', () async {
      api.pages[1] = [_row('c1')];
      final vm = vmFor('co');
      await settle();

      // First clear takes the VM from the default `{active}` state to the
      // fully-cleared `{}` state — that transition is a real change and
      // reloads. The *second* clear is the genuine no-op: nothing differs
      // from its cleared target, so no API call is issued.
      await vm.clearAllFilters();
      await settle();
      api.calls.clear();

      await vm.clearAllFilters();
      await settle();

      expect(api.calls, isEmpty);
    });
  });

  group('hasActiveFilters', () {
    test('false at defaults, true after any change', () async {
      api.pages[1] = [_row('c1')];
      final vm = vmFor('co');
      await settle();
      expect(vm.hasActiveFilters, isFalse);

      await vm.setStates({EntityState.archived});
      await settle();
      expect(vm.hasActiveFilters, isTrue);

      await vm.clearAllFilters();
      await settle();
      expect(vm.hasActiveFilters, isFalse);
    });
  });

  group('persistence', () {
    test(
      'company-scoped filters round-trip through nav_state.filters_json',
      () async {
        api.pages[1] = [_row('c1')];
        final vm = vmFor('co-A');
        await settle();
        await vm.setStates({EntityState.archived});
        await vm.setSort(field: ClientFieldIds.balance, ascending: false);
        // Wait past the 1 ms persist debounce.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await settle();
        vm.dispose();

        // A second VM for the SAME company should rehydrate the filters.
        api.pages[1] = [_row('c1')];
        final vm2 = vmFor('co-A');
        await settle();
        expect(vm2.states, {EntityState.archived});
        expect(vm2.sortField, ClientFieldIds.balance);
        expect(vm2.sortAscending, isFalse);
        vm2.dispose();
      },
    );

    test('company switch surfaces a different filter blob', () async {
      // Seed a stored blob for company B; company A has none yet.
      await db.navStateDao.saveFilters(
        filtersJson: jsonEncode({
          'co-B': {
            // Singular `client` matches `EntityType.client.name` — the
            // generic list VM persists under the entity-type token.
            'client': {
              'states': ['deleted'],
              'sortField': 'updated_at',
              'sortAscending': false,
              'customFilters': <String, dynamic>{},
              'search': '',
            },
          },
        }),
        now: 0,
      );

      api.pages[1] = [_row('c1')];
      final vmA = vmFor('co-A');
      await settle();
      expect(vmA.states, {EntityState.active}, reason: 'co-A defaults');
      vmA.dispose();

      api.pages[1] = [_row('c1')];
      final vmB = vmFor('co-B');
      await settle();
      expect(vmB.states, {EntityState.deleted});
      expect(vmB.sortField, ClientFieldIds.updatedAt);
      expect(vmB.sortAscending, isFalse);
      vmB.dispose();
    });

    test(
      'corrupt filters_json is treated as no saved state — VM uses defaults',
      () async {
        await db.navStateDao.saveFilters(
          filtersJson: 'not even close to JSON {',
          now: 0,
        );
        api.pages[1] = [_row('c1')];
        final vm = vmFor('co');
        await settle();
        expect(vm.states, {EntityState.active});
        expect(vm.sortField, ClientFieldIds.name);
        vm.dispose();
      },
    );
  });

  group('search', () {
    test(
      'setSearch resets loadedPages and routes the term to the API',
      () async {
        api.pages[1] = [for (var i = 0; i < 50; i++) _row('c$i')];
        api.pages[2] = [_row('c50')];
        final vm = vmFor('co');
        await settle();
        await vm.loadMore();
        await settle();
        expect(vm.loadedPages, 2);

        // Now searching — the next API call should carry the term and
        // loadedPages should reset to 1.
        api.calls.clear();
        api.pages[1] = [_row('c_match', name: 'Acme')];
        vm.setSearch('acme');
        await settle();
        // Give the 1 ms debounce time to fire.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await settle();

        expect(vm.loadedPages, 1);
        expect(api.calls, hasLength(1));
        expect(api.calls.single.search, 'acme');
        vm.dispose();
      },
    );
  });
}
