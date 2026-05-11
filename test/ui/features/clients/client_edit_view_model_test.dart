import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/ui/features/clients/view_models/client_edit_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests target ClientEditViewModel's contract — what the screen depends on:
///   * Create mode mints a tmp_ id via repo.create and queues a 'create' row
///   * Edit mode passes the modified client to repo.save and queues 'update'
///   * isDirty stays false until the user actually changes something
///   * isDirty for create flips true the moment a field has content
///   * primary contact edits target the existing primary (or create one)
/// They don't re-test the repo / outbox / ChangeNotifier itself.

class _NoopApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) {
    // The edit VM never hits the API directly — everything lands via the
    // outbox. A call here means we accidentally bypassed the repo.
    throw StateError('Unexpected API call: ${invocation.memberName}');
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

  Client existing() => Client.fromApi(
    ClientApi.fromJson({'id': 'c1', 'name': 'Original', 'balance': '0'}),
  );

  group('isDirty', () {
    test('edit mode: stays false until a field actually changes', () {
      final vm = ClientEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing(),
      );
      expect(vm.isDirty, isFalse);
      vm.setName('Renamed');
      expect(vm.isDirty, isTrue);
      vm.dispose();
    });

    test('create mode: false until the form has any content', () {
      final vm = ClientEditViewModel(repo: repo, companyId: 'co');
      expect(vm.isDirty, isFalse);
      vm.setName('New Client');
      expect(vm.isDirty, isTrue);
      vm.dispose();
    });
  });

  group('save (edit)', () {
    test(
      'queues an update outbox row and reflects the new name in Drift',
      () async {
        // Seed Drift with the existing row so save actually has something
        // to overwrite.
        await repo.applyUpdateResponse(
          companyId: 'co',
          serverResponse: ClientApi.fromJson({'id': 'c1', 'name': 'Original'}),
        );

        final vm = ClientEditViewModel(
          repo: repo,
          companyId: 'co',
          existing: existing(),
        );
        vm.setName('Renamed');

        final result = await vm.save();
        expect(result, isNotNull);
        expect(result!.name, 'Renamed');

        final pending = await db.outboxDao.nextReady(
          companyId: 'co',
          now: 1 << 60,
        );
        expect(pending, hasLength(1));
        expect(pending.single.mutationKind, MutationKind.update.wireName);
        expect(pending.single.entityId, 'c1');
        vm.dispose();
      },
    );
  });

  group('save (create)', () {
    test(
      'mints a tmp_ id, returns it, and queues a create outbox row',
      () async {
        final vm = ClientEditViewModel(repo: repo, companyId: 'co');
        vm.setName('Brand New');
        vm.setPrimaryContactEmail('person@new.test');

        final result = await vm.save();
        expect(result, isNotNull);
        expect(result!.id, startsWith('tmp_'));
        expect(result.name, 'Brand New');
        expect(result.contacts.single.email, 'person@new.test');

        final pending = await db.outboxDao.nextReady(
          companyId: 'co',
          now: 1 << 60,
        );
        expect(pending.single.mutationKind, MutationKind.create.wireName);
        expect(pending.single.entityId, startsWith('tmp_'));
        vm.dispose();
      },
    );
  });

  group('primary contact editing', () {
    test('creates a primary contact when none exists yet', () {
      final vm = ClientEditViewModel(repo: repo, companyId: 'co');
      vm.setPrimaryContactFirstName('Jane');
      vm.setPrimaryContactEmail('jane@x.test');
      expect(vm.draft.contacts, hasLength(1));
      expect(vm.draft.contacts.single.firstName, 'Jane');
      expect(vm.draft.contacts.single.isPrimary, isTrue);
      vm.dispose();
    });

    test('edits the existing primary contact in place', () {
      final existing = Client.fromApi(
        ClientApi.fromJson({
          'id': 'c1',
          'name': 'Acme',
          'balance': '0',
          'contacts': [
            {'id': 'a', 'first_name': 'Alice', 'is_primary': false},
            {'id': 'b', 'first_name': 'Bob', 'is_primary': true},
          ],
        }),
      );
      final vm = ClientEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing,
      );
      vm.setPrimaryContactFirstName('Bobby');
      expect(
        vm.draft.contacts.firstWhere((c) => c.id == 'b').firstName,
        'Bobby',
      );
      expect(
        vm.draft.contacts.firstWhere((c) => c.id == 'a').firstName,
        'Alice',
        reason: 'secondary contact must be untouched',
      );
      vm.dispose();
    });
  });
}
