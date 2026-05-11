import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/features/clients/client_filter_keys.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../_localization_helper.dart';

/// Verifies the four built-in client filter keys round-trip values through
/// the VM and produce the right chip/suggestion data. We bring up a real
/// `GenericListViewModel` against an in-memory Drift database; mocking the
/// VM would just re-create its base, which is where the writes land.

/// Bare-minimum VM stand-in so we don't need to spin up the full Clients
/// stack just to exercise filter-key state.
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
  Stream<List<String>> watchDistinctCustomValues(int columnIndex) =>
      Stream.value(const ['North', 'South', 'East']);

  @override
  Iterable<BulkAction<dynamic>> get bulkActions => const [];
}

class _FakeStaticsRepository extends StaticsRepository {
  _FakeStaticsRepository({
    required super.db,
    required super.service,
    Map<String, Country>? countries,
  }) : _countries = countries ?? const {};

  final Map<String, Country> _countries;

  @override
  Future<void> ensureLoaded({bool force = false}) async {}

  @override
  Map<String, Country> get countries => _countries;

  @override
  Country? country(String id) => _countries[id];
}

const _kUsa = Country(
  id: '840',
  name: 'United States',
  iso2: 'US',
  iso3: 'USA',
  swapCurrencySymbol: false,
  thousandSeparator: ',',
  decimalSeparator: '.',
  swapPostalCode: false,
);

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
    // Wait for the hydrate cycle so writes don't race against init.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return vm;
  }

  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: kTestLocalizationsDelegates,
    supportedLocales: kTestSupportedLocales,
    home: Material(child: child),
  );

  group('IsFilterKey', () {
    test('is at default when states == {active}', () async {
      final vm = await makeVm();
      const key = IsFilterKey();
      expect(key.isAtDefault(vm), isTrue);
      await vm.setStates({EntityState.archived});
      expect(key.isAtDefault(vm), isFalse);
      vm.dispose();
    });

    test('addValue replaces (single-valued)', () async {
      final vm = await makeVm();
      const key = IsFilterKey();
      await key.addValue(vm, 'archived');
      expect(vm.states, {EntityState.archived});
      await key.addValue(vm, 'deleted');
      expect(vm.states, {
        EntityState.deleted,
      }, reason: 'singleValue keys replace, not append');
      vm.dispose();
    });

    test('removeValue snaps back to default when last value drops', () async {
      final vm = await makeVm();
      const key = IsFilterKey();
      await key.addValue(vm, 'archived');
      await key.removeValue(vm, 'archived');
      expect(vm.states, {
        EntityState.active,
      }, reason: 'empty set snaps to the default so the chip disappears');
      vm.dispose();
    });

    test('cycleValue advances active → archived → deleted → active', () async {
      final vm = await makeVm();
      const key = IsFilterKey();
      final cycler = key.cycleValue(vm)!;
      await cycler();
      expect(vm.states, {EntityState.archived});
      await cycler();
      expect(vm.states, {EntityState.deleted});
      await cycler();
      expect(vm.states, {EntityState.active});
      vm.dispose();
    });
  });

  group('CustomFieldFilterKey', () {
    test('isAvailable false without a configured label', () async {
      final vm = await makeVm();
      const key = CustomFieldFilterKey(columnIndex: 1, configuredLabel: '');
      expect(key.isAvailable(vm), isFalse);
      vm.dispose();
    });

    test('addValue accumulates, removeValue drops', () async {
      final vm = await makeVm();
      const key = CustomFieldFilterKey(
        columnIndex: 1,
        configuredLabel: 'Region',
      );
      await key.addValue(vm, 'North');
      await key.addValue(vm, 'South');
      expect(vm.customFilters[1], {'North', 'South'});
      await key.removeValue(vm, 'North');
      expect(vm.customFilters[1], {'South'});
      vm.dispose();
    });
  });

  group('CountryFilterKey', () {
    test('reads from extraFilters under country_id', () async {
      final vm = await makeVm();
      final key = CountryFilterKey(
        statics: _FakeStaticsRepository(
          db: db,
          service: _FakeStaticsService(),
          countries: const {'840': _kUsa},
        ),
      );
      await key.addValue(vm, '840');
      expect(vm.extraFilters['country_id'], {'840'});
      await key.removeValue(vm, '840');
      expect(vm.extraFilters.containsKey('country_id'), isFalse);
      vm.dispose();
    });

    test(
      'addValue accepts ISO code aliases and resolves to numeric id',
      () async {
        final vm = await makeVm();
        final key = CountryFilterKey(
          statics: _FakeStaticsRepository(
            db: db,
            service: _FakeStaticsService(),
            countries: const {'840': _kUsa},
          ),
        );
        await key.addValue(vm, 'US');
        expect(
          vm.extraFilters['country_id'],
          {'840'},
          reason: 'paste compat: `country:US` resolves through ISO2',
        );
        vm.dispose();
      },
    );
  });

  group('GroupFilterKey', () {
    test('is unavailable (stub) — keeps the key out of the menu', () async {
      final vm = await makeVm();
      const key = GroupFilterKey();
      expect(
        key.isAvailable(vm),
        isFalse,
        reason: 'Groups entity is not wired up yet — opt out of autocomplete',
      );
      vm.dispose();
    });
  });

  group('buildClientFilterKeys', () {
    testWidgets('resolves company custom-field labels', (tester) async {
      late List<String> displayLabels;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              final keys = buildClientFilterKeys(
                company: const Company(
                  id: 'co',
                  name: 'Acme',
                  customFields: {
                    'client1': 'Region|North,South',
                    'client3': 'Project',
                  },
                ),
                statics: _FakeStaticsRepository(
                  db: db,
                  service: _FakeStaticsService(),
                ),
              );
              displayLabels = [for (final k in keys) k.displayLabel(context)];
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // is, custom1..4, country, group → 7 keys; custom1 gets "Region",
      // custom3 gets "Project", others fall through to the generic label.
      expect(displayLabels.length, 7);
      expect(displayLabels[1], 'Region');
      expect(displayLabels[3], 'Project');
    });
  });
}

class _FakeStaticsService implements StaticsService {
  @override
  Future<Map<String, dynamic>> fetch() async => const {};
}
