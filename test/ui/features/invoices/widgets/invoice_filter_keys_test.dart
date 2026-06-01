import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/invoice_status.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_filter_keys.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the wire contract of `InvoiceStatusFilterKey`: writes wire ids
/// `'1'..'6'` to `vm.extraFilters['status_id']`. Computed pseudo-statuses
/// (`-1`, `-2`, `-3`) are intentionally excluded.

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

  test('id is "status" and is multi-valued', () {
    const key = InvoiceStatusFilterKey();
    expect(key.id, 'status');
    expect(key.singleValue, isFalse);
  });

  test('addValue accumulates wire ids in extraFilters[status_id]', () async {
    final vm = await makeVm();
    const key = InvoiceStatusFilterKey();

    await key.addValue(vm, InvoiceStatus.sent.wireId);
    expect(vm.extraFilters['status_id'], {'2'});

    await key.addValue(vm, InvoiceStatus.paid.wireId);
    expect(vm.extraFilters['status_id'], {'2', '4'});

    await key.removeValue(vm, '2');
    expect(vm.extraFilters['status_id'], {'4'});

    vm.dispose();
  });

  test('isAtDefault tracks the filter set', () async {
    final vm = await makeVm();
    const key = InvoiceStatusFilterKey();

    expect(key.isAtDefault(vm), isTrue);
    await key.addValue(vm, '4');
    expect(key.isAtDefault(vm), isFalse);

    vm.dispose();
  });

  test('opts in to the checkbox multi-select picker', () {
    expect(const InvoiceStatusFilterKey().checkboxMultiSelect, isTrue);
  });

  testWidgets('selectExclusive replaces the whole set in one write', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    );

    // Real async zone — see is_filter_key_test for the rationale.
    // `selectExclusive`'s override ignores [ctx].
    await tester.runAsync(() async {
      final vm = await makeVm();
      const key = InvoiceStatusFilterKey();

      await key.addValue(vm, '2');
      await key.addValue(vm, '4');
      expect(vm.extraFilters['status_id'], {'2', '4'});

      await key.selectExclusive(vm, ctx, '6');
      expect(vm.extraFilters['status_id'], {'6'});

      vm.dispose();
    });
  });

  testWidgets('clear empties the status set in one write', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    );

    await tester.runAsync(() async {
      final vm = await makeVm();
      const key = InvoiceStatusFilterKey();

      await key.addValue(vm, '2');
      await key.addValue(vm, '4');
      expect(vm.extraFilters['status_id'], {'2', '4'});

      await key.clear(vm, ctx);
      expect(vm.extraFilters['status_id'] ?? const <String>{}, isEmpty);

      vm.dispose();
    });
  });

  group('InvoiceOverdueFilterKey', () {
    test('id is "overdue" and single-valued', () {
      const key = InvoiceOverdueFilterKey();
      expect(key.id, 'overdue');
      expect(key.singleValue, isTrue);
    });

    test('addValue writes overdue=true and never touches status_id', () async {
      final vm = await makeVm();
      const key = InvoiceOverdueFilterKey();

      expect(key.isAtDefault(vm), isTrue);
      await key.addValue(vm, 'true');
      expect(vm.extraFilters['overdue'], {'true'});
      expect(vm.extraFilters.containsKey('status_id'), isFalse);
      expect(key.isAtDefault(vm), isFalse);

      await key.removeValue(vm, 'true');
      expect(vm.extraFilters['overdue'] ?? const <String>{}, isEmpty);
      expect(key.isAtDefault(vm), isTrue);

      vm.dispose();
    });

    testWidgets('renders one removable chip', (tester) async {
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
        const key = InvoiceOverdueFilterKey();

        expect(key.tokensFrom(vm, ctx), isEmpty);
        await key.addValue(vm, 'true');
        final tokens = key.tokensFrom(vm, ctx).toList();
        expect(tokens, hasLength(1));
        expect(tokens.single.keyId, 'overdue');
        expect(tokens.single.rawValue, 'true');

        await key.clear(vm, ctx);
        expect(key.tokensFrom(vm, ctx), isEmpty);

        vm.dispose();
      });
    });
  });
}
