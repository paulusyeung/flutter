import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests target AuthRepository's session-state contract:
///   * login persists tokens to TokenStorage AND companies/account to Drift,
///     AND seeds session + credentials
///   * switchCompany flips credentials to the right per-company token
///   * logout clears everything (in-memory + persistent)
///   * restore rebuilds session from disk on next launch
///   * restore detects a stale token (DB was wiped) and falls back to logout
/// They do NOT test http or flutter_secure_storage.

/// Programmable fake — each `login` call returns a queued response (or
/// throws if the test queued an error). Avoids hitting the network.
class _FakeAuthService implements AuthService {
  final List<Object> _outcomes = [];

  void queueLogin(LoginResponseApi response) => _outcomes.add(response);
  void queueLoginError(Object error) => _outcomes.add(error);

  @override
  Future<LoginResponseApi> login({
    required String baseUrl,
    required bool isHosted,
    required String email,
    required String password,
    String? oneTimePassword,
  }) async {
    if (_outcomes.isEmpty) {
      throw StateError('no login outcome queued');
    }
    final next = _outcomes.removeAt(0);
    if (next is LoginResponseApi) return next;
    throw next;
  }

  @override
  Future<void> recoverPassword({
    required String baseUrl,
    required bool isHosted,
    required String email,
  }) async {}

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

LoginResponseApi _envelope({
  List<({String id, String name, String token})> companies = const [
    (id: 'co_a', name: 'Acme', token: 'tok_a'),
  ],
  String defaultCompanyId = 'co_a',
  String accountId = 'acct_1',
}) {
  return LoginResponseApi(
    data: [
      for (final c in companies)
        UserCompanyApi(
          permissions: 'view_client,edit_client',
          company: CompanyEnvelopeApi(id: c.id, name: c.name),
          token: TokenApi(token: c.token),
          account: AccountEnvelopeApi(
            id: accountId,
            defaultCompanyId: defaultCompanyId,
            plan: 'pro',
            numTrialDays: 14,
          ),
        ),
    ],
  );
}

void main() {
  late AppDatabase db;
  late _FakeAuthService authService;
  late InMemoryTokenStorage storage;
  late AuthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    authService = _FakeAuthService();
    storage = InMemoryTokenStorage();
    repo = AuthRepository(
      db: db,
      authService: authService,
      tokenStorage: storage,
    );
  });
  tearDown(() async {
    await db.close();
  });

  group('login', () {
    test('persists tokens + companies and primes credentials', () async {
      authService.queueLogin(
        _envelope(
          companies: [
            (id: 'co_a', name: 'Acme', token: 'tok_a'),
            (id: 'co_b', name: 'Beta', token: 'tok_b'),
          ],
          defaultCompanyId: 'co_b',
        ),
      );

      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a@b',
        password: 'pw',
      );

      // Credentials prime the ApiClient with the default company's token.
      expect(repo.credentials.value!.token, 'tok_b');
      expect(repo.credentials.value!.baseUrl, 'https://test');
      expect(repo.session.value!.companies.map((c) => c.id), ['co_a', 'co_b']);
      expect(repo.session.value!.currentCompanyId, 'co_b');

      // Tokens reach secure storage (encoded JSON).
      final raw = await storage.read('invoiceninja.tokens.v1');
      expect(raw, isNotNull);
      expect(jsonDecode(raw!) as Map<String, dynamic>, {
        'co_a': 'tok_a',
        'co_b': 'tok_b',
      });

      // Companies + account land in Drift.
      final companies = await db.companiesDao.all();
      expect(companies.map((c) => c.id), containsAll(['co_a', 'co_b']));
      expect((await db.companiesDao.account())?.id, 'acct_1');
    });

    test('refuses an empty response (no companies)', () async {
      authService.queueLogin(const LoginResponseApi());
      await expectLater(
        () => repo.login(
          baseUrl: 'https://test',
          isHosted: false,
          email: 'a',
          password: 'b',
        ),
        throwsStateError,
      );
      expect(repo.session.value, isNull);
      expect(repo.credentials.value, isNull);
    });
  });

  group('switchCompany', () {
    test('updates credentials to the target company token', () async {
      authService.queueLogin(
        _envelope(
          companies: [
            (id: 'co_a', name: 'Acme', token: 'tok_a'),
            (id: 'co_b', name: 'Beta', token: 'tok_b'),
          ],
          defaultCompanyId: 'co_a',
        ),
      );
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      expect(repo.credentials.value!.token, 'tok_a');

      await repo.switchCompany('co_b');

      expect(repo.credentials.value!.token, 'tok_b');
      expect(repo.session.value!.currentCompanyId, 'co_b');
      expect(await storage.read('invoiceninja.current_company.v1'), 'co_b');
    });
  });

  group('logout', () {
    test('clears session, credentials, secure storage, and Drift', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );

      await repo.logout();

      expect(repo.session.value, isNull);
      expect(repo.credentials.value, isNull);
      expect(await storage.read('invoiceninja.tokens.v1'), isNull);
      expect(await db.companiesDao.all(), isEmpty);
      expect(await db.companiesDao.account(), isNull);
    });
  });

  group('restore', () {
    test('rebuilds session + credentials from disk on next launch', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );

      // Simulate "next launch" — a fresh repo against the same storage + DB.
      final fresh = AuthRepository(
        db: db,
        authService: authService,
        tokenStorage: storage,
      );
      expect(fresh.credentials.value, isNull, reason: 'before restore');

      await fresh.restore();

      expect(fresh.credentials.value!.token, 'tok_a');
      expect(fresh.session.value!.currentCompanyId, 'co_a');
    });

    test('detects stale token (DB wiped) and falls back to logout', () async {
      await storage.write(
        'invoiceninja.tokens.v1',
        jsonEncode({'co_a': 'tok_a'}),
      );
      await storage.write('invoiceninja.base_url.v1', 'https://test');
      // No companies in Drift — simulates a wiped local cache.

      await repo.restore();

      expect(repo.session.value, isNull);
      expect(repo.credentials.value, isNull);
      expect(
        await storage.read('invoiceninja.tokens.v1'),
        isNull,
        reason: 'logout drops the stale token so we re-login fresh',
      );
    });
  });
}
