import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/features/clients/client_filter_keys.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the checkbox / split-action contract for the state (`is`) filter:
/// it opts in to the checkbox picker and `selectExclusive` collapses the
/// applied set to a single state in one `setStates` write.

class _FakeVm extends GenericListViewModel<dynamic> {
  _FakeVm({
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.searchDebounce,
    super.persistDebounce,
  });

  @override
  EntityType get entityType => EntityType.client;

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

  test('IsFilterKey opts in to the checkbox multi-select picker', () {
    expect(const IsFilterKey().checkboxMultiSelect, isTrue);
  });

  test('a non-opt-in key keeps the default toggle-and-close picker', () {
    expect(const NameFilterKey().checkboxMultiSelect, isFalse);
  });

  testWidgets(
    'selectExclusive collapses {active, archived} to {deleted} in one write',
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

      // Run the VM work in the real async zone: `makeVm`'s delayed loop and
      // the VM's debounced persist timer don't advance under the widget
      // binding's fake clock. `selectExclusive`'s override ignores [ctx].
      await tester.runAsync(() async {
        final vm = await makeVm();
        const key = IsFilterKey();

        await key.addValue(vm, EntityState.archived.serverName);
        expect(
          vm.states,
          containsAll(<EntityState>[EntityState.active, EntityState.archived]),
        );

        await key.selectExclusive(vm, ctx, EntityState.deleted.serverName);
        expect(vm.states, {EntityState.deleted});

        vm.dispose();
      });
    },
  );
}
