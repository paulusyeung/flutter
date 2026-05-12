import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/industry.dart';
import 'package:admin/data/models/value/language.dart';
import 'package:admin/data/models/value/size.dart';
import 'package:decimal/decimal.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/token_search_controller.dart';
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

  /// Synchronous override so widget tests can exercise
  /// `CustomFieldFilterKey.quickValueSuggestions` without waiting for the
  /// base VM's stream-subscription cache to populate (the subscription
  /// uses `Stream.value`, which fires asynchronously on the microtask
  /// queue — `testWidgets`'s fake clock doesn't drain that reliably).
  @override
  List<String> distinctCustomValues(int columnIndex) => const [
    'North',
    'South',
    'East',
  ];

  @override
  Iterable<BulkAction<dynamic>> get bulkActions => const [];
}

class _FakeStaticsRepository extends StaticsRepository {
  _FakeStaticsRepository({
    required super.db,
    required super.service,
    Map<String, Country>? countries,
    Map<String, Industry>? industries,
    Map<String, Size>? sizes,
    Map<String, Currency>? currencies,
    Map<String, Language>? languages,
  }) : _countries = countries ?? const {},
       _industries = industries ?? const {},
       _sizes = sizes ?? const {},
       _currencies = currencies ?? const {},
       _languages = languages ?? const {};

  final Map<String, Country> _countries;
  final Map<String, Industry> _industries;
  final Map<String, Size> _sizes;
  final Map<String, Currency> _currencies;
  final Map<String, Language> _languages;

  @override
  Future<void> ensureLoaded({bool force = false}) async {}

  @override
  Map<String, Country> get countries => _countries;

  @override
  Country? country(String id) => _countries[id];

  @override
  Map<String, Industry> get industries => _industries;

  @override
  Industry? industry(String id) => _industries[id];

  @override
  Map<String, Size> get sizes => _sizes;

  @override
  Size? size(String id) => _sizes[id];

  @override
  Map<String, Currency> get currencies => _currencies;

  @override
  Currency? currency(String id) => _currencies[id];

  @override
  Map<String, Language> get languages => _languages;

  @override
  Language? language(String id) => _languages[id];
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

    test('addValue always unions (Sentry-style accumulate)', () async {
      final vm = await makeVm();
      const key = IsFilterKey();
      // From default `{active}`, picking Archived unions — both chips
      // remain visible. The user can `×` the active one if they want.
      await key.addValue(vm, 'archived');
      expect(vm.states, {EntityState.active, EntityState.archived});
      await key.addValue(vm, 'deleted');
      expect(vm.states, {
        EntityState.active,
        EntityState.archived,
        EntityState.deleted,
      });
      vm.dispose();
    });

    test('removeValue keeps the rest when one of many drops', () async {
      final vm = await makeVm();
      const key = IsFilterKey();
      await vm.setStates({EntityState.archived, EntityState.deleted});
      await key.removeValue(vm, 'archived');
      expect(vm.states, {EntityState.deleted});
      vm.dispose();
    });

    test('removeValue allows an empty state set — chip disappears', () async {
      final vm = await makeVm();
      const key = IsFilterKey();
      // Default `{active}`. Removing the only chip clears entirely.
      await key.removeValue(vm, 'active');
      expect(
        vm.states,
        isEmpty,
        reason: 'empty set means "no status restriction"; user sees all rows',
      );
      vm.dispose();
    });

    test('cycleValue returns null — chip tap opens the value picker', () async {
      final vm = await makeVm();
      const key = IsFilterKey();
      // Falling back to the base class default means `_onChipTap` routes
      // to the "open value picker" branch instead of cycling silently.
      expect(key.cycleValue(vm), isNull);
      vm.dispose();
    });
  });

  group('CustomFieldFilterKey', () {
    test('isAvailable=false even with a configured label — server '
        'ignores custom_value1..4 (May 2026 measurement)', () async {
      final vm = await makeVm();
      const empty = CustomFieldFilterKey(columnIndex: 1, configuredLabel: '');
      const configured = CustomFieldFilterKey(
        columnIndex: 1,
        configuredLabel: 'Region',
      );
      expect(empty.isAvailable(vm), isFalse);
      expect(configured.isAvailable(vm), isFalse);
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

    testWidgets(
      'dropdown-click path: TokenSearchController.selectValue commits the '
      'value and tokensFrom emits the chip',
      (tester) async {
        // Reproduces the user-visible flow: user picks `custom1:` from the
        // Add Filter menu, the value dropdown streams cached values, the
        // user clicks one. The menu wiring funnels every value tap through
        // `TokenSearchController.selectValue` — exercising it here pins
        // any regression in the dropdown-click pipeline (closure capture,
        // setSearch race, applied-state check) to a unit test.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        const key = CustomFieldFilterKey(
          columnIndex: 1,
          configuredLabel: 'Region',
        );
        final controller = TokenSearchController(
          vm: vm,
          filterKeys: const [key],
          initialText: '',
        );
        addTearDown(controller.dispose);

        late BuildContext capturedContext;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        await controller.selectValue(
          key,
          const FilterValueSuggestion(rawValue: 'North', displayLabel: 'North'),
          capturedContext,
        );

        expect(vm.customFilters[1], {'North'});
        final chips = key.tokensFrom(vm, capturedContext).toList();
        expect(chips, hasLength(1));
        expect(chips.single.rawValue, 'North');
        expect(chips.single.displayKey, 'Region');
        // Let the persist + search debounce timers fire so the test
        // framework's pending-timer guard is satisfied.
        await tester.pump(const Duration(milliseconds: 10));
      },
    );

    testWidgets(
      'TokenSearchController.filterKeys can be swapped: an empty-label key '
      'emits no chip, but reassigning a configured-label key surfaces one — '
      'guards the stale-keys race in `TokenSearchField.didUpdateWidget`',
      (tester) async {
        // Reproduces the user-visible bug: when the StreamBuilder<Company?>
        // wrapping the search field first builds with `company == null`,
        // `buildClientFilterKeys` produces `CustomFieldFilterKey`s with
        // empty `configuredLabel`s. The Company stream then emits and the
        // host hands the field a fresh keys list with labels populated. If
        // the controller doesn't sync, chip rendering keeps consulting the
        // stale empty-label key and `tokensFrom` short-circuits, so the
        // filter applies but the pill never paints.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        // Stage 1: configure the filter via the FRESH key (mirrors the
        // picker's path — it reads `widget.filterKeys`, not the
        // controller's). The value lands in `vm.customFilters[1]`.
        await const CustomFieldFilterKey(
          columnIndex: 1,
          configuredLabel: 'Region',
        ).addValue(vm, 'North');
        expect(vm.customFilters[1], {'North'});

        // Stage 2: controller initialised with the STALE keys (empty
        // label) — the chip query should return nothing because
        // `tokensFrom` short-circuits.
        final controller = TokenSearchController(
          vm: vm,
          filterKeys: const [
            CustomFieldFilterKey(columnIndex: 1, configuredLabel: ''),
          ],
          initialText: '',
        );
        addTearDown(controller.dispose);

        late int staleCount;
        late int freshCount;
        late FilterToken freshChip;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                staleCount = controller.activeTokens(context).length;
                // Stage 3: the host's didUpdateWidget would now sync the
                // controller with the fresh keys. Same call here.
                controller.filterKeys = const [
                  CustomFieldFilterKey(
                    columnIndex: 1,
                    configuredLabel: 'Region',
                  ),
                ];
                final tokens = controller.activeTokens(context);
                freshCount = tokens.length;
                if (tokens.isNotEmpty) freshChip = tokens.first;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(staleCount, 0); // bug reproduces with stale keys
        expect(freshCount, 1); // fix surfaces the chip after the swap
        expect(freshChip.rawValue, 'North');
        expect(freshChip.displayKey, 'Region');
        // Also let the pending VM timer (scheduled by setCustomFilter →
        // _resetAndReload → _schedulePersist) settle so the test
        // framework's pending-timer guard doesn't fire.
        await tester.pump(const Duration(milliseconds: 10));
      },
    );

    testWidgets('tokensFrom returns empty when the label is un-configured — '
        'guards against orphan chips painting after a label is removed', (
      tester,
    ) async {
      // The empty-label gate in `tokensFrom` short-circuits before the
      // vm is read, so any vm satisfies the call signature. We construct
      // `_FakeVm` directly (skipping `makeVm`'s hydrate-await loop,
      // which doesn't settle inside `testWidgets`'s fake-time clock).
      final vm = _FakeVm(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      addTearDown(vm.dispose);
      late int unconfiguredCount;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              unconfiguredCount = const CustomFieldFilterKey(
                columnIndex: 1,
                configuredLabel: '',
              ).tokensFrom(vm, context).length;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(unconfiguredCount, 0);
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

    test(
      'isAvailable=false — server ignores country_id (May 2026 measurement)',
      () async {
        final vm = await makeVm();
        final key = CountryFilterKey(
          statics: _FakeStaticsRepository(
            db: db,
            service: _FakeStaticsService(),
          ),
        );
        expect(key.isAvailable(vm), isFalse);
        vm.dispose();
      },
    );
  });

  group('IndustryFilterKey', () {
    test('reads from extraFilters under industry_id', () async {
      final vm = await makeVm();
      final key = IndustryFilterKey(
        statics: _FakeStaticsRepository(
          db: db,
          service: _FakeStaticsService(),
          industries: const {'5': Industry(id: '5', name: 'Software')},
        ),
      );
      await key.addValue(vm, '5');
      expect(vm.extraFilters['industry_id'], {'5'});
      await key.removeValue(vm, '5');
      expect(vm.extraFilters.containsKey('industry_id'), isFalse);
      vm.dispose();
    });

    test(
      'isAvailable=false — server ignores industry_id (May 2026 measurement)',
      () async {
        final vm = await makeVm();
        final key = IndustryFilterKey(
          statics: _FakeStaticsRepository(
            db: db,
            service: _FakeStaticsService(),
          ),
        );
        expect(key.isAvailable(vm), isFalse);
        vm.dispose();
      },
    );
  });

  group('SizeFilterKey', () {
    test('reads from extraFilters under size_id', () async {
      final vm = await makeVm();
      final key = SizeFilterKey(
        statics: _FakeStaticsRepository(
          db: db,
          service: _FakeStaticsService(),
          sizes: const {'2': Size(id: '2', name: '4 - 10')},
        ),
      );
      await key.addValue(vm, '2');
      expect(vm.extraFilters['size_id'], {'2'});
      await key.removeValue(vm, '2');
      expect(vm.extraFilters.containsKey('size_id'), isFalse);
      vm.dispose();
    });
  });

  group('AssignedFilterKey', () {
    test('is unavailable (stub) — opt out until Users entity ships', () async {
      final vm = await makeVm();
      const key = AssignedFilterKey();
      expect(key.isAvailable(vm), isFalse);
      vm.dispose();
    });
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

  group('NameFilterKey', () {
    test(
      'addValue stores the raw value (no wildcard) — server does LIKE',
      () async {
        final vm = await makeVm();
        const key = NameFilterKey();
        await key.addValue(vm, 'tes');
        expect(
          vm.extraFilters['name'],
          {'tes'},
          reason:
              'Server matches via SQL LIKE %value%; a literal `*` would '
              'make the filter return 0 rows.',
        );
        // singleValue: re-adding replaces, not unions.
        await key.addValue(vm, 'bob');
        expect(vm.extraFilters['name'], {'bob'});
        await key.removeValue(vm, 'bob');
        expect(vm.extraFilters.containsKey('name'), isFalse);
        vm.dispose();
      },
    );

    test('addValue trims whitespace and rejects empty input', () async {
      final vm = await makeVm();
      const key = NameFilterKey();
      await key.addValue(vm, '  spaced  ');
      expect(vm.extraFilters['name'], {'spaced'});
      await key.addValue(vm, '   ');
      // Empty-after-trim should not overwrite the existing value.
      expect(vm.extraFilters['name'], {'spaced'});
      vm.dispose();
    });

    testWidgets('hintForValueMode returns a non-null localized hint', (
      tester,
    ) async {
      String? hint;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              hint = const NameFilterKey().hintForValueMode(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(hint, isNotNull);
      expect(hint, isNot(''));
    });
  });

  group('FilterFilterKey', () {
    test('addValue stores the value under server param `filter` and '
        'singleValue replaces on subsequent adds', () async {
      final vm = await makeVm();
      const key = FilterFilterKey();
      await key.addValue(vm, 'acme');
      expect(vm.extraFilters['filter'], {'acme'});
      await key.addValue(vm, 'bob');
      expect(vm.extraFilters['filter'], {'bob'});
      await key.removeValue(vm, 'bob');
      expect(vm.extraFilters.containsKey('filter'), isFalse);
      vm.dispose();
    });

    test('addValue trims whitespace and rejects empty input', () async {
      final vm = await makeVm();
      const key = FilterFilterKey();
      await key.addValue(vm, '  spaced  ');
      expect(vm.extraFilters['filter'], {'spaced'});
      await key.addValue(vm, '   ');
      expect(vm.extraFilters['filter'], {'spaced'});
      vm.dispose();
    });
  });

  group('EmailFilterKey', () {
    test('addValue stores the value under server param `email` and '
        'singleValue replaces on subsequent adds', () async {
      final vm = await makeVm();
      const key = EmailFilterKey();
      await key.addValue(vm, '@gmail.com');
      expect(vm.extraFilters['email'], {'@gmail.com'});
      await key.addValue(vm, 'foo@bar.io');
      expect(vm.extraFilters['email'], {'foo@bar.io'});
      await key.removeValue(vm, 'foo@bar.io');
      expect(vm.extraFilters.containsKey('email'), isFalse);
      vm.dispose();
    });
  });

  group('NumberFilterKey', () {
    test('addValue stores the value under server param `number` and '
        'singleValue replaces on subsequent adds', () async {
      final vm = await makeVm();
      const key = NumberFilterKey();
      await key.addValue(vm, '1234');
      expect(vm.extraFilters['number'], {'1234'});
      await key.addValue(vm, '9999');
      expect(vm.extraFilters['number'], {'9999'});
      await key.removeValue(vm, '9999');
      expect(vm.extraFilters.containsKey('number'), isFalse);
      vm.dispose();
    });

    testWidgets('chip renders as `= "value"` — exact-match shape', (
      tester,
    ) async {
      // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
      // uses `Future.delayed(Duration.zero)`, which never settles inside
      // `testWidgets`'s fake-time clock.
      final vm = _FakeVm(
        companyId: 'co',
        navStateDao: db.navStateDao,
        userSettings: UserSettingsRepository(db: db),
        searchDebounce: const Duration(milliseconds: 1),
        persistDebounce: const Duration(milliseconds: 1),
      );
      addTearDown(vm.dispose);
      const key = NumberFilterKey();
      await key.addValue(vm, '1234');
      late List<FilterToken> tokens;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              tokens = key.tokensFrom(vm, context).toList();
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(tokens, hasLength(1));
      expect(tokens.single.displayValue, '= "1234"');
      // Let the persist + search debounce timers fire so the test
      // framework's pending-timer guard is satisfied.
      await tester.pump(const Duration(milliseconds: 10));
    });
  });

  group('server-ignored keys are hidden from the menu', () {
    // Every key whose server param empirically did not narrow the
    // result set on demo.invoiceninja.com (May 2026 probe) opts out of
    // the suggestion menu via `isAvailable => false`. Re-enable by
    // flipping the override once the v5 API adds support.
    test('all flipped filter keys report isAvailable=false', () async {
      final vm = await makeVm();
      final fakeStatics = _FakeStaticsRepository(
        db: db,
        service: _FakeStaticsService(),
      );
      final entries = <(String, bool)>[
        ('country', CountryFilterKey(statics: fakeStatics).isAvailable(vm)),
        ('industry', IndustryFilterKey(statics: fakeStatics).isAvailable(vm)),
        ('size', SizeFilterKey(statics: fakeStatics).isAvailable(vm)),
        ('currency', CurrencyFilterKey(statics: fakeStatics).isAvailable(vm)),
        ('language', LanguageFilterKey(statics: fakeStatics).isAvailable(vm)),
        ('vat', const VatFilterKey().isAvailable(vm)),
        ('classification', const ClassificationFilterKey().isAvailable(vm)),
        ('created', const CreatedFilterKey().isAvailable(vm)),
        ('updated', const UpdatedFilterKey().isAvailable(vm)),
        (
          'custom1 with label',
          const CustomFieldFilterKey(
            columnIndex: 1,
            configuredLabel: 'Region',
          ).isAvailable(vm),
        ),
      ];
      for (final (name, available) in entries) {
        expect(available, isFalse, reason: '$name should be unavailable');
      }
      vm.dispose();
    });
  });

  group('BalanceFilterKey', () {
    test('addValue writes suffix wire `value:gt` by default — server expects '
        'suffix syntax, prefix `gt:value` is a degenerate no-op', () async {
      final vm = await makeVm();
      const key = BalanceFilterKey();
      await key.addValue(vm, '1000');
      expect(vm.extraFilters['balance'], {'1000:gt'});
      vm.dispose();
    });

    test('addValue accepts explicit `value:lt` shorthand', () async {
      final vm = await makeVm();
      const key = BalanceFilterKey();
      await key.addValue(vm, '1000:lt');
      expect(vm.extraFilters['balance'], {'1000:lt'});
      // singleValue: a new operator replaces the previous one.
      await key.addValue(vm, '500:gt');
      expect(vm.extraFilters['balance'], {'500:gt'});
      vm.dispose();
    });

    test('addValue trims whitespace and rejects empty', () async {
      final vm = await makeVm();
      const key = BalanceFilterKey();
      await key.addValue(vm, '   ');
      expect(vm.extraFilters.containsKey('balance'), isFalse);
      await key.addValue(vm, '  100  ');
      expect(vm.extraFilters['balance'], {'100:gt'});
      vm.dispose();
    });

    test('supportedOps exposes both gt and lt', () async {
      const key = BalanceFilterKey();
      expect(key.supportedOps, [FilterOp.gt, FilterOp.lt]);
    });

    test('addValue accepts `>value` / `<value` prefix forms produced by the '
        'pick-op-first flow and normalises to the suffix wire', () async {
      final vm = await makeVm();
      const key = BalanceFilterKey();
      await key.addValue(vm, '>1000');
      expect(vm.extraFilters['balance'], {'1000:gt'});
      await key.addValue(vm, '<500');
      expect(vm.extraFilters['balance'], {'500:lt'});
      // Embedded whitespace around the value is tolerated.
      await key.addValue(vm, '> 250');
      expect(vm.extraFilters['balance'], {'250:gt'});
      vm.dispose();
    });

    test(
      'isValidValue rejects bare operator symbols with no numeric value '
      '(so Enter on `balance:>` is a no-op instead of silently dropping)',
      () {
        const key = BalanceFilterKey();
        // No value: invalid.
        expect(key.isValidValue('>'), isFalse);
        expect(key.isValidValue('<'), isFalse);
        expect(key.isValidValue(':gt'), isFalse);
        expect(key.isValidValue(':lt'), isFalse);
        expect(key.isValidValue(''), isFalse);
        // With a value (any of the accepted forms): valid.
        expect(key.isValidValue('1000'), isTrue);
        expect(key.isValidValue('>1000'), isTrue);
        expect(key.isValidValue('1000:gt'), isTrue);
        expect(key.isValidValue('< 500'), isTrue);
      },
    );
  });

  group('CreatedFilterKey', () {
    test('addValue stores yyyy-MM-dd with suffix `:gt`', () async {
      final vm = await makeVm();
      const key = CreatedFilterKey();
      await key.addValue(vm, '2026-01-01');
      expect(vm.extraFilters['created_at'], {'2026-01-01:gt'});
      vm.dispose();
    });
  });

  group('UpdatedFilterKey', () {
    test('addValue stores yyyy-MM-dd with suffix `:gt`', () async {
      final vm = await makeVm();
      const key = UpdatedFilterKey();
      await key.addValue(vm, '2026-05-01');
      expect(vm.extraFilters['updated_at'], {'2026-05-01:gt'});
      vm.dispose();
    });
  });

  group('VatFilterKey / IdNumberFilterKey / ClassificationFilterKey', () {
    test('vat accumulates multiple values', () async {
      final vm = await makeVm();
      const key = VatFilterKey();
      await key.addValue(vm, 'DE123');
      await key.addValue(vm, 'FR456');
      expect(vm.extraFilters['vat_number'], {'DE123', 'FR456'});
      await key.removeValue(vm, 'DE123');
      expect(vm.extraFilters['vat_number'], {'FR456'});
      vm.dispose();
    });

    test('classification stores the typed enum-ish value', () async {
      final vm = await makeVm();
      const key = ClassificationFilterKey();
      await key.addValue(vm, 'company');
      expect(vm.extraFilters['classification'], {'company'});
      vm.dispose();
    });
  });

  group('CurrencyFilterKey', () {
    test('reads from extraFilters under currency_id', () async {
      final vm = await makeVm();
      final key = CurrencyFilterKey(
        statics: _FakeStaticsRepository(
          db: db,
          service: _FakeStaticsService(),
          currencies: {
            '1': Currency(
              id: '1',
              name: 'US Dollar',
              code: 'USD',
              symbol: r'$',
              precision: 2,
              thousandSeparator: ',',
              decimalSeparator: '.',
              swapCurrencySymbol: false,
              exchangeRate: Decimal.one,
            ),
          },
        ),
      );
      await key.addValue(vm, '1');
      expect(vm.extraFilters['currency_id'], {'1'});
      vm.dispose();
    });
  });

  group('LanguageFilterKey', () {
    test('reads from extraFilters under language_id', () async {
      final vm = await makeVm();
      final key = LanguageFilterKey(
        statics: _FakeStaticsRepository(
          db: db,
          service: _FakeStaticsService(),
          languages: const {
            '1': Language(id: '1', name: 'English', locale: 'en'),
          },
        ),
      );
      await key.addValue(vm, '1');
      expect(vm.extraFilters['language_id'], {'1'});
      vm.dispose();
    });
  });

  group(
    'quickValueSuggestions (cross-key value matches in free-text picker)',
    () {
      // The key-mode picker calls `quickValueSuggestions` on every key
      // synchronously and surfaces matches as a `Filter values` block.
      // These tests verify the per-key contribution: each contributing
      // key returns the expected matches, and non-contributing keys
      // (typed-input + flat-membership) return empty so they don't
      // pollute the picker.

      testWidgets('IsFilterKey: `act` → [Active] (startsWith on label)', (
        tester,
      ) async {
        // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
        // uses `Future.delayed(Duration.zero)`, which never settles
        // inside `testWidgets`'s fake-time clock. `quickValueSuggestions`
        // doesn't read VM state on contributing keys (statics-backed
        // keys hit `statics.*`; `IsFilterKey` enumerates EntityState
        // values), so a freshly-constructed VM is enough.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        late List<FilterValueSuggestion> matches;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                matches = const IsFilterKey().quickValueSuggestions(
                  vm,
                  context,
                  'act',
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(matches.map((s) => s.rawValue), ['active']);
        expect(matches.first.displayLabel, 'Active');
      });

      testWidgets('IsFilterKey: empty query → []', (tester) async {
        // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
        // uses `Future.delayed(Duration.zero)`, which never settles
        // inside `testWidgets`'s fake-time clock. `quickValueSuggestions`
        // doesn't read VM state on contributing keys (statics-backed
        // keys hit `statics.*`; `IsFilterKey` enumerates EntityState
        // values), so a freshly-constructed VM is enough.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        late List<FilterValueSuggestion> matches;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                matches = const IsFilterKey().quickValueSuggestions(
                  vm,
                  context,
                  '',
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(matches, isEmpty);
      });

      testWidgets('IsFilterKey: no match → []', (tester) async {
        // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
        // uses `Future.delayed(Duration.zero)`, which never settles
        // inside `testWidgets`'s fake-time clock. `quickValueSuggestions`
        // doesn't read VM state on contributing keys (statics-backed
        // keys hit `statics.*`; `IsFilterKey` enumerates EntityState
        // values), so a freshly-constructed VM is enough.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        late List<FilterValueSuggestion> matches;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                matches = const IsFilterKey().quickValueSuggestions(
                  vm,
                  context,
                  'xyz',
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(matches, isEmpty);
      });

      testWidgets('CountryFilterKey: `ger` → [Germany] (startsWith on name)', (
        tester,
      ) async {
        // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
        // uses `Future.delayed(Duration.zero)`, which never settles
        // inside `testWidgets`'s fake-time clock. `quickValueSuggestions`
        // doesn't read VM state on contributing keys (statics-backed
        // keys hit `statics.*`; `IsFilterKey` enumerates EntityState
        // values), so a freshly-constructed VM is enough.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        final key = CountryFilterKey(
          statics: _FakeStaticsRepository(
            db: db,
            service: _FakeStaticsService(),
            countries: const {
              '276': Country(
                id: '276',
                name: 'Germany',
                iso2: 'DE',
                iso3: 'DEU',
                swapCurrencySymbol: false,
                thousandSeparator: '.',
                decimalSeparator: ',',
                swapPostalCode: false,
              ),
              '840': _kUsa,
            },
          ),
        );
        late List<FilterValueSuggestion> matches;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                matches = key.quickValueSuggestions(vm, context, 'ger');
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(matches.map((s) => s.displayLabel), ['Germany']);
        expect(matches.first.rawValue, '276');
      });

      testWidgets('CountryFilterKey: `us` → [United States] via ISO2', (
        tester,
      ) async {
        // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
        // uses `Future.delayed(Duration.zero)`, which never settles
        // inside `testWidgets`'s fake-time clock. `quickValueSuggestions`
        // doesn't read VM state on contributing keys (statics-backed
        // keys hit `statics.*`; `IsFilterKey` enumerates EntityState
        // values), so a freshly-constructed VM is enough.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        final key = CountryFilterKey(
          statics: _FakeStaticsRepository(
            db: db,
            service: _FakeStaticsService(),
            countries: const {'840': _kUsa},
          ),
        );
        late List<FilterValueSuggestion> matches;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                matches = key.quickValueSuggestions(vm, context, 'us');
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        // ISO2 exact-match is the second branch — the name "United
        // States" doesn't startsWith "us", but the iso2 code does.
        expect(matches.map((s) => s.displayLabel), ['United States']);
        expect(matches.first.secondaryLabel, 'US');
      });

      testWidgets('CountryFilterKey: caps at 3 per key when many match', (
        tester,
      ) async {
        // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
        // uses `Future.delayed(Duration.zero)`, which never settles
        // inside `testWidgets`'s fake-time clock. `quickValueSuggestions`
        // doesn't read VM state on contributing keys (statics-backed
        // keys hit `statics.*`; `IsFilterKey` enumerates EntityState
        // values), so a freshly-constructed VM is enough.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        // Five made-up countries all starting with "un" so the cap is
        // the only thing constraining the output.
        Country mk(String id, String name, String iso2, String iso3) => Country(
          id: id,
          name: name,
          iso2: iso2,
          iso3: iso3,
          swapCurrencySymbol: false,
          thousandSeparator: ',',
          decimalSeparator: '.',
          swapPostalCode: false,
        );
        final key = CountryFilterKey(
          statics: _FakeStaticsRepository(
            db: db,
            service: _FakeStaticsService(),
            countries: {
              '1': mk('1', 'Unallocated', 'UA', 'UAA'),
              '2': mk('2', 'Unbridged', 'UB', 'UBB'),
              '3': mk('3', 'Uncharted', 'UC', 'UCC'),
              '4': mk('4', 'Undecided', 'UD', 'UDD'),
              '5': mk('5', 'United Land', 'UL', 'ULL'),
            },
          ),
        );
        late List<FilterValueSuggestion> matches;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                matches = key.quickValueSuggestions(vm, context, 'un');
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        // Alphabetically: Unallocated, Unbridged, Uncharted, …
        expect(matches.length, 3);
        expect(matches.map((s) => s.displayLabel), [
          'Unallocated',
          'Unbridged',
          'Uncharted',
        ]);
      });

      testWidgets('CurrencyFilterKey: `eur` → [EUR] (startsWith on code)', (
        tester,
      ) async {
        // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
        // uses `Future.delayed(Duration.zero)`, which never settles
        // inside `testWidgets`'s fake-time clock. `quickValueSuggestions`
        // doesn't read VM state on contributing keys (statics-backed
        // keys hit `statics.*`; `IsFilterKey` enumerates EntityState
        // values), so a freshly-constructed VM is enough.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        final key = CurrencyFilterKey(
          statics: _FakeStaticsRepository(
            db: db,
            service: _FakeStaticsService(),
            currencies: {
              '3': Currency(
                id: '3',
                name: 'Euro',
                code: 'EUR',
                symbol: '€',
                precision: 2,
                thousandSeparator: '.',
                decimalSeparator: ',',
                swapCurrencySymbol: false,
                exchangeRate: Decimal.one,
              ),
              '1': Currency(
                id: '1',
                name: 'US Dollar',
                code: 'USD',
                symbol: r'$',
                precision: 2,
                thousandSeparator: ',',
                decimalSeparator: '.',
                swapCurrencySymbol: false,
                exchangeRate: Decimal.one,
              ),
            },
          ),
        );
        late List<FilterValueSuggestion> matches;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                matches = key.quickValueSuggestions(vm, context, 'eur');
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(matches.map((s) => s.displayLabel), ['EUR']);
        expect(matches.first.rawValue, '3');
        expect(matches.first.secondaryLabel, 'Euro');
      });

      testWidgets('IndustryFilterKey: `soft` → [Software]', (tester) async {
        // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
        // uses `Future.delayed(Duration.zero)`, which never settles
        // inside `testWidgets`'s fake-time clock. `quickValueSuggestions`
        // doesn't read VM state on contributing keys (statics-backed
        // keys hit `statics.*`; `IsFilterKey` enumerates EntityState
        // values), so a freshly-constructed VM is enough.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        final key = IndustryFilterKey(
          statics: _FakeStaticsRepository(
            db: db,
            service: _FakeStaticsService(),
            industries: const {
              '5': Industry(id: '5', name: 'Software'),
              '9': Industry(id: '9', name: 'Manufacturing'),
            },
          ),
        );
        late List<FilterValueSuggestion> matches;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                matches = key.quickValueSuggestions(vm, context, 'soft');
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(matches.map((s) => s.displayLabel), ['Software']);
      });

      testWidgets('LanguageFilterKey: `eng` → [English]', (tester) async {
        // Construct `_FakeVm` directly — `makeVm()`'s hydrate-await loop
        // uses `Future.delayed(Duration.zero)`, which never settles
        // inside `testWidgets`'s fake-time clock. `quickValueSuggestions`
        // doesn't read VM state on contributing keys (statics-backed
        // keys hit `statics.*`; `IsFilterKey` enumerates EntityState
        // values), so a freshly-constructed VM is enough.
        final vm = _FakeVm(
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
        );
        addTearDown(vm.dispose);
        final key = LanguageFilterKey(
          statics: _FakeStaticsRepository(
            db: db,
            service: _FakeStaticsService(),
            languages: const {
              '1': Language(id: '1', name: 'English', locale: 'en'),
            },
          ),
        );
        late List<FilterValueSuggestion> matches;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                matches = key.quickValueSuggestions(vm, context, 'eng');
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(matches.map((s) => s.displayLabel), ['English']);
      });

      testWidgets(
        'CustomFieldFilterKey: `nor` → [North] (startsWith on cached value)',
        (tester) async {
          // Regression coverage for the cross-key custom-value lookup. The
          // sister keys (Country, Currency, Industry, Language, Status) all
          // got `quickValueSuggestions` overrides; CustomFieldFilterKey was
          // missed in that pass, so typing free text didn't surface
          // `Region: North`. Reads from the synchronous cache populated by
          // `GenericListViewModel._subscribeCustomValues`.
          final vm = _FakeVm(
            companyId: 'co',
            navStateDao: db.navStateDao,
            userSettings: UserSettingsRepository(db: db),
            searchDebounce: const Duration(milliseconds: 1),
            persistDebounce: const Duration(milliseconds: 1),
          );
          addTearDown(vm.dispose);
          late List<FilterValueSuggestion> matches;
          await tester.pumpWidget(
            wrap(
              Builder(
                builder: (context) {
                  matches = const CustomFieldFilterKey(
                    columnIndex: 1,
                    configuredLabel: 'Region',
                  ).quickValueSuggestions(vm, context, 'nor');
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          expect(matches.map((s) => s.displayLabel), ['North']);
          expect(matches.first.rawValue, 'North');
        },
      );

      testWidgets(
        'CustomFieldFilterKey: empty configuredLabel returns [] (key is hidden)',
        (tester) async {
          // Symmetric with `isAvailable: false` — when the workspace
          // hasn't configured a label for this custom column, the key
          // doesn't show up in the menu, so its cross-key contributions
          // shouldn't either.
          final vm = _FakeVm(
            companyId: 'co',
            navStateDao: db.navStateDao,
            userSettings: UserSettingsRepository(db: db),
            searchDebounce: const Duration(milliseconds: 1),
            persistDebounce: const Duration(milliseconds: 1),
          );
          addTearDown(vm.dispose);
          late List<FilterValueSuggestion> matches;
          await tester.pumpWidget(
            wrap(
              Builder(
                builder: (context) {
                  matches = const CustomFieldFilterKey(
                    columnIndex: 1,
                    configuredLabel: '',
                  ).quickValueSuggestions(vm, context, 'nor');
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          expect(matches, isEmpty);
        },
      );

      testWidgets(
        'non-contributing keys return empty by default (Name, Balance, Vat)',
        (tester) async {
          // Construct `_FakeVm` directly — see the earlier comment.
          final vm = _FakeVm(
            companyId: 'co',
            navStateDao: db.navStateDao,
            userSettings: UserSettingsRepository(db: db),
            searchDebounce: const Duration(milliseconds: 1),
            persistDebounce: const Duration(milliseconds: 1),
          );
          addTearDown(vm.dispose);
          // These keys don't have an enumerable value set, so they
          // should NOT show up in the cross-key value-match block —
          // typing free text shouldn't surface a `Name: foo` row.
          late List<List<FilterValueSuggestion>> results;
          await tester.pumpWidget(
            wrap(
              Builder(
                builder: (context) {
                  results = [
                    const NameFilterKey().quickValueSuggestions(
                      vm,
                      context,
                      'foo',
                    ),
                    const BalanceFilterKey().quickValueSuggestions(
                      vm,
                      context,
                      '100',
                    ),
                    const VatFilterKey().quickValueSuggestions(
                      vm,
                      context,
                      'DE',
                    ),
                    const IdNumberFilterKey().quickValueSuggestions(
                      vm,
                      context,
                      '123',
                    ),
                    const ClassificationFilterKey().quickValueSuggestions(
                      vm,
                      context,
                      'com',
                    ),
                  ];
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          for (final r in results) {
            expect(r, isEmpty);
          }
        },
      );
    },
  );

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
      // is, search, name, email, number, balance, custom1..4 (4),
      // country, industry, size, currency, language, classification,
      // vat, id_number, created, updated, group, assigned → 22 keys.
      // custom1 gets "Region", custom3 gets "Project"; others fall
      // through to the generic label.
      expect(displayLabels.length, 22);
      // Order: is(0), search(1), name(2), email(3), number(4),
      // balance(5), custom1(6)…custom4(9), …
      expect(
        displayLabels[6],
        'Region',
        reason: 'custom1 with configured label',
      );
      expect(
        displayLabels[8],
        'Project',
        reason: 'custom3 with configured label',
      );
    });
  });
}

class _FakeStaticsService implements StaticsService {
  @override
  Future<Map<String, dynamic>> fetch() async => const {};
}
