// Smoke test for `GenericListViewModel<T>`. Confirms the foundation holds:
// a brand-new entity (Invoice here is a fake stand-in) can plug into the
// generic stack with only an entity-specific subclass — no changes to the
// base, the column system, or the filter/sort/multiselect machinery. If
// adding entity #2 requires touching the base, this test fails.
//
// Total entity-specific code measured by line count below; if it grows
// past ~200, the generics aren't pulling their weight.

import 'dart:async';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeInvoice {
  const FakeInvoice({
    required this.id,
    required this.number,
    required this.amount,
    this.archived = false,
    this.deleted = false,
  });

  final String id;
  final String number;
  final double amount;
  final bool archived;
  final bool deleted;
}

final _kAllColumns = <ColumnDefinition<FakeInvoice>>[
  ColumnDefinition(
    id: 'number',
    labelKey: 'number',
    cellBuilder: (i, _) => Text(i.number),
  ),
  ColumnDefinition(
    id: 'amount',
    labelKey: 'amount',
    cellBuilder: (i, _) => Text(i.amount.toString()),
  ),
];

class FakeInvoiceListViewModel extends GenericListViewModel<FakeInvoice> {
  FakeInvoiceListViewModel({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
  });

  final List<FakeInvoice> _stub = const [
    FakeInvoice(id: 'inv_1', number: 'INV-001', amount: 100),
    FakeInvoice(id: 'inv_2', number: 'INV-002', amount: 200, archived: true),
  ];

  int archiveCalls = 0;
  int fetchPageCalls = 0;

  @override
  EntityType get entityType => EntityType.invoice;

  @override
  List<ColumnDefinition<FakeInvoice>> get allColumns => _kAllColumns;

  @override
  List<String> get defaultColumnIds => const ['number', 'amount'];

  @override
  String get defaultSortField => 'number';

  @override
  bool isValidColumnId(String field) => _kAllColumns.any((c) => c.id == field);

  @override
  String idOf(FakeInvoice item) => item.id;

  @override
  bool isArchived(FakeInvoice item) => item.archived;

  @override
  bool isDeleted(FakeInvoice item) => item.deleted;

  @override
  Stream<List<FakeInvoice>> watchPage() => Stream.value(_stub);

  @override
  Future<bool> fetchPage({
    required int page,
    required String? search,
    required Set<EntityState> states,
    required Map<String, Set<String>> extraFilters,
    required bool ignoreCursor,
  }) async {
    fetchPageCalls++;
    return false;
  }

  @override
  Future<void> refreshAll() async {}

  @override
  Stream<List<String>> watchDistinctCustomValues(int columnIndex) =>
      const Stream.empty();

  @override
  Iterable<BulkAction<FakeInvoice>> get bulkActions => [
    BulkAction<FakeInvoice>(
      id: 'archive',
      labelKey: 'archive',
      eligible: (i) => !i.archived && !i.deleted,
      apply: (id) async => archiveCalls++,
    ),
  ];
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'generic stack carries a brand-new entity without touching the base',
    () async {
      final vm = FakeInvoiceListViewModel(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      await settle();

      // Drift watch streamed the stub through the generic _onItems handler.
      expect(vm.items.map((i) => i.id), ['inv_1', 'inv_2']);
      expect(vm.columns.map((c) => c.id), ['number', 'amount']);
      expect(vm.sortField, 'number');
      expect(vm.states, {EntityState.active});

      // Filter mutations work through the base unchanged.
      await vm.setSort(field: 'amount', ascending: false);
      expect(vm.sortField, 'amount');
      expect(vm.sortAscending, isFalse);
      expect(vm.hasActiveFilters, isTrue);

      // Bulk action declared in the registry is callable through the base.
      vm.toggleSelected('inv_1');
      vm.toggleSelected('inv_2');
      final result = await vm.applyBulkAction(vm.bulkActionById('archive')!);
      expect(result.ok, 1, reason: 'inv_1 is eligible, inv_2 already archived');
      expect(result.skipped, 1);
      expect(vm.archiveCalls, 1);
      expect(vm.isInMultiselect, isFalse, reason: 'selection cleared on exit');

      vm.dispose();
    },
  );

  test(
    'countEligibleSelected counts only selected, loaded, eligible rows',
    () async {
      final vm = FakeInvoiceListViewModel(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      await settle();
      final archive = vm.bulkActionById('archive')!;

      // Nothing selected → 0 (the scaffold short-circuits the prep dialog).
      expect(vm.countEligibleSelected(archive), 0);

      // inv_2 is already archived → ineligible for 'archive'.
      vm.toggleSelected('inv_2');
      expect(vm.countEligibleSelected(archive), 0);

      // inv_1 is active → the only eligible one in the selection.
      vm.toggleSelected('inv_1');
      expect(vm.countEligibleSelected(archive), 1);

      // An id outside the loaded window isn't counted.
      vm.toggleSelected('inv_999');
      expect(vm.countEligibleSelected(archive), 1);

      vm.dispose();
    },
  );

  test('persisted filter blob is keyed by entity type', () async {
    final vm = FakeInvoiceListViewModel(
      companyId: 'co',
      navStateDao: db.navStateDao,
      userSettings: UserSettingsRepository(db: db),
      searchDebounce: const Duration(milliseconds: 1),
      persistDebounce: const Duration(milliseconds: 1),
    );
    await settle();
    await vm.setStates({EntityState.archived});
    // Past the persist debounce.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await settle();
    vm.dispose();

    final row = await db.navStateDao.current();
    expect(row?.filtersJson, isNotNull);
    expect(
      row!.filtersJson!.contains('"invoice"'),
      isTrue,
      reason: 'persisted under EntityType.invoice.name, not "client"',
    );
    expect(
      row.filtersJson!.contains('"client"'),
      isFalse,
      reason: 'invoice and client occupy separate sub-keys',
    );
  });

  test(
    'extraFilters flow through hasActiveFilters and clearAllFilters',
    () async {
      final vm = FakeInvoiceListViewModel(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      await settle();
      expect(vm.hasActiveFilters, isFalse);

      await vm.setExtraFilter(serverKey: 'country_id', values: {'840'});
      expect(vm.hasActiveFilters, isTrue);
      expect(vm.extraFilters['country_id'], {'840'});

      // Empty set removes the entry entirely so the API call drops the key.
      await vm.setExtraFilter(serverKey: 'country_id', values: const {});
      expect(vm.extraFilters.containsKey('country_id'), isFalse);

      await vm.setExtraFilter(serverKey: 'country_id', values: {'840'});
      await vm.setStates({EntityState.archived});
      await vm.clearAllFilters();
      expect(vm.extraFilters, isEmpty);
      // Clear drops the state dimension entirely — no residual
      // `{active}` reset, so the token field emits no `State` chip.
      expect(vm.states, isEmpty);
      expect(vm.hasActiveFilters, isFalse);

      // Regression: a *second* clear when the only thing set is
      // `{active}` — `hasActiveFilters` reports false for `{active}`, so
      // the old `if (!wasActive) return;` early-return made this clear a
      // silent no-op and the `State: Active` chip never cleared.
      await vm.setStates({EntityState.active});
      expect(vm.states, {EntityState.active});
      expect(vm.hasActiveFilters, isFalse);
      await vm.clearAllFilters();
      expect(vm.states, isEmpty);

      vm.dispose();
    },
  );

  test('extraFilters persist + rehydrate across VM lifecycles', () async {
    final settings = UserSettingsRepository(db: db);
    final vm1 = FakeInvoiceListViewModel(
      companyId: 'co',
      navStateDao: db.navStateDao,
      userSettings: settings,
      searchDebounce: const Duration(milliseconds: 1),
      persistDebounce: const Duration(milliseconds: 1),
    );
    await settle();
    await vm1.setExtraFilter(serverKey: 'country_id', values: {'840', '124'});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await settle();
    vm1.dispose();

    final vm2 = FakeInvoiceListViewModel(
      companyId: 'co',
      navStateDao: db.navStateDao,
      userSettings: settings,
      searchDebounce: const Duration(milliseconds: 1),
      persistDebounce: const Duration(milliseconds: 1),
    );
    await settle();
    expect(vm2.extraFilters['country_id'], {'840', '124'});
    vm2.dispose();
  });

  test(
    'v1 filter blob (no extraFilters field) hydrates without errors',
    () async {
      // Simulate a saved blob from before `extraFilters` existed: only
      // states + sortField. The base VM must read it as-is, defaulting
      // `_extraFilters` to {} so existing users don't lose their filters.
      final priorBlob =
          '{"co":{"invoice":{"search":"acme","states":["archived"],'
          '"sortField":"number","sortAscending":false,'
          '"customFilters":{}}}}';
      await db.navStateDao.saveFilters(
        filtersJson: priorBlob,
        now: DateTime.now().millisecondsSinceEpoch,
      );

      final vm = FakeInvoiceListViewModel(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      await settle();
      expect(vm.search, 'acme');
      expect(vm.states, {EntityState.archived});
      expect(vm.sortField, 'number');
      expect(vm.sortAscending, isFalse);
      expect(vm.extraFilters, isEmpty);
      vm.dispose();
    },
  );

  test(
    'savedViewSnapshot omits columnIds on default, includes them once '
    'the user customizes',
    () async {
      final vm = FakeInvoiceListViewModel(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      await settle();
      // On the registry default (no stored preference) the view carries no
      // column override — otherwise applying it would force the default into
      // user_settings and queue a no-op PUT (the reported outbox bug).
      expect(
        vm.savedViewSnapshot().containsKey('columnIds'),
        isFalse,
        reason: 'no column override while on the default layout',
      );
      // Seed the user_settings row so setColumns isn't a silent no-op.
      await db.userSettingsDao.upsert(
        UserSettingsCompanion(
          companyId: const Value('co'),
          userId: const Value('user1'),
          tableColumnsJson: const Value('{}'),
          extraJson: const Value('{}'),
          updatedAt: const Value(0),
        ),
      );
      await vm.setColumns(['amount']);
      await settle();
      expect(
        vm.savedViewSnapshot()['columnIds'],
        equals(['amount']),
        reason: "reflects the user's explicit column-picker choice",
      );
      // currentSnapshot() must NOT carry columnIds — nav_state stays compact.
      expect(vm.currentSnapshot().containsKey('columnIds'), isFalse);

      // Reset back to the default → the override drops out again.
      await vm.resetColumns();
      await settle();
      expect(
        vm.savedViewSnapshot().containsKey('columnIds'),
        isFalse,
        reason: 'resetColumns clears the customization flag',
      );
      vm.dispose();
    },
  );

  test('applySnapshot resets all six fields before applying', () async {
    final vm = FakeInvoiceListViewModel(
      companyId: 'co',
      navStateDao: db.navStateDao,
      userSettings: UserSettingsRepository(db: db),
      searchDebounce: const Duration(milliseconds: 1),
      persistDebounce: const Duration(milliseconds: 1),
    );
    await settle();
    // Pre-load the VM with non-empty extraFilters + non-default sort —
    // these must be cleared by applySnapshot, not merged.
    await vm.setExtraFilter(serverKey: 'country_id', values: {'US'});
    await vm.setSort(field: 'amount', ascending: false);
    expect(vm.extraFilters['country_id'], {'US'});
    expect(vm.sortField, 'amount');

    // Apply a snapshot that omits extraFilters and reverts sort.
    await vm.applySnapshot({
      'search': 'acme',
      'states': ['archived'],
      'sortField': 'number',
      'sortAscending': true,
    });
    expect(vm.search, 'acme');
    expect(vm.states, {EntityState.archived});
    expect(vm.sortField, 'number');
    expect(vm.sortAscending, isTrue);
    // Critical: extraFilters from before is wiped, not retained.
    expect(vm.extraFilters, isEmpty);
    vm.dispose();
  });

  test(
    'rehydrate from disk + own-write persist cycle stabilizes within one '
    'fetch (locks down snapshot equality against future key reordering)',
    () async {
      await db.navStateDao.saveFilters(
        filtersJson:
            '{"co":{"invoice":{"search":"acme","states":["archived"],'
            '"sortField":"number","sortAscending":false,'
            '"customFilters":{},"extraFilters":{"country_id":["US"]}}}}',
        now: 0,
      );
      final vm = FakeInvoiceListViewModel(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      await settle();
      // Wait past the persist debounce; a spurious watchCurrent re-apply
      // (key-order regression) would echo back as another fetchPage.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await settle();
      expect(
        vm.fetchPageCalls,
        1,
        reason:
            'exactly one initial fetch — if currentSnapshot() ever reorders '
            'keys vs the persisted slot, DeepCollectionEquality would '
            'diverge and the listener would re-apply, bumping this counter',
      );
      vm.dispose();
    },
  );

  test('user filter change made during the hydrate→first-emission window '
      'survives the listener', () async {
    // Pre-seed nav_state so hydrate has content to read; the slot's
    // extraFilters omit country_id.
    await db.navStateDao.saveFilters(
      filtersJson:
          '{"co":{"invoice":{"search":"","states":["active"],'
          '"sortField":"number","sortAscending":true,'
          '"customFilters":{},"extraFilters":{}}}}',
      now: 0,
    );
    final vm = FakeInvoiceListViewModel(
      companyId: 'co',
      navStateDao: db.navStateDao,
      userSettings: UserSettingsRepository(db: db),
      searchDebounce: const Duration(milliseconds: 1),
      persistDebounce: const Duration(milliseconds: 1),
    );
    // Race the listener: mutate before settle. This synchronously kicks
    // off _resetAndReload + a debounced persist; the first watchCurrent
    // emission is still in flight and would otherwise overwrite us.
    // Yield once so _hydrate completes (it's awaited inside _init).
    await Future<void>.delayed(Duration.zero);
    unawaited(vm.setExtraFilter(serverKey: 'country_id', values: {'US', 'CA'}));
    // Now let everything settle past the persist debounce.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await settle();
    expect(
      vm.extraFilters['country_id'],
      {'US', 'CA'},
      reason:
          "user's mid-init mutation must not be overwritten by the first "
          'watchCurrent emission echoing the pre-edit slot back at us',
    );
    vm.dispose();
  });

  test(
    'nav_state listener does not feedback-loop on the VM\'s own persist',
    () async {
      final vm = FakeInvoiceListViewModel(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      await settle();
      final initialFetches = vm.fetchPageCalls;
      // Mutate state so the VM persists. The persist will write
      // nav_state.filters_json, which fires the watchCurrent listener — but
      // the slot will match currentSnapshot and the listener must skip.
      await vm.setExtraFilter(serverKey: 'country_id', values: {'US'});
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await settle();
      // Exactly one extra fetch (the setExtraFilter -> _resetAndReload path).
      // No second fetch from the watchCurrent listener echoing our own
      // persist back at us.
      expect(vm.fetchPageCalls, initialFetches + 1);
      vm.dispose();
    },
  );

  test(
    'transformPage override filters items before they reach the view',
    () async {
      final vm = _UnpaidOnlyInvoiceListViewModel(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      await settle();
      // The fake stub has inv_1 (amount=100) and inv_2 (amount=200, archived).
      // The override drops anything with amount < 150 — exercises the hook
      // wiring without depending on entity-specific semantics.
      expect(
        vm.items.map((i) => i.id),
        ['inv_2'],
        reason: 'transformPage(raw) wrapped watchPage() before _onItems ran',
      );
      vm.dispose();
    },
  );

  test(
    'empty `_states` is treated as "no status filter" in hasActiveFilters',
    () async {
      final vm = FakeInvoiceListViewModel(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      await settle();

      // Default `{active}` reports no active filter.
      expect(vm.hasActiveFilters, isFalse);

      // Clearing to `{}` (user removed the only status chip) is also
      // "no filter" — both states drop the lifecycle `status` query param.
      await vm.setStates(const <EntityState>{});
      expect(
        vm.hasActiveFilters,
        isFalse,
        reason:
            'empty set means "show all"; equivalent to the default `{active}` '
            'from a hasActiveFilters perspective so the empty-state copy '
            'reads "no clients yet", not "no matches".',
      );
      vm.dispose();
    },
  );
}

/// Exercises the `transformPage` hook: drops invoices with `amount < 150` so
/// only `inv_2` makes it to the view. Stand-in for a real "unpaid invoices"
/// derived filter that the server doesn't expose as an `extraFilters` key.
class _UnpaidOnlyInvoiceListViewModel extends FakeInvoiceListViewModel {
  _UnpaidOnlyInvoiceListViewModel({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
  });

  @override
  Stream<List<FakeInvoice>> transformPage(Stream<List<FakeInvoice>> raw) =>
      raw.map((items) => items.where((i) => i.amount >= 150).toList());
}
