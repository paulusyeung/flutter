import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/device_contacts_service.dart';
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

  group('multi-contact editing', () {
    test('create mode seeds one blank primary contact', () {
      final vm = ClientEditViewModel(repo: repo, companyId: 'co');
      expect(vm.draft.contacts, hasLength(1));
      final seeded = vm.draft.contacts.single;
      expect(seeded.isPrimary, isTrue);
      expect(seeded.firstName, isEmpty);
      expect(seeded.lastName, isEmpty);
      expect(seeded.email, isEmpty);
      expect(seeded.phone, isEmpty);
      // A blank seeded contact must not make an untouched form dirty.
      expect(vm.isDirty, isFalse);
      vm.dispose();
    });

    test(
      'addContact appends an empty row and marks it primary when list was empty',
      () {
        final vm = ClientEditViewModel(repo: repo, companyId: 'co');
        // New clients seed one blank primary contact; drop it to exercise the
        // empty-list branch of addContact.
        vm.removeContact(0);
        expect(vm.draft.contacts, isEmpty);
        vm.addContact();
        expect(vm.draft.contacts, hasLength(1));
        expect(vm.draft.contacts.single.isPrimary, isTrue);
        vm.dispose();
      },
    );

    test(
      'addContact on a non-empty list does not steal primary from the existing one',
      () {
        final existing = Client.fromApi(
          ClientApi.fromJson({
            'id': 'c1',
            'name': 'Acme',
            'balance': '0',
            'contacts': [
              {'id': 'a', 'first_name': 'Alice', 'is_primary': true},
            ],
          }),
        );
        final vm = ClientEditViewModel(
          repo: repo,
          companyId: 'co',
          existing: existing,
        );
        vm.addContact();
        expect(vm.draft.contacts, hasLength(2));
        expect(vm.draft.contacts[0].isPrimary, isTrue);
        expect(vm.draft.contacts[1].isPrimary, isFalse);
        vm.dispose();
      },
    );

    test(
      'removeContact promotes contacts[0] to primary when the primary is removed',
      () {
        final existing = Client.fromApi(
          ClientApi.fromJson({
            'id': 'c1',
            'name': 'Acme',
            'balance': '0',
            'contacts': [
              {'id': 'a', 'first_name': 'Alice', 'is_primary': false},
              {'id': 'b', 'first_name': 'Bob', 'is_primary': true},
              {'id': 'c', 'first_name': 'Carol', 'is_primary': false},
            ],
          }),
        );
        final vm = ClientEditViewModel(
          repo: repo,
          companyId: 'co',
          existing: existing,
        );
        vm.removeContact(1); // Bob, the primary
        expect(vm.draft.contacts, hasLength(2));
        expect(vm.draft.contacts[0].id, 'a');
        expect(vm.draft.contacts[0].isPrimary, isTrue, reason: 'auto-promote');
        expect(vm.draft.contacts[1].isPrimary, isFalse);
        vm.dispose();
      },
    );

    test(
      'setContactPrimary moves the primary flag, leaving fields untouched',
      () {
        final existing = Client.fromApi(
          ClientApi.fromJson({
            'id': 'c1',
            'name': 'Acme',
            'balance': '0',
            'contacts': [
              {'id': 'a', 'first_name': 'Alice', 'is_primary': true},
              {'id': 'b', 'first_name': 'Bob', 'is_primary': false},
            ],
          }),
        );
        final vm = ClientEditViewModel(
          repo: repo,
          companyId: 'co',
          existing: existing,
        );
        vm.setContactPrimary(1);
        expect(vm.draft.contacts[0].isPrimary, isFalse);
        expect(vm.draft.contacts[1].isPrimary, isTrue);
        expect(vm.draft.contacts[0].firstName, 'Alice');
        expect(vm.draft.contacts[1].firstName, 'Bob');
        vm.dispose();
      },
    );

    test(
      'indexed contact setters edit the right row without touching siblings',
      () {
        final existing = Client.fromApi(
          ClientApi.fromJson({
            'id': 'c1',
            'name': 'Acme',
            'balance': '0',
            'contacts': [
              {'id': 'a', 'first_name': 'Alice', 'is_primary': true},
              {'id': 'b', 'first_name': 'Bob', 'is_primary': false},
            ],
          }),
        );
        final vm = ClientEditViewModel(
          repo: repo,
          companyId: 'co',
          existing: existing,
        );
        vm.setContactEmailAt(1, 'bob@x.test');
        expect(vm.draft.contacts[1].email, 'bob@x.test');
        expect(vm.draft.contacts[0].email, '');
        vm.dispose();
      },
    );
  });

  group('applyImportedContact', () {
    test('fills the first all-blank contact row in place', () {
      final vm = ClientEditViewModel(repo: repo, companyId: 'co');
      // New clients already seed one blank primary row to fill in place.
      final r = vm.applyImportedContact(
        const DeviceContactImport(
          firstName: 'Dana',
          lastName: 'Lee',
          email: 'dana@x.test',
          phone: '555-1',
        ),
        countryId: '',
      );
      expect(r.contactAdded, isTrue);
      expect(
        vm.draft.contacts,
        hasLength(1),
        reason: 'filled in place, not appended',
      );
      expect(vm.draft.contacts.single.firstName, 'Dana');
      expect(vm.draft.contacts.single.email, 'dana@x.test');
      expect(vm.draft.contacts.single.isPrimary, isTrue);
      vm.dispose();
    });

    test('appends a non-primary contact when others already have data', () {
      final existing = Client.fromApi(
        ClientApi.fromJson({
          'id': 'c1',
          'name': 'Acme',
          'balance': '0',
          'contacts': [
            {'id': 'a', 'first_name': 'Alice', 'is_primary': true},
          ],
        }),
      );
      final vm = ClientEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing,
      );
      final r = vm.applyImportedContact(
        const DeviceContactImport(firstName: 'Dana', email: 'dana@x.test'),
        countryId: '',
      );
      expect(r.contactAdded, isTrue);
      expect(vm.draft.contacts, hasLength(2));
      expect(vm.draft.contacts[0].firstName, 'Alice');
      expect(vm.draft.contacts[1].firstName, 'Dana');
      expect(vm.draft.contacts[1].isPrimary, isFalse);
      vm.dispose();
    });

    test('client name/address/website are blanks-only (never overwrite)', () {
      final existing = Client.fromApi(
        ClientApi.fromJson({
          'id': 'c1',
          'name': 'Acme',
          'address1': 'Existing St',
          'website': 'acme.test',
          'balance': '0',
        }),
      );
      final vm = ClientEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing,
      );
      final r = vm.applyImportedContact(
        const DeviceContactImport(
          organization: 'NewCo',
          firstName: 'Dana',
          address1: 'New St',
          website: 'new.test',
        ),
        countryId: '840',
      );
      expect(vm.draft.name, 'Acme');
      expect(vm.draft.address1, 'Existing St');
      expect(vm.draft.website, 'acme.test');
      expect(
        vm.draft.countryId,
        '840',
        reason: 'countryId was blank, so it fills',
      );
      expect(r.filledClientFields, contains('address')); // countryId
      expect(r.filledClientFields, isNot(contains('name')));
      expect(r.filledClientFields, isNot(contains('website')));
      vm.dispose();
    });

    test('individual fallback: client name = person full name when no company', () {
      final vm = ClientEditViewModel(repo: repo, companyId: 'co');
      final r = vm.applyImportedContact(
        const DeviceContactImport(
          firstName: 'Jane',
          lastName: 'Doe',
          email: 'jane@x.test',
        ),
        countryId: '',
      );
      expect(vm.draft.name, 'Jane Doe');
      expect(vm.draft.displayName, 'Jane Doe');
      expect(r.filledClientFields, contains('name'));
      vm.dispose();
    });

    test('company-only card fills the client name and adds no contact', () {
      final vm = ClientEditViewModel(repo: repo, companyId: 'co');
      final r = vm.applyImportedContact(
        const DeviceContactImport(organization: 'OrgOnly'),
        countryId: '',
      );
      expect(vm.draft.name, 'OrgOnly');
      expect(
        vm.draft.contacts,
        hasLength(1),
        reason: 'seeded blank contact remains; no person on the card',
      );
      expect(vm.draft.contacts.single.firstName, isEmpty);
      expect(r.contactAdded, isFalse);
      expect(r.filledClientFields, contains('name'));
      expect(r.appliedChanges, isTrue);
      vm.dispose();
    });

    test('duplicate by email is skipped, not appended', () {
      final existing = Client.fromApi(
        ClientApi.fromJson({
          'id': 'c1',
          'name': 'Acme',
          'balance': '0',
          'contacts': [
            {
              'id': 'a',
              'first_name': 'Alice',
              'email': 'dup@x.test',
              'is_primary': true,
            },
          ],
        }),
      );
      final vm = ClientEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing,
      );
      final r = vm.applyImportedContact(
        const DeviceContactImport(firstName: 'Alicia', email: 'dup@x.test'),
        countryId: '',
      );
      expect(r.contactWasDuplicate, isTrue);
      expect(r.contactAdded, isFalse);
      expect(
        r.appliedChanges,
        isFalse,
        reason: 'client name already set; nothing filled',
      );
      expect(vm.draft.contacts, hasLength(1));
      vm.dispose();
    });

    test('all-blank pick changes nothing', () {
      final vm = ClientEditViewModel(repo: repo, companyId: 'co');
      final r = vm.applyImportedContact(
        const DeviceContactImport(),
        countryId: '',
      );
      expect(r.changedNothing, isTrue);
      expect(vm.draft.name, '');
      expect(
        vm.draft.contacts,
        hasLength(1),
        reason: 'seeded blank contact remains; import added nothing',
      );
      expect(vm.draft.contacts.single.firstName, isEmpty);
      vm.dispose();
    });

    test('display-name-only contact is split into first/last', () {
      final vm = ClientEditViewModel(repo: repo, companyId: 'co');
      vm.applyImportedContact(
        const DeviceContactImport(
          displayName: 'John Smith',
          email: 'john@x.test',
        ),
        countryId: '',
      );
      expect(vm.draft.contacts.single.firstName, 'John');
      expect(vm.draft.contacts.single.lastName, 'Smith');
      vm.dispose();
    });

    test('restoreDraft round-trips the pre-import snapshot (Undo)', () {
      final vm = ClientEditViewModel(repo: repo, companyId: 'co');
      final before = vm.draft;
      vm.applyImportedContact(
        const DeviceContactImport(firstName: 'Jane', organization: 'NewCo'),
        countryId: '',
      );
      expect(vm.draft.name, 'NewCo');
      expect(vm.draft.contacts, hasLength(1));
      vm.restoreDraft(before);
      expect(vm.draft.name, '');
      expect(
        vm.draft.contacts,
        hasLength(1),
        reason: 'restores the seeded blank contact snapshot',
      );
      expect(vm.draft.contacts.single.firstName, isEmpty);
      vm.dispose();
    });

    test('single-name import appends, does not skip a different person', () {
      final existing = Client.fromApi(
        ClientApi.fromJson({
          'id': 'c1',
          'name': 'Acme',
          'balance': '0',
          'contacts': [
            {'id': 'a', 'first_name': 'Cher', 'is_primary': true},
          ],
        }),
      );
      final vm = ClientEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing,
      );
      // A different "Cher" with no surname/email/phone must NOT be treated as
      // a duplicate of the existing single-name contact.
      final r = vm.applyImportedContact(
        const DeviceContactImport(firstName: 'Cher'),
        countryId: '',
      );
      expect(r.contactWasDuplicate, isFalse);
      expect(r.contactAdded, isTrue);
      expect(vm.draft.contacts, hasLength(2));
      vm.dispose();
    });

    test('phone-only re-import is deduped across formatting', () {
      final existing = Client.fromApi(
        ClientApi.fromJson({
          'id': 'c1',
          'name': 'Acme',
          'balance': '0',
          'contacts': [
            {
              'id': 'a',
              'first_name': 'Pat',
              'phone': '(555) 123-4567',
              'is_primary': true,
            },
          ],
        }),
      );
      final vm = ClientEditViewModel(
        repo: repo,
        companyId: 'co',
        existing: existing,
      );
      final r = vm.applyImportedContact(
        const DeviceContactImport(phone: '555-123-4567'), // same digits
        countryId: '',
      );
      expect(r.contactWasDuplicate, isTrue);
      expect(r.contactAdded, isFalse);
      expect(vm.draft.contacts, hasLength(1));
      vm.dispose();
    });
  });
}
