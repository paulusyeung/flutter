import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/deep_link_filter_intent.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins `GenericListViewModel.applyDeepLinkIntent`: replace (not merge)
/// semantics, a single reload, and once-only consumption per token.

class _FakeVm extends GenericListViewModel<dynamic> {
  _FakeVm({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
  });

  int fetchCount = 0;
  Map<String, Set<String>> lastFetchExtraFilters = const {};
  Set<EntityState> lastFetchStates = const {};

  @override
  EntityType get entityType => EntityType.invoice;

  @override
  List<ColumnDefinition<dynamic>> get allColumns => const [];

  @override
  List<String> get defaultColumnIds => const [];

  @override
  String get defaultSortField => 'number';

  @override
  bool isValidColumnId(String field) => true;

  @override
  String idOf(dynamic item) => '';

  @override
  bool isArchived(dynamic item) => false;

  @override
  bool isDeleted(dynamic item) => false;

  @override
  Stream<List<dynamic>> watchPage() => const Stream.empty();

  @override
  Future<bool> fetchPage({
    required int page,
    required String? search,
    required Set<EntityState> states,
    required Map<String, Set<String>> extraFilters,
    required bool ignoreCursor,
  }) async {
    fetchCount++;
    lastFetchStates = states;
    lastFetchExtraFilters = extraFilters;
    return false;
  }

  @override
  Future<void> refreshAll() async {}

  @override
  Iterable<BulkAction<dynamic>> get bulkActions => const [];
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  Future<_FakeVm> makeVm() async {
    final vm = _FakeVm(
      companyId: 'co',
      navStateDao: db.navStateDao,
      userSettings: UserSettingsRepository(db: db),
      searchDebounce: const Duration(milliseconds: 1),
      persistDebounce: const Duration(milliseconds: 1),
    );
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return vm;
  }

  test('applies extraFilters + sort and reloads exactly once', () async {
    final vm = await makeVm();
    final fetchesAfterInit = vm.fetchCount;

    await vm.applyDeepLinkIntent(
      ListFilterIntent(
        extraFilters: const {
          'overdue': {'true'},
        },
        sortField: 'due_date',
        sortAscending: true,
        token: 't1',
      ),
    );

    expect(vm.fetchCount, fetchesAfterInit + 1);
    expect(vm.extraFilters['overdue'], {'true'});
    expect(vm.sortField, 'due_date');
    expect(vm.sortAscending, isTrue);
    expect(vm.lastFetchExtraFilters['overdue'], {'true'});

    vm.dispose();
  });

  test('replaces — does not merge — the user\'s leftover filters', () async {
    final vm = await makeVm();

    // Pre-existing user filter.
    await vm.setExtraFilter(serverKey: 'status_id', values: {'4'});
    expect(vm.extraFilters['status_id'], {'4'});

    await vm.applyDeepLinkIntent(
      ListFilterIntent(
        extraFilters: const {
          'overdue': {'true'},
        },
        token: 't2',
      ),
    );

    // The panel directive wins outright — the stale status_id is gone.
    expect(vm.extraFilters.containsKey('status_id'), isFalse);
    expect(vm.extraFilters['overdue'], {'true'});
    expect(vm.states, {EntityState.active});

    vm.dispose();
  });

  test('same token is consumed once (no re-apply / no extra fetch)', () async {
    final vm = await makeVm();
    final intent = ListFilterIntent(
      extraFilters: const {
        'overdue': {'true'},
      },
      token: 'dup',
    );

    await vm.applyDeepLinkIntent(intent);
    final countAfterFirst = vm.fetchCount;
    expect(vm.lastConsumedIntentToken, 'dup');

    // Simulate the user removing the chip, then a rebuild re-delivering the
    // same intent — it must NOT clobber the user's change.
    await vm.setExtraFilter(serverKey: 'overdue', values: const {});
    expect(vm.extraFilters['overdue'] ?? const <String>{}, isEmpty);

    await vm.applyDeepLinkIntent(intent);

    expect(vm.extraFilters['overdue'] ?? const <String>{}, isEmpty);
    expect(vm.fetchCount, countAfterFirst + 1); // only the setExtraFilter one

    vm.dispose();
  });

  // ── nav_state watch must not clobber an unpersisted deep-link ──────────

  // A baseline slot equal to a fresh VM's defaults (see currentSnapshot()).
  const baselineJson =
      '{"co":{"invoice":{"search":"","states":["active"],'
      '"sortField":"number","sortAscending":true,'
      '"customFilters":{},"extraFilters":{}}}}';

  Future<_FakeVm> makeSeededVm({
    required String filtersJson,
    Duration persist = const Duration(seconds: 30),
  }) async {
    await db.navStateDao.saveFilters(
      filtersJson: filtersJson,
      now: DateTime.now().millisecondsSinceEpoch,
    );
    final vm = _FakeVm(
      companyId: 'co',
      navStateDao: db.navStateDao,
      userSettings: UserSettingsRepository(db: db),
      searchDebounce: const Duration(milliseconds: 1),
      persistDebounce: persist,
    );
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return vm;
  }

  test(
    'an unrelated nav_state write (route) does not clear a freshly '
    'applied deep-link intent',
    () async {
      // Long persist debounce so the intent stays only in memory.
      final vm = await makeSeededVm(filtersJson: baselineJson);

      await vm.applyDeepLinkIntent(
        ListFilterIntent(
          extraFilters: const {
            'overdue': {'true'},
          },
          token: 'navt1',
        ),
      );
      expect(vm.extraFilters['overdue'], {'true'});

      // Route persister touches the SAME nav_state row → watchCurrent
      // re-emits with the still-old filters_json slot.
      await db.navStateDao.saveRoute(
        route: '/invoices',
        now: DateTime.now().millisecondsSinceEpoch,
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      // The intent must survive (bug: it was reset to the stale slot).
      expect(vm.extraFilters['overdue'], {'true'});
      expect(vm.states, {EntityState.active});

      vm.dispose();
    },
  );

  test(
    'a genuine external slot change (saved-view apply) still re-hydrates',
    () async {
      final vm = await makeSeededVm(filtersJson: baselineJson);
      expect(vm.extraFilters.containsKey('client_status'), isFalse);

      await db.navStateDao.saveFilters(
        filtersJson:
            '{"co":{"invoice":{"search":"","states":["active"],'
            '"sortField":"number","sortAscending":true,'
            '"customFilters":{},"extraFilters":{"client_status":["paid"]}}}}',
        now: DateTime.now().millisecondsSinceEpoch,
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(vm.extraFilters['client_status'], {'paid'});

      vm.dispose();
    },
  );

  test('a fresh token re-applies', () async {
    final vm = await makeVm();

    await vm.applyDeepLinkIntent(
      ListFilterIntent(
        extraFilters: const {
          'client_status': {'expired'},
        },
        token: 'a',
      ),
    );
    expect(vm.extraFilters['client_status'], {'expired'});

    await vm.applyDeepLinkIntent(
      ListFilterIntent(
        extraFilters: const {
          'overdue': {'true'},
        },
        token: 'b',
      ),
    );
    expect(vm.extraFilters.containsKey('client_status'), isFalse);
    expect(vm.extraFilters['overdue'], {'true'});
    expect(vm.lastConsumedIntentToken, 'b');

    vm.dispose();
  });
}
