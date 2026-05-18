import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/features/payments/widgets/payment_filter_keys.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins `PaymentStatusFilterKey` (`client_status`) and
/// `PaymentDateRangeFilterKey` (emits the canonical 3-part
/// `date,<start>,<end>` `date_range` wire; legacy 2-part still parses) — used
/// by the "Paid this month" KPI deep-link.

class _FakeVm extends GenericListViewModel<dynamic> {
  _FakeVm({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
  });

  @override
  EntityType get entityType => EntityType.payment;

  @override
  List<ColumnDefinition<dynamic>> get allColumns => const [];

  @override
  List<String> get defaultColumnIds => const [];

  @override
  String get defaultSortField => 'date';

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

  group('PaymentStatusFilterKey', () {
    test('writes to extraFilters[client_status]', () async {
      final vm = await makeVm();
      const key = PaymentStatusFilterKey();

      expect(key.isAtDefault(vm), isTrue);
      await key.addValue(vm, 'completed');
      expect(vm.extraFilters['client_status'], {'completed'});

      await key.addValue(vm, 'refunded');
      expect(vm.extraFilters['client_status'], {'completed', 'refunded'});
      expect(key.isAtDefault(vm), isFalse);

      vm.dispose();
    });
  });

  group('PaymentDateRangeFilterKey', () {
    test('id is "date_range" and single-valued', () {
      const key = PaymentDateRangeFilterKey();
      expect(key.id, 'date_range');
      expect(key.singleValue, isTrue);
    });

    test('isValidValue accepts canonical 3-part and legacy 2-part; '
        'rejects fewer parts or empty bounds', () {
      const key = PaymentDateRangeFilterKey();
      expect(key.isValidValue('this_month,2026-05-01,2026-05-31'), isTrue);
      // Legacy 2-part still parses — the backend honours it for a
      // deprecation cycle and a pre-upgrade persisted value may hold one.
      expect(key.isValidValue('2026-05-01,2026-05-31'), isTrue);
      expect(key.isValidValue('2026-05-01'), isFalse);
      expect(key.isValidValue('custom,,'), isFalse);
    });

    test('addValue normalizes any valid range to the canonical '
        'date,<start>,<end> wire', () async {
      final vm = await makeVm();
      const key = PaymentDateRangeFilterKey();

      // A 1-part value is invalid and no-ops.
      await key.addValue(vm, '2026-05-01');
      expect(vm.extraFilters['date_range'] ?? const <String>{}, isEmpty);

      // Legacy 2-part is accepted and normalized to canonical 3-part.
      await key.addValue(vm, '2026-05-01,2026-05-31');
      expect(vm.extraFilters['date_range'], {'date,2026-05-01,2026-05-31'});

      // A 3-part value with a non-`date` column prefix is normalized too —
      // the column is always forced to `date`.
      await key.addValue(vm, 'this_month,2026-05-01,2026-05-31');
      expect(vm.extraFilters['date_range'], {'date,2026-05-01,2026-05-31'});

      await key.removeValue(vm, 'date,2026-05-01,2026-05-31');
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
        const key = PaymentDateRangeFilterKey();

        await key.addValue(vm, 'this_month,2026-05-01,2026-05-31');
        final tokens = key.tokensFrom(vm, ctx).toList();
        expect(tokens, hasLength(1));
        expect(tokens.single.displayValue, '2026-05-01 – 2026-05-31');

        vm.dispose();
      });
    });
  });
}
