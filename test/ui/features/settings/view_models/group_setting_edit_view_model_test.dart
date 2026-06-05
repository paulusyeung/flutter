import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/group_setting_api_model.dart';
import 'package:admin/data/models/domain/group_setting.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/data/services/group_settings_api.dart';
import 'package:admin/ui/features/settings/view_models/group_setting_edit_view_model.dart';

/// Covers the client-side group-name validation that gates Save. The server
/// requires `name` to be present and unique-per-company on create
/// (`StoreGroupSettingRequest`); these tests assert the VM blocks the same
/// cases up front instead of letting the optimistic save bounce later.
void main() {
  group('GroupSettingEditViewModel — name validation', () {
    late AppDatabase db;
    late GroupSettingRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = GroupSettingRepository(db: db, api: _FakeGroupSettingsApi());
    });
    tearDown(() async {
      await db.close();
    });

    // Seed a synced group so it shows up in `watchAllIncludingArchived` (the
    // uniqueness scope the VM watches). `archivedAt: 0` => active.
    Future<void> seed(String id, String name, {int archivedAt = 0}) =>
        repo.applyCreateResponse(
          companyId: 'co',
          tempId: id,
          serverResponse: GroupSettingApi(
            id: id,
            name: name,
            updatedAt: 1700000000,
            archivedAt: archivedAt,
          ),
        );

    GroupSettingEditViewModel makeVm({GroupSetting? existing}) {
      final vm = GroupSettingEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing,
      );
      addTearDown(vm.dispose);
      return vm;
    }

    GroupSetting existingGroup(String id, String name) => GroupSetting.fromApi(
      GroupSettingApi(id: id, name: name, updatedAt: 1700000000),
    );

    test('create: blank name is invalid with no inline error', () {
      final vm = makeVm();
      expect(vm.nameIsValid, isFalse);
      expect(vm.nameErrorKey, isNull);
    });

    test('create: a whitespace-only name is invalid', () {
      final vm = makeVm();
      vm.setName('   ');
      expect(vm.nameIsValid, isFalse);
      expect(vm.nameErrorKey, isNull);
    });

    test('create: a unique name is valid', () async {
      await seed('g_a', 'Alpha');
      final vm = makeVm();
      vm.setName('Beta');
      await pumpEventQueue();
      expect(vm.nameIsValid, isTrue);
      expect(vm.nameErrorKey, isNull);
    });

    test(
      'create: a duplicate name (case-insensitive) is blocked inline',
      () async {
        await seed('g_a', 'Alpha');
        final vm = makeVm();
        vm.setName('alpha');
        await pumpEventQueue();
        expect(vm.nameIsValid, isFalse);
        expect(vm.nameErrorKey, 'group_name_taken');
      },
    );

    test('create: an archived group still reserves its name', () async {
      await seed('g_arch', 'Legacy', archivedAt: 1700000000);
      final vm = makeVm();
      vm.setName('Legacy');
      await pumpEventQueue();
      expect(vm.nameIsValid, isFalse);
      expect(vm.nameErrorKey, 'group_name_taken');
    });

    test(
      'edit: keeping the group its own name is valid (self excluded)',
      () async {
        await seed('g_a', 'Alpha');
        final vm = makeVm(existing: existingGroup('g_a', 'Alpha'));
        await pumpEventQueue();
        expect(vm.nameIsValid, isTrue);
        expect(vm.nameErrorKey, isNull);
      },
    );

    test('edit: renaming onto another group is allowed — the server checks '
        'uniqueness only on create', () async {
      await seed('g_a', 'Alpha');
      await seed('g_b', 'Beta');
      final vm = makeVm(existing: existingGroup('g_a', 'Alpha'));
      vm.setName('Beta');
      await pumpEventQueue();
      expect(vm.nameIsValid, isTrue);
      expect(vm.nameErrorKey, isNull);
    });
  });
}

class _FakeGroupSettingsApi implements GroupSettingsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
