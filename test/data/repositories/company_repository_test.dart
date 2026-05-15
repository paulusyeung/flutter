import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_registration_field_api_model.dart';
import 'package:admin/data/models/api/company_api_model.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/domain/sync/mutation.dart';

class _FakeCompaniesApi implements CompaniesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StubCompaniesApi implements CompaniesApi {
  _StubCompaniesApi(this.response);
  final CompanyItemApi response;

  @override
  Future<CompanyItemApi> get(String id) async => response;

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  CompanyRepository makeRepo() => CompanyRepository(
    db: db,
    api: _FakeCompaniesApi(),
    uuid: const Uuid(),
    now: () => DateTime.utc(2026, 5, 11, 12),
  );

  Future<void> seedCompany(
    String id, {
    String name = 'Acme',
    Map<String, dynamic> settings = const {'name': 'Acme'},
    Map<String, String> customFields = const {},
  }) async {
    await db.companiesDao.upsertAll([
      CompaniesCompanion.insert(
        id: id,
        name: name,
        displayName: Value(name),
        settings: jsonEncode(settings),
        customFields: Value(jsonEncode(customFields)),
        permissions: '',
        accountId: 'acct',
        token: 'tok',
        updatedAt: 1700000000,
      ),
    ]);
  }

  group('updateCompany', () {
    test(
      'writes the new settings JSON and enqueues an update outbox row',
      () async {
        const companyId = 'co';
        await seedCompany(companyId);
        final repo = makeRepo();

        final current = await repo.get(companyId);
        expect(current, isNotNull);
        final draft = current!.copyWith(
          settings: current.settings.copyWith(
            name: 'Acme Renamed',
            idNumber: 'REG-9',
          ),
        );

        await repo.updateCompany(draft: draft);

        final row = await db.companiesDao.byId(companyId);
        expect(row, isNotNull);
        final decoded = jsonDecode(row!.settings) as Map<String, dynamic>;
        expect(decoded['name'], 'Acme Renamed');
        expect(decoded['id_number'], 'REG-9');

        final pending = await db.outboxDao.nextReady(
          companyId: companyId,
          now: 1 << 60,
        );
        expect(pending, hasLength(1));
        expect(pending.single.mutationKind, MutationKind.update.wireName);
        expect(pending.single.entityType, 'company');
        expect(pending.single.entityId, companyId);
        expect(pending.single.idempotencyKey, isNotEmpty);
      },
    );

    test('preserves unknown settings keys across the round-trip', () async {
      // An "unknown" field is one the typed `CompanySettingsApi` doesn't
      // model. The original implementation silently dropped these on every
      // save, corrupting fields like `mailgun_secret` server-side.
      const companyId = 'co';
      await seedCompany(
        companyId,
        settings: const {
          'name': 'Acme',
          // Real fields we don't currently model:
          'mailgun_secret': 'super-secret',
          'a_brand_new_field_we_dont_model': 42,
        },
      );
      final repo = makeRepo();

      final current = await repo.get(companyId);
      final draft = current!.copyWith(
        settings: current.settings.copyWith(name: 'Acme Renamed'),
      );
      await repo.updateCompany(draft: draft);

      // Drift row keeps the unknown keys.
      final row = await db.companiesDao.byId(companyId);
      final stored = jsonDecode(row!.settings) as Map<String, dynamic>;
      expect(stored['name'], 'Acme Renamed');
      expect(stored['mailgun_secret'], 'super-secret');
      expect(stored['a_brand_new_field_we_dont_model'], 42);

      // Outbox payload (what gets PUT'd to the server) also keeps them.
      final pending = await db.outboxDao.nextReady(
        companyId: companyId,
        now: 1 << 60,
      );
      final payload =
          jsonDecode(pending.single.payload) as Map<String, dynamic>;
      final settings = payload['settings'] as Map<String, dynamic>;
      expect(settings['name'], 'Acme Renamed');
      expect(settings['mailgun_secret'], 'super-secret');
      expect(settings['a_brand_new_field_we_dont_model'], 42);
    });

    test(
      'persists portal fields and clientRegistrationFields edits',
      () async {
        const companyId = 'co';
        await seedCompany(companyId);
        final repo = makeRepo();

        final current = await repo.get(companyId);
        final draft = current!.copyWith(
          subdomain: 'acme',
          portalDomain: 'https://billing.acme.test',
          portalMode: 'subdomain',
          companyKey: 'CK1',
          clientRegistrationFields: [
            const ClientRegistrationFieldApi(
              key: 'email',
              required: true,
              visible: true,
            ),
            const ClientRegistrationFieldApi(
              key: 'phone',
              required: false,
              visible: true,
            ),
          ],
        );
        await repo.updateCompany(draft: draft);

        final row = await db.companiesDao.byId(companyId);
        expect(row!.subdomain, 'acme');
        expect(row.portalDomain, 'https://billing.acme.test');
        expect(row.portalMode, 'subdomain');
        expect(row.companyKey, 'CK1');
        final decoded = jsonDecode(row.clientRegistrationFields) as List;
        expect(decoded, hasLength(2));
        expect(decoded.first, {
          'key': 'email',
          'required': true,
          'visible': true,
        });

        final reloaded = await repo.get(companyId);
        expect(reloaded!.subdomain, 'acme');
        expect(reloaded.clientRegistrationFields, hasLength(2));
        expect(reloaded.clientRegistrationFields.first.key, 'email');
        expect(reloaded.clientRegistrationFields.first.required, true);
      },
    );

    test('persists custom_fields edits', () async {
      const companyId = 'co';
      await seedCompany(companyId);
      final repo = makeRepo();

      final current = await repo.get(companyId);
      final draft = current!.copyWith(
        customFields: const {'company1': 'Department|single_line_text'},
      );
      await repo.updateCompany(draft: draft);

      final row = await db.companiesDao.byId(companyId);
      final decoded = jsonDecode(row!.customFields) as Map<String, dynamic>;
      expect(decoded['company1'], 'Department|single_line_text');

      // Round-trip through the repo's `_fromRow` — should see the same map.
      final reloaded = await repo.get(companyId);
      expect(reloaded!.customFields, {
        'company1': 'Department|single_line_text',
      });
    });
  });

  group('applyUpdateResponse', () {
    test('overwrites settings + custom_fields with the server body', () async {
      const companyId = 'co';
      await seedCompany(companyId);
      final repo = makeRepo();

      final response = CompanyApi(
        id: companyId,
        name: 'Acme',
        settings: const {'name': 'Acme Inc', 'country_id': '276'},
        customFields: const {'company1': 'Department|single_line_text'},
        updatedAt: 1900000000,
      );

      await repo.applyUpdateResponse(
        companyId: companyId,
        serverResponse: response,
      );

      final row = await db.companiesDao.byId(companyId);
      final decodedSettings = jsonDecode(row!.settings) as Map<String, dynamic>;
      expect(decodedSettings['name'], 'Acme Inc');
      expect(decodedSettings['country_id'], '276');
      final decodedCustom =
          jsonDecode(row.customFields) as Map<String, dynamic>;
      expect(decodedCustom['company1'], 'Department|single_line_text');
      expect(row.updatedAt, 1900000000);
    });
  });

  group('refresh', () {
    test('upserts the GET /companies/{id} response into Drift', () async {
      const companyId = 'co';
      await seedCompany(companyId);
      final response = CompanyItemApi(
        data: CompanyApi(
          id: companyId,
          name: 'Acme',
          settings: const {'name': 'Acme Inc', 'country_id': '276'},
          customFields: const {'company1': 'Department|single_line_text'},
          sizeId: '4',
          industryId: '11',
          legalEntityId: 0,
          updatedAt: 1900000000,
        ),
      );
      final repo = CompanyRepository(
        db: db,
        api: _StubCompaniesApi(response),
        uuid: const Uuid(),
        now: () => DateTime.utc(2026, 5, 11, 12),
      );

      await repo.refresh(companyId);

      final row = await db.companiesDao.byId(companyId);
      final settings = jsonDecode(row!.settings) as Map<String, dynamic>;
      expect(settings['name'], 'Acme Inc');
      expect(settings['country_id'], '276');
      final custom = jsonDecode(row.customFields) as Map<String, dynamic>;
      expect(custom['company1'], 'Department|single_line_text');
      expect(row.sizeId, '4');
      expect(row.industryId, '11');
    });

    test(
      'swallows errors so the page can still render the cached row',
      () async {
        const companyId = 'co';
        await seedCompany(companyId);
        final repo = CompanyRepository(
          db: db,
          api: _FakeCompaniesApi(), // throws on every call
          uuid: const Uuid(),
        );

        await repo.refresh(companyId); // must not throw
      },
    );

    test('no-op for empty companyId', () async {
      final repo = CompanyRepository(
        db: db,
        api: _FakeCompaniesApi(), // would throw if called
        uuid: const Uuid(),
      );

      await repo.refresh(''); // must not invoke the api
    });
  });

  group('_fromRow hardening', () {
    test(
      'parses loose-type numeric/bool fields via the lenient parser',
      () async {
        // Regression for the form-rendering-blank bug: the live server sends
        // `reset_counter_frequency_id` as a String, which used to crash the
        // strict parser and trigger the empty-typed fallback. The lenient
        // parser coerces it; the form sees real values.
        const companyId = 'co';
        await seedCompany(
          companyId,
          settings: const {
            'name': 'Acme',
            'reset_counter_frequency_id': '1',
            'tax_rate1': '19.5',
            'military_time': 1,
          },
        );
        final repo = makeRepo();

        final company = await repo.get(companyId);
        expect(company, isNotNull);
        expect(company!.settings.name, 'Acme');
        expect(company.settings.resetCounterFrequencyId, 1);
        expect(company.settings.taxRate1, 19.5);
        expect(company.settings.militaryTime, true);
      },
    );

    test('survives a TypeError in CompanySettingsApi.fromJson', () async {
      // Invoice Ninja occasionally returns legacy booleans as `0`/`1` ints.
      // The generated `fromJson` uses bare `as bool?` casts, which throw.
      // The repo must catch that so the UI doesn't get stuck on a spinner —
      // `rawSettings` is preserved so the eventual PUT round-trip is intact.
      const companyId = 'co';
      await seedCompany(
        companyId,
        settings: const {
          'name': 'Acme',
          'enable_reminder1': 0, // <-- the trap
          'a_brand_new_field_we_dont_model': 'untouched',
        },
      );
      final repo = makeRepo();

      final company = await repo.get(companyId);
      expect(company, isNotNull);
      // Typed view falls back to empty; raw map keeps every original key
      // so the merge in `updateCompany` can round-trip them.
      expect(company!.rawSettings['name'], 'Acme');
      expect(company.rawSettings['enable_reminder1'], 0);
      expect(
        company.rawSettings['a_brand_new_field_we_dont_model'],
        'untouched',
      );
    });
  });

  group('uploadLogo', () {
    test('enqueues an outbox row carrying the local file path', () async {
      const companyId = 'co';
      await seedCompany(companyId);
      final repo = makeRepo();

      await repo.uploadLogo(companyId: companyId, localPath: '/tmp/logo.png');

      final pending = await db.outboxDao.nextReady(
        companyId: companyId,
        now: 1 << 60,
      );
      expect(pending, hasLength(1));
      final payload =
          jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expect(payload['_action'], 'upload_logo');
      expect(payload['local_path'], '/tmp/logo.png');
    });
  });
}
