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

/// Phase 6: the dedicated per-segment dropdown. It commits straight
/// through the key (`changeOp` / `addValue`) and never owns or writes a
/// search text controller — these assert the resulting VM state.
///
/// `GenericListViewModel`'s ctor starts a live Drift `navStateDao`
/// subscription; under `testWidgets`' fake clock that deadlocks
/// ("Cannot add event while adding stream"). So every pump / tap / async
/// key write runs inside `tester.runAsync` (real event loop). Rows are
/// tapped by INDEX (op order = `supportedOps`; preset order =
/// `kRelativeDatePresets`) so the test is locale-independent.
class _FakeVm extends GenericListViewModel<dynamic> {
  _FakeVm({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
  });

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

  _FakeVm makeVm() => _FakeVm(
    companyId: 'co',
    navStateDao: db.navStateDao,
    userSettings: UserSettingsRepository(db: db),
  );

  Widget host(Widget child) => MaterialApp(
    theme: buildInTheme(
      InTheme.light,
    ).copyWith(splashFactory: NoSplash.splashFactory),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('comparator: 5 rows, current op checked, tap rewrites the '
      'op only (value preserved) and closes', (tester) async {
    final vm = makeVm();
    var closed = false;
    await tester.runAsync(() async {
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
      await tester.pump();
    });

    // supportedOps == [gt, gte, lt, lte, eq] → 5 rows; gte (index 1,
    // the current op) is check-marked.
    expect(find.byType(InkWell), findsNWidgets(5));
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byType(InkWell).at(2)); // index 2 == lt
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });

    expect(vm.extraFilters['created_at'], {'lt:2026-01-01'});
    expect(closed, isTrue);
    vm.dispose();
    await tester.runAsync(() async {});
  });

  testWidgets('date value: 5 relative presets + Absolute date; a preset '
      'commits the rolling token keeping the current op', (tester) async {
    final vm = makeVm();
    await tester.runAsync(() async {
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
      await tester.pump();
    });

    expect(find.byType(InkWell), findsNWidgets(6)); // 5 presets + absolute

    await tester.runAsync(() async {
      // kRelativeDatePresets[2] == ('rel:d7', '7 days ago').
      await tester.tap(find.byType(InkWell).at(2));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });

    expect(vm.extraFilters['created_at'], {'lt:rel:d7'});
    vm.dispose();
    await tester.runAsync(() async {});
  });

  testWidgets('numeric value: prefilled field, Enter commits buildWire '
      'with the current op (no search-field text involved)', (tester) async {
    final vm = makeVm();
    var closed = false;
    await tester.runAsync(() async {
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
      await tester.pump();
    });

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(
      tester.widget<TextField>(field).controller!.text,
      '1000',
      reason: 'value segment prefills the bare value',
    );

    await tester.runAsync(() async {
      await tester.enterText(field, '500');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });

    expect(vm.extraFilters['balance'], {'gt:500'});
    expect(closed, isTrue);
    vm.dispose();
    await tester.runAsync(() async {});
  });
}
