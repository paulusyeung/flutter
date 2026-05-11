// Smoke test for `GenericListViewModel<T>`. Confirms the foundation holds:
// a brand-new entity (Invoice here is a fake stand-in) can plug into the
// generic stack with only an entity-specific subclass — no changes to the
// base, the column system, or the filter/sort/multiselect machinery. If
// adding entity #2 requires touching the base, this test fails.
//
// Total entity-specific code measured by line count below; if it grows
// past ~200, the generics aren't pulling their weight.

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
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
  }) async => false;

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
      await vm.clearAllFilters();
      expect(vm.extraFilters, isEmpty);
      expect(vm.hasActiveFilters, isFalse);

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
}
