import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/ui/features/clients/view_models/client_detail_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests target ClientDetailViewModel's contract:
///   * watches the repository so a synced edit reaches the screen
///   * resolves through `id_remap` so a detail screen opened with a tmp id
///     keeps showing the entity after the sync engine swaps to the real id
///   * surfaces null + isResolving=false when the row is missing
/// They don't re-test Drift or ClientRepository itself.

class _NoopApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    // The detail VM only watches; it doesn't trigger the API. Anything that
    // does call the API in this fake suite is a regression worth flagging.
    throw StateError('Unexpected API call: $name');
  }
}

ClientApi _api(String id, {String name = 'Acme'}) =>
    ClientApi(id: id, name: name, updatedAt: 1);

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
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

  test('emits null when the row is missing and isResolving=false', () async {
    final vm = ClientDetailViewModel(
      repo: repo,
      companyId: 'co',
      id: 'missing',
    );
    await _settle();
    expect(vm.item, isNull);
    expect(vm.isResolving, isFalse);
    vm.dispose();
  });

  test('streams updates as the repository row changes', () async {
    final vm = ClientDetailViewModel(repo: repo, companyId: 'co', id: 'c1');
    await _settle();
    expect(vm.item, isNull);

    // Server response lands — VM surfaces the row.
    await repo.applyUpdateResponse(
      companyId: 'co',
      serverResponse: _api('c1', name: 'First'),
    );
    await _settle();
    expect(vm.item?.name, 'First');

    // A subsequent update (e.g. server refresh) flows through too.
    await repo.applyUpdateResponse(
      companyId: 'co',
      serverResponse: _api('c1', name: 'Renamed'),
    );
    await _settle();
    expect(vm.item?.name, 'Renamed');
    vm.dispose();
  });

  test(
    'detail screen opened with tmp id survives the sync engine remap',
    () async {
      // Simulate "we just created a client offline" — Drift has the tmp row.
      final draft = Client.fromApi(
        _api('', name: 'New'),
      ).copyWith(isDirty: true);
      final created = (await repo.create(companyId: 'co', draft: draft)).entity;
      expect(created.id, startsWith('tmp_'));

      final vm = ClientDetailViewModel(
        repo: repo,
        companyId: 'co',
        id: created.id, // navigated to /clients/tmp_xxx
      );
      await _settle();
      expect(vm.item?.id, created.id);

      // Sync engine swaps tmp → real id.
      await repo.applyCreateResponse(
        companyId: 'co',
        tempId: created.id,
        serverResponse: _api('real_xyz', name: 'New'),
      );
      await _settle();

      expect(
        vm.item?.id,
        'real_xyz',
        reason: 'watch must resolve through id_remap so the URL stays valid',
      );
      vm.dispose();
    },
  );
}
