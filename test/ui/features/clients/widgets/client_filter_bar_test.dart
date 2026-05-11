import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/state_filter_pills.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests the pill-tap → VM update path through a real ClientListViewModel.
/// (The full `ClientFilterBar` also embeds dropdowns driven by Drift
/// streams; those are hard to settle in the test harness, so dropdown
/// surface-level behavior is covered by the VM tests instead.)

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
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  });

  tearDown(() async {
    vm.dispose();
    await db.close();
  });

  testWidgets('tapping a pill chip toggles the matching state in the VM', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(Brightness.light),
        home: Scaffold(
          body: ListenableBuilder(
            listenable: vm,
            builder: (_, _) => StateFilterPills(
              selected: vm.states,
              onToggle: vm.toggleState,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();

    expect(vm.states, {EntityState.active, EntityState.archived});
  });
}
