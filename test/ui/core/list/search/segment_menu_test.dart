import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/segment_menu.dart';
import 'package:admin/ui/features/clients/client_filter_keys.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 6: the dedicated per-segment dropdown. The point is that it
/// commits straight through the key (`changeOp` / `addValue`) and never
/// owns or writes a search text controller — so these assert the VM
/// state. Rows are tapped by INDEX (op order is the declared
/// `supportedOps` order; preset order is `kRelativeDatePresets`) so the
/// test is locale-independent and doesn't depend on async l10n load.
class _FakeVm extends GenericListViewModel<dynamic> {
  _FakeVm({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
  });

  int notifications = 0;

  @override
  void notifyListeners() {
    notifications++;
    super.notifyListeners();
  }

  @override
  EntityType get entityType => EntityType.client;
  @override
  List<ColumnDefinition<dynamic>> get allColumns => const [];
  @override
  List<String> get defaultColumnIds => const [];
  @override
  String get defaultSortField => 'name';
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
  }) async => false;
  @override
  Future<void> refreshAll() async {}
  @override
  Iterable<BulkAction<dynamic>> get bulkActions => const [];
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

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

  // No MaterialApp/localization (its async asset load + the VM's debounce
  // timers make pumpAndSettle never idle). A bare themed host is enough —
  // SegmentMenu only needs InTheme, which it reads via context.inTheme
  // (a ThemeExtension wired by the app theme). Splashes disabled so a
  // tap leaves no pending ripple animation at teardown.
  Widget host(Widget child) => MaterialApp(
    theme: buildInTheme(
      InTheme.light,
    ).copyWith(splashFactory: NoSplash.splashFactory),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('comparator: 5 rows, current op checked, tap rewrites the '
      'op only — one VM write, value preserved, closes', (tester) async {
    final vm = await makeVm();
    var closed = false;
    await tester.pumpWidget(
      host(
        SegmentMenu(
          vm: vm,
          filterKey: const CreatedFilterKey(),
          kind: SegmentKind.comparator,
          currentWire: 'gte:2026-01-01',
          onClose: () => closed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    // supportedOps == [gt, gte, lt, lte, eq] → 5 rows; gte (index 1) is
    // the current op and is check-marked.
    expect(find.byType(InkWell), findsNWidgets(5));
    expect(find.byIcon(Icons.check), findsOneWidget);

    final before = vm.notifications;
    // Index 2 == lt ("is before").
    await tester.tap(find.byType(InkWell).at(2));
    await tester.pump(const Duration(milliseconds: 20));

    expect(vm.extraFilters['created_at'], {'lt:2026-01-01'});
    expect(
      vm.notifications - before,
      1,
      reason: 'changeOp must be a single VM write',
    );
    expect(closed, isTrue);
    vm.dispose();
  });

  testWidgets('date value: 5 relative presets + Absolute date; a preset '
      'commits the rolling token keeping the current op', (tester) async {
    final vm = await makeVm();
    await tester.pumpWidget(
      host(
        SegmentMenu(
          vm: vm,
          filterKey: const CreatedFilterKey(),
          kind: SegmentKind.value,
          currentWire: 'lt:2026-01-01',
          onClose: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    // 5 presets + "Absolute date" row.
    expect(find.byType(InkWell), findsNWidgets(6));

    // kRelativeDatePresets[2] == ('rel:d7', '7 days ago').
    await tester.tap(find.byType(InkWell).at(2));
    await tester.pump(const Duration(milliseconds: 20));

    // Value is the rolling token; the op (lt) is preserved.
    expect(vm.extraFilters['created_at'], {'lt:rel:d7'});
    vm.dispose();
  });

  testWidgets('numeric value: prefilled field, Enter commits buildWire '
      'with the current op (no search-field text involved)', (tester) async {
    final vm = await makeVm();
    var closed = false;
    await tester.pumpWidget(
      host(
        SegmentMenu(
          vm: vm,
          filterKey: const BalanceFilterKey(),
          kind: SegmentKind.value,
          currentWire: 'gt:1000',
          onClose: () => closed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(
      tester.widget<TextField>(field).controller!.text,
      '1000',
      reason: 'value segment prefills the bare value',
    );

    await tester.enterText(field, '500');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 20));

    expect(vm.extraFilters['balance'], {'gt:500'});
    expect(closed, isTrue);
    vm.dispose();
  });
}
