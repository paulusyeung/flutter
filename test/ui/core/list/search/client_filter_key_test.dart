import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/client_filter_key.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../_localization_helper.dart';

/// Verifies the shared `ClientFilterKey` round-trips ids through
/// `vm.extraFilters['client_id']`. The repository's `watchActiveNames`
/// is exercised at runtime; the unit test focuses on the VM contract.

class _NoopApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected API call: ${invocation.memberName}');
  }
}

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
  late ClientRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ClientRepository(db: db, api: _NoopApi());
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

  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: kTestLocalizationsDelegates,
    supportedLocales: kTestSupportedLocales,
    home: Material(child: child),
  );

  testWidgets('id and serverKey are stable wire contracts', (tester) async {
    final key = ClientFilterKey(clients: repo, companyId: 'co');
    expect(key.id, 'client');
    expect(key.serverKey, 'client_id');
    key.dispose();
  });

  testWidgets('addValue / removeValue round-trip through extraFilters',
      (tester) async {
    final vm = await makeVm();
    final key = ClientFilterKey(clients: repo, companyId: 'co');

    await key.addValue(vm, 'c1');
    expect(vm.extraFilters['client_id'], {'c1'});

    await key.addValue(vm, 'c2');
    expect(vm.extraFilters['client_id'], {'c1', 'c2'});

    await key.removeValue(vm, 'c1');
    expect(vm.extraFilters['client_id'], {'c2'});

    await key.removeValue(vm, 'c2');
    expect(vm.extraFilters['client_id'] ?? const <String>{}, isEmpty);

    key.dispose();
    vm.dispose();
  });

  testWidgets('isAtDefault tracks the filter set', (tester) async {
    final vm = await makeVm();
    final key = ClientFilterKey(clients: repo, companyId: 'co');

    expect(key.isAtDefault(vm), isTrue);
    await key.addValue(vm, 'c1');
    expect(key.isAtDefault(vm), isFalse);

    key.dispose();
    vm.dispose();
  });

  testWidgets('tokensFrom emits one chip per applied id', (tester) async {
    final vm = await makeVm();
    final key = ClientFilterKey(clients: repo, companyId: 'co');
    await key.addValue(vm, 'c1');
    await key.addValue(vm, 'c2');

    BuildContext? captured;
    await tester.pumpWidget(
      wrap(Builder(builder: (ctx) {
        captured = ctx;
        return const SizedBox.shrink();
      })),
    );
    await tester.pumpAndSettle();

    final tokens = key.tokensFrom(vm, captured!).toList();
    expect(tokens, hasLength(2));
    expect(tokens.map((t) => t.rawValue).toSet(), {'c1', 'c2'});
    expect(tokens.first.displayKey, equals(Localization.of(captured!).tr('client')));

    key.dispose();
    vm.dispose();
  });

  testWidgets('displayValueFor falls back to the raw id when the names '
      'cache is empty', (tester) async {
    final key = ClientFilterKey(clients: repo, companyId: 'co');
    expect(key.displayValueFor('unknown-id'), 'unknown-id');
    key.dispose();
  });
}
