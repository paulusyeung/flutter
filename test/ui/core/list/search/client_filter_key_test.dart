import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/client_filter_key.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the shared `ClientFilterKey` round-trips ids through
/// `vm.extraFilters['client_id']` and that `displayValueFor` consults
/// the parent-supplied `nameForClientId` callback (with a graceful
/// fallback to the raw id when the names map hasn't loaded yet).

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

  test('id and serverKey are stable wire contracts', () {
    final key = ClientFilterKey(clients: repo, companyId: 'co');
    expect(key.id, 'client');
    expect(key.serverKey, 'client_id');
  });

  test('addValue / removeValue round-trip through extraFilters', () async {
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

    vm.dispose();
  });

  test('isAtDefault tracks the filter set', () async {
    final vm = await makeVm();
    final key = ClientFilterKey(clients: repo, companyId: 'co');

    expect(key.isAtDefault(vm), isTrue);
    await key.addValue(vm, 'c1');
    expect(key.isAtDefault(vm), isFalse);

    vm.dispose();
  });

  group('displayValueFor', () {
    test('returns raw id when no resolver is supplied', () {
      final key = ClientFilterKey(clients: repo, companyId: 'co');
      expect(key.displayValueFor('opaque-id'), 'opaque-id');
    });

    test('resolves through the parent-supplied lookup', () {
      const names = {'c1': 'Acme Co.', 'c2': 'Globex'};
      final key = ClientFilterKey(
        clients: repo,
        companyId: 'co',
        nameForClientId: (id) => names[id],
      );
      expect(key.displayValueFor('c1'), 'Acme Co.');
      expect(key.displayValueFor('c2'), 'Globex');
    });

    test('falls back to raw id when the resolver returns null '
        '(client not yet in the names stream)', () {
      const names = {'c1': 'Acme Co.'};
      final key = ClientFilterKey(
        clients: repo,
        companyId: 'co',
        nameForClientId: (id) => names[id],
      );
      expect(key.displayValueFor('unknown-id'), 'unknown-id');
    });

    test('falls back to raw id when the resolver returns an empty string '
        '(client exists but has no name yet)', () {
      final key = ClientFilterKey(
        clients: repo,
        companyId: 'co',
        nameForClientId: (id) => '',
      );
      expect(key.displayValueFor('c1'), 'c1');
    });
  });
}
