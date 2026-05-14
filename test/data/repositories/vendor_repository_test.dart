import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/vendor_api_model.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/models/domain/vendor_contact.dart';
import 'package:admin/data/models/value/parsing.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/vendor_repository.dart';
import 'package:admin/data/services/vendors_api.dart';

import '_base_entity_repository_contract.dart';

/// Covers the universal `BaseEntityRepository` contract via the shared
/// harness and the entity-specific behaviour the contract doesn't probe
/// (contact mapping, tmp_-id stripping in `VendorContact.toApiJson`).
class _VendorFixture
    extends EntityRepositoryContractFixture<Vendor, VendorApi> {
  @override
  String get entityType => 'vendor';

  @override
  VendorRepository buildRepo(AppDatabase db) =>
      VendorRepository(db: db, api: _FakeVendorsApi());

  @override
  VendorApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) => VendorApi(
    id: id,
    name: displayValue ?? id,
    updatedAt: updatedAt,
  );

  @override
  Vendor fromApi(VendorApi api) => Vendor.fromApi(api);

  @override
  Vendor editCopy(Vendor item, {required String displayValue}) =>
      item.copyWith(name: displayValue);

  @override
  String idOf(Vendor item) => item.id;

  @override
  bool isDirtyOf(Vendor item) => item.isDirty;

  @override
  Future<Vendor> create(
    BaseEntityRepository<Vendor, VendorApi> repo, {
    required String companyId,
    required Vendor draft,
  }) => (repo as VendorRepository).create(companyId: companyId, draft: draft);

  @override
  Future<void> save(
    BaseEntityRepository<Vendor, VendorApi> repo, {
    required String companyId,
    required Vendor entity,
  }) => (repo as VendorRepository).save(companyId: companyId, vendor: entity);

  @override
  Future<void> delete(
    BaseEntityRepository<Vendor, VendorApi> repo, {
    required String companyId,
    required String id,
  }) => (repo as VendorRepository).delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_VendorFixture());

  group('VendorRepository — entity-specific', () {
    test(
      'VendorApi → Vendor round-trip preserves nested contacts in order',
      () {
        const api = VendorApi(
          id: 'v_1',
          name: 'Acme Co',
          contacts: [
            VendorContactApi(
              id: 'vc_1',
              firstName: 'Alice',
              lastName: 'Anders',
              email: 'alice@acme.test',
            ),
            VendorContactApi(
              id: 'vc_2',
              firstName: 'Bob',
              lastName: 'Brown',
              email: 'bob@acme.test',
            ),
          ],
        );
        final domain = Vendor.fromApi(api);
        expect(domain.contacts, hasLength(2));
        expect(domain.contacts[0].id, 'vc_1');
        expect(domain.contacts[0].firstName, 'Alice');
        expect(domain.contacts[0].lastName, 'Anders');
        expect(domain.contacts[1].id, 'vc_2');
        expect(domain.contacts[1].firstName, 'Bob');
        expect(domain.contacts[1].lastName, 'Brown');
      },
    );

    test(
      'VendorContact.toApiJson omits tmp_ ids by default but keeps them with '
      'preserveTempId — the create flow needs the server to allocate the id, '
      'local Drift persistence needs to keep watching the tmp row',
      () {
        final tmpContact = VendorContact(
          id: 'tmp_abc',
          firstName: 'New',
          lastName: 'Contact',
          email: 'new@acme.test',
          phone: '',
          password: '',
          sendEmail: true,
          isPrimary: false,
          customValue1: '',
          customValue2: '',
          customValue3: '',
          customValue4: '',
          updatedAt: epochSecondsToUtc(0),
          isDeleted: false,
        );

        final outbound = tmpContact.toApiJson();
        expect(
          outbound.containsKey('id'),
          isFalse,
          reason: 'tmp_ ids are stripped from the outbound payload',
        );

        final local = tmpContact.toApiJson(preserveTempId: true);
        expect(
          local['id'],
          'tmp_abc',
          reason: 'preserveTempId keeps the temp id for local Drift round-trip',
        );

        // And confirm real ids round-trip both ways.
        final saved = tmpContact.copyWith(id: 'vc_real');
        expect(saved.toApiJson()['id'], 'vc_real');
        expect(saved.toApiJson(preserveTempId: true)['id'], 'vc_real');
      },
    );
  });

  // Sanity-check that the in-memory DB harness still composes cleanly for
  // future tests added to this group.
  group('VendorRepository — DB smoke', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    test('repo can be constructed against an in-memory DB', () {
      final repo = VendorRepository(db: db, api: _FakeVendorsApi());
      expect(repo.entityTypeName, 'vendor');
    });
  });
}

class _FakeVendorsApi implements VendorsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
