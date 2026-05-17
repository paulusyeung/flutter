import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/date_range_filter_key.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the reusable 2-part `DateRangeFilterKey` (`start,end` →
/// base `QueryFilters::date_range`, used by invoices/quotes).

class _FakeVm extends GenericListViewModel<dynamic> {
  _FakeVm({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
  });

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
  }) async => false;

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

  test('id/serverKey/single-value contract', () {
    const key = DateRangeFilterKey();
    expect(key.id, 'date_range');
    expect(key.singleValue, isTrue);
  });

  test('isValidValue requires a 2-part non-empty start,end', () {
    const key = DateRangeFilterKey();
    expect(key.isValidValue('2026-01-01,2026-12-31'), isTrue);
    // 3-part is tolerated (>=2) — first two parts used.
    expect(key.isValidValue('2026-01-01,2026-12-31,extra'), isTrue);
    expect(key.isValidValue('2026-01-01'), isFalse);
    expect(key.isValidValue(',2026-12-31'), isFalse);
    expect(key.isValidValue('2026-01-01,'), isFalse);
  });

  test('addValue stores a valid window; rejects a 1-part value', () async {
    final vm = await makeVm();
    const key = DateRangeFilterKey();

    await key.addValue(vm, '2026-01-01');
    expect(vm.extraFilters['date_range'] ?? const <String>{}, isEmpty);

    await key.addValue(vm, '2026-01-01,2026-12-31');
    expect(vm.extraFilters['date_range'], {'2026-01-01,2026-12-31'});

    await key.removeValue(vm, '2026-01-01,2026-12-31');
    expect(vm.extraFilters['date_range'] ?? const <String>{}, isEmpty);

    vm.dispose();
  });

  testWidgets('chip shows the start–end window', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      final vm = await makeVm();
      const key = DateRangeFilterKey();
      await key.addValue(vm, '2026-01-01,2026-12-31');
      final tokens = key.tokensFrom(vm, ctx).toList();
      expect(tokens, hasLength(1));
      expect(tokens.single.displayValue, '2026-01-01 – 2026-12-31');
      vm.dispose();
    });
  });
}
