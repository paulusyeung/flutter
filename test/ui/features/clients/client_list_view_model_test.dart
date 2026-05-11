import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests target the ClientListViewModel's contract — what the UI
/// depends on. They DON'T re-test the repository, Drift, or ChangeNotifier
/// itself; we use a fake ClientsApi + a real in-memory ClientRepository so
/// the dataflow we actually wire in production is exercised.

class _FakeClientsApi implements ClientsApi {
  _FakeClientsApi();
  final Map<int, List<ClientApi>> pages = {};
  final List<({int page, String? search})> calls = [];
  Object? nextError;

  @override
  Future<({ClientListApi data, int? cursorUpdatedAt, String? cursorId})> list({
    required int page,
    int perPage = 50,
    String? search,
    int? sinceUpdatedAt,
    String? sinceId,
    Map<String, String> filters = const {},
  }) async {
    calls.add((page: page, search: search));
    if (nextError != null) {
      final err = nextError;
      nextError = null;
      throw err!;
    }
    final rows = pages[page] ?? const <ClientApi>[];
    return (
      data: ClientListApi(data: rows),
      cursorUpdatedAt: rows.isNotEmpty ? rows.last.updatedAt : null,
      cursorId: rows.isNotEmpty ? rows.last.id : null,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ClientApi _row(String id, {String name = ''}) =>
    ClientApi(id: id, name: name.isEmpty ? id : name, updatedAt: 100);

void main() {
  late AppDatabase db;
  late _FakeClientsApi api;
  late ClientRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _FakeClientsApi();
    repo = ClientRepository(db: db, api: api);
  });
  tearDown(() async {
    await db.close();
  });

  ClientListViewModel vmFor(String companyId) => ClientListViewModel(
        repo: repo,
        companyId: companyId,
        // Keep the debounce tiny so tests don't sleep needlessly.
        searchDebounce: const Duration(milliseconds: 1),
      );

  /// Pump the event loop a few times — enough for the constructor's
  /// `unawaited(_loadInitialPage())` and any chained `notifyListeners()`
  /// to settle.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('initial load', () {
    test('triggers an ensurePageLoaded(1) on construction', () async {
      api.pages[1] = [_row('c1'), _row('c2')];
      final vm = vmFor('co');
      await settle();

      expect(api.calls, hasLength(1));
      expect(api.calls.single.page, 1);
      expect(api.calls.single.search, isNull);
      expect(vm.clients.map((c) => c.id), ['c1', 'c2']);
      vm.dispose();
    });

    test('captures error so the screen can render ErrorView', () async {
      api.nextError = Exception('boom');
      final vm = vmFor('co');
      await settle();

      expect(vm.initialError, isNotNull);
      expect(vm.clients, isEmpty);

      // retryInitial flows through the same path and clears the error
      // on success.
      api.pages[1] = [_row('c1')];
      await vm.retryInitial();
      await settle();

      expect(vm.initialError, isNull);
      expect(vm.clients.map((c) => c.id), ['c1']);
      vm.dispose();
    });
  });

  group('loadMore', () {
    test('only widens loadedPages on a successful fetch', () async {
      api.pages[1] = [for (var i = 0; i < 50; i++) _row('c$i')]; // full page
      api.pages[2] = [_row('c50')]; // partial → hasMore=false
      final vm = vmFor('co');
      await settle();
      expect(vm.loadedPages, 1);
      expect(vm.hasMore, isTrue);

      await vm.loadMore();
      await settle();
      expect(vm.loadedPages, 2);
      expect(vm.hasMore, isFalse);

      // Calling again after hasMore=false is a no-op (no API call).
      final callsBefore = api.calls.length;
      await vm.loadMore();
      expect(api.calls.length, callsBefore);
      vm.dispose();
    });

    test('errors on subsequent pages do not bump loadedPages', () async {
      api.pages[1] = [for (var i = 0; i < 50; i++) _row('c$i')];
      final vm = vmFor('co');
      await settle();

      api.nextError = Exception('flake');
      await vm.loadMore();
      await settle();
      expect(vm.loadedPages, 1, reason: 'window must not widen on error');
      vm.dispose();
    });
  });

  group('search', () {
    test(
      'setSearch resets loadedPages and routes the term to the API',
      () async {
        api.pages[1] = [for (var i = 0; i < 50; i++) _row('c$i')];
        api.pages[2] = [_row('c50')];
        final vm = vmFor('co');
        await settle();
        await vm.loadMore();
        await settle();
        expect(vm.loadedPages, 2);

        // Now searching — the next API call should carry the term and
        // loadedPages should reset to 1.
        api.calls.clear();
        api.pages[1] = [_row('c_match', name: 'Acme')];
        vm.setSearch('acme');
        await settle();
        // Give the 1 ms debounce time to fire.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await settle();

        expect(vm.loadedPages, 1);
        expect(api.calls, hasLength(1));
        expect(api.calls.single.search, 'acme');
        vm.dispose();
      },
    );
  });
}
