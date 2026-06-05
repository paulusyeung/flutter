import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/features/credits/widgets/credit_filter_keys.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins `CreditClientStatusFilterKey`: writes the credit status wire labels to
/// `vm.extraFilters['client_status']` (the server-backed
/// `CreditFilters::client_status` param). Unlike quotes there are no computed
/// states — the four labels map 1:1 to `status_id`.

class _FakeVm extends GenericListViewModel<dynamic> {
  _FakeVm({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
  });

  @override
  EntityType get entityType => EntityType.credit;

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

  test('id is "status" and multi-valued', () {
    const key = CreditClientStatusFilterKey();
    expect(key.id, 'status');
    expect(key.singleValue, isFalse);
    expect(key.checkboxMultiSelect, isTrue);
  });

  testWidgets(
    'status options are exactly the four server client_status values — '
    'no "viewed" (display-only computed status, not a server filter)',
    (tester) async {
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
        const key = CreditClientStatusFilterKey();
        final suggestions = await key.watchValueSuggestions(vm, ctx, '').first;
        final rawValues = suggestions.map((s) => s.rawValue).toList();
        expect(rawValues, ['draft', 'sent', 'partial', 'applied']);
        expect(rawValues, isNot(contains('viewed')));
        vm.dispose();
      });
    },
  );

  test('addValue unions into extraFilters[client_status]', () async {
    final vm = await makeVm();
    const key = CreditClientStatusFilterKey();

    expect(key.isAtDefault(vm), isTrue);
    await key.addValue(vm, 'partial');
    expect(vm.extraFilters['client_status'], {'partial'});

    await key.addValue(vm, 'applied');
    expect(vm.extraFilters['client_status'], {'partial', 'applied'});

    await key.removeValue(vm, 'partial');
    expect(vm.extraFilters['client_status'], {'applied'});
    expect(key.isAtDefault(vm), isFalse);

    vm.dispose();
  });

  testWidgets('selectExclusive replaces the set in one write', (tester) async {
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
      const key = CreditClientStatusFilterKey();

      await key.addValue(vm, 'draft');
      await key.addValue(vm, 'sent');
      expect(vm.extraFilters['client_status'], {'draft', 'sent'});

      await key.selectExclusive(vm, ctx, 'applied');
      expect(vm.extraFilters['client_status'], {'applied'});

      await key.clear(vm, ctx);
      expect(vm.extraFilters['client_status'] ?? const <String>{}, isEmpty);

      vm.dispose();
    });
  });
}
