// Locks down GenericListViewModel.runSelectionAction — the in-flight latch the
// scaffold wraps around EntityListBulkAction.onSelection handlers (bulk PDF
// print/download, "Invoice Project(s)", "Download Documents"). Guarantees:
//   * bulkInFlight is raised for the action's duration and released after
//   * a second call while one is in flight is a no-op (no double-fire)
//   * the selection is NOT cleared (the scaffold owns that, unlike the per-id
//     applyBulkAction path)

import 'dart:async';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Row {
  const _Row(this.id);
  final String id;
}

final _cols = <ColumnDefinition<_Row>>[
  ColumnDefinition(id: 'id', labelKey: 'id', cellBuilder: (r, _) => Text(r.id)),
];

class _Vm extends GenericListViewModel<_Row> {
  _Vm({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
  });

  @override
  EntityType get entityType => EntityType.invoice;
  @override
  List<ColumnDefinition<_Row>> get allColumns => _cols;
  @override
  List<String> get defaultColumnIds => const ['id'];
  @override
  String get defaultSortField => 'id';
  @override
  bool isValidColumnId(String field) => field == 'id';
  @override
  String idOf(_Row item) => item.id;
  @override
  bool isArchived(_Row item) => false;
  @override
  bool isDeleted(_Row item) => false;
  @override
  Stream<List<_Row>> watchPage() => Stream.value(const [_Row('a')]);
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
  Iterable<BulkAction<_Row>> get bulkActions => const [];
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  _Vm build() => _Vm(
    companyId: 'co',
    navStateDao: db.navStateDao,
    userSettings: UserSettingsRepository(db: db),
    searchDebounce: const Duration(milliseconds: 1),
    persistDebounce: const Duration(milliseconds: 1),
  );

  test(
    'raises bulkInFlight for the action duration and releases after',
    () async {
      final vm = build();
      await settle();

      final gate = Completer<void>();
      var sawInFlight = false;
      final future = vm.runSelectionAction(() async {
        sawInFlight = vm.bulkInFlight;
        await gate.future;
      });

      expect(vm.bulkInFlight, isTrue, reason: 'latched synchronously on call');
      gate.complete();
      await future;

      expect(sawInFlight, isTrue, reason: 'flag was set while the action ran');
      expect(vm.bulkInFlight, isFalse, reason: 'released in finally');
      vm.dispose();
    },
  );

  test('a second call while one is in flight is a no-op', () async {
    final vm = build();
    await settle();

    final gate = Completer<void>();
    var firstRan = 0;
    var secondRan = 0;
    final first = vm.runSelectionAction(() async {
      firstRan++;
      await gate.future;
    });
    // Fires while `first` is still awaiting the gate.
    await vm.runSelectionAction(() async => secondRan++);

    expect(secondRan, 0, reason: 'guarded by the in-flight latch');
    gate.complete();
    await first;
    expect(firstRan, 1);
    vm.dispose();
  });

  test('does not clear the selection (scaffold owns that)', () async {
    final vm = build();
    await settle();

    vm.toggleSelected('a');
    await vm.runSelectionAction(() async {});

    expect(vm.isSelected('a'), isTrue);
    vm.dispose();
  });
}
