import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/active_filters_strip.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClientsApi implements ClientsApi {
  @override
  Future<({ClientListApi data, int? cursorUpdatedAt, String? cursorId})> list({
    required int page,
    int perPage = 50,
    String? search,
    int? sinceUpdatedAt,
    String? sinceId,
    Map<String, String> filters = const {},
  }) async => (
    data: ClientListApi(data: const []),
    cursorUpdatedAt: null,
    cursorId: null,
  );

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late ClientListViewModel vm;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    vm = ClientListViewModel(
      repo: ClientRepository(db: db, api: _FakeClientsApi()),
      navStateDao: db.navStateDao,
      userSettings: UserSettingsRepository(db: db),
      companyId: 'co',
      searchDebounce: const Duration(milliseconds: 1),
      persistDebounce: const Duration(milliseconds: 1),
    );
    // Let initial load + hydration settle.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  });

  tearDown(() async {
    vm.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(Brightness.light),
        home: Scaffold(
          body: ListenableBuilder(
            listenable: vm,
            builder: (_, _) => ActiveFiltersStrip(vm: vm),
          ),
        ),
      ),
    );
  }

  testWidgets('hidden when no filters are active', (tester) async {
    await pump(tester);
    expect(find.byType(ActiveFiltersStrip), findsOneWidget);
    expect(find.text('Clear all'), findsNothing);
    expect(find.text('Active'), findsNothing);
  });

  testWidgets(
    'shows a chip per non-default filter plus a Clear all button',
    (tester) async {
      await vm.setStates({EntityState.archived});
      await vm.setSort(field: ClientFieldIds.balance, ascending: false);
      await tester.pumpAndSettle();
      await pump(tester);

      expect(find.text('Archived'), findsOneWidget);
      expect(find.textContaining('Sort: Balance'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
    },
  );

  testWidgets('Clear all resets the VM and hides the strip', (tester) async {
    await vm.setStates({EntityState.archived});
    await tester.pumpAndSettle();
    await pump(tester);

    expect(find.text('Clear all'), findsOneWidget);
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(vm.states, {EntityState.active});
    expect(find.text('Clear all'), findsNothing);
  });
}
