import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_api_model.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/companies_api.dart';

/// Stub returning a canned Singapore setup result. Records that
/// `peppolSetupWithRedirect` was the method invoked (not the EU
/// outbox-dispatched `peppolSetup`).
class _SgStubApi implements CompaniesApi {
  _SgStubApi({required this.company, this.corppassUrl});
  final CompanyItemApi company;
  final String? corppassUrl;
  int calls = 0;

  @override
  Future<({CompanyItemApi company, String? corppassUrl})>
      peppolSetupWithRedirect({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    calls++;
    return (company: company, corppassUrl: corppassUrl);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> seed(String id) async {
    await db.companiesDao.upsertAll([
      CompaniesCompanion.insert(
        id: id,
        name: 'Acme',
        displayName: const Value('Acme'),
        settings: jsonEncode({'name': 'Acme', 'country_id': '702'}),
        permissions: '',
        accountId: 'acct',
        token: 'tok',
        updatedAt: 1700000000,
      ),
    ]);
  }

  CompanyItemApi resp(String id, {int legalEntityId = 42}) => CompanyItemApi(
        data: CompanyApi(
          id: id,
          name: 'Acme',
          settings: const {'name': 'Acme', 'country_id': '702'},
          legalEntityId: legalEntityId,
          updatedAt: 1900000000,
        ),
      );

  test('peppolSetupDirect applies the company to Drift, returns corppassUrl, '
      'and creates NO outbox row', () async {
    const companyId = 'co';
    await seed(companyId);
    final api = _SgStubApi(
      company: resp(companyId),
      corppassUrl: 'https://corppass.gov.sg/auth',
    );
    final repo = CompanyRepository(
      db: db,
      api: api,
      uuid: const Uuid(),
      now: () => DateTime.utc(2026, 5, 11, 12),
    );

    final url = await repo.peppolSetupDirect(
      companyId: companyId,
      payload: const {'country': '702', 'id_number': 'UEN9'},
    );

    expect(api.calls, 1);
    expect(url, 'https://corppass.gov.sg/auth');
    // Company envelope applied to Drift (legal_entity_id landed).
    final row = await db.companiesDao.byId(companyId);
    expect(row, isNotNull);
    expect(row!.updatedAt, 1900000000);
    // Deliberate direct path → NOT queued through the outbox.
    final pending = await db.outboxDao.nextReady(
      companyId: companyId,
      now: 1 << 60,
    );
    expect(pending, isEmpty,
        reason: 'SG setup is a direct request, not an outbox mutation');
  });

  test('empty corppass_url → null (registration was immediate)', () async {
    const companyId = 'co';
    await seed(companyId);
    final repo = CompanyRepository(
      db: db,
      api: _SgStubApi(company: resp(companyId), corppassUrl: ''),
      uuid: const Uuid(),
      now: () => DateTime.utc(2026, 5, 11, 12),
    );
    final url = await repo.peppolSetupDirect(
      companyId: companyId,
      payload: const {'country': '702'},
    );
    expect(url, isNull);
  });
}
