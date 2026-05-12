import 'dart:async';
import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
  List<({String id, String name, String token, bool isAdmin, bool isOwner})>
  companies = const [
    (id: 'co_a', name: 'Acme', token: 'tok_a', isAdmin: false, isOwner: false),
  ],
  String defaultCompanyId = 'co_a',
  String accountId = 'acct_1',
  Map<String, Map<String, dynamic>> settingsByCompanyId = const {},
}) {
  return LoginResponseApi(
    data: [
      for (final c in companies)
        UserCompanyApi(
          permissions: 'view_client,edit_client',
          isAdmin: c.isAdmin,
          isOwner: c.isOwner,
          company: CompanyEnvelopeApi(
            id: c.id,
            name: c.name,
            settings: settingsByCompanyId[c.id] ?? const <String, dynamic>{},
          ),
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
  late PasswordCache passwordCache;
  late AuthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    authService = _FakeAuthService();
    storage = InMemoryTokenStorage();
    passwordCache = PasswordCache();
    repo = AuthRepository(
      db: db,
      authService: authService,
      tokenStorage: storage,
      passwordCache: passwordCache,
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
            (
              id: 'co_a',
              name: 'Acme',
              token: 'tok_a',
              isAdmin: false,
              isOwner: false,
            ),
            (
              id: 'co_b',
              name: 'Beta',
              token: 'tok_b',
              isAdmin: false,
              isOwner: false,
            ),
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
            (
              id: 'co_a',
              name: 'Acme',
              token: 'tok_a',
              isAdmin: false,
              isOwner: false,
            ),
            (
              id: 'co_b',
              name: 'Beta',
              token: 'tok_b',
              isAdmin: false,
              isOwner: false,
            ),
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

    test('refuses to activate a company whose cached token is empty', () async {
      // Bug repro: a /refresh response that returned an empty `token` for the
      // non-active company used to land in _tokensByCompany as ''. The
      // null-only guard let it through, ApiClient sent a blank X-API-Token,
      // the server 401'd, and the user got bounced to /login. Login with one
      // bad token to seed the same shape and prove the guard now catches it.
      authService.queueLogin(
        _envelope(
          companies: [
            (
              id: 'co_a',
              name: 'Acme',
              token: 'tok_a',
              isAdmin: false,
              isOwner: false,
            ),
            (
              id: 'co_b',
              name: 'Beta',
              token: '',
              isAdmin: false,
              isOwner: false,
            ),
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

      expect(
        repo.credentials.value!.token,
        'tok_a',
        reason: 'empty cached token must not replace a working one',
      );
      expect(
        repo.session.value!.currentCompanyId,
        'co_a',
        reason: 'session stays on the previously-active company',
      );
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
      // Simulate a destructive-action confirm: password lives in the cache
      // until logout or TTL. Without an explicit clear in logout(), this
      // string would survive into the next user's session.
      passwordCache.set('user-password');
      expect(passwordCache.read(), 'user-password');

      await repo.logout();

      expect(repo.session.value, isNull);
      expect(repo.credentials.value, isNull);
      expect(await storage.read('invoiceninja.tokens.v1'), isNull);
      expect(await db.companiesDao.all(), isEmpty);
      expect(await db.companiesDao.account(), isNull);
      expect(
        passwordCache.read(),
        isNull,
        reason: 'logout must clear the in-memory password cache',
      );
    });

    test(
      'awaits onBeforeLogout before wiping Drift so in-flight sync settles',
      () async {
        authService.queueLogin(_envelope());
        await repo.login(
          baseUrl: 'https://test',
          isHosted: false,
          email: 'a',
          password: 'b',
        );

        // Resolve the hook's gate only after asserting Drift is still
        // populated — proves logout() really did `await` the hook before
        // the wipe (otherwise this races with `db.wipe`).
        final gate = Completer<void>();
        var hookCalled = false;
        repo.onBeforeLogout = () async {
          hookCalled = true;
          await gate.future;
        };

        final logoutFuture = repo.logout();
        await Future<void>.delayed(Duration.zero);
        expect(hookCalled, isTrue);
        expect(await db.companiesDao.all(), isNotEmpty, reason: 'wipe waits');
        gate.complete();
        await logoutFuture;
        expect(await db.companiesDao.all(), isEmpty);
      },
    );

    test('logout completes even if onBeforeLogout throws', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      repo.onBeforeLogout = () async => throw StateError('hook blew up');

      await repo.logout(); // must not rethrow

      expect(repo.session.value, isNull);
      expect(await db.companiesDao.all(), isEmpty);
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
        passwordCache: passwordCache,
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

    test(
      'preserves displayName (from settings.name) and logo across restart',
      () async {
        authService.queueLogin(
          _envelope(
            settingsByCompanyId: const {
              'co_a': {
                'name': 'Acme Co',
                'company_logo': 'https://logo.example/acme.png',
              },
            },
          ),
        );
        await repo.login(
          baseUrl: 'https://test',
          isHosted: false,
          email: 'a',
          password: 'b',
        );

        // Cold start: fresh repo, same DB + secure storage.
        final fresh = AuthRepository(
          db: db,
          authService: authService,
          tokenStorage: storage,
          passwordCache: passwordCache,
        );
        await fresh.restore();

        final c = fresh.session.value!.companies.single;
        expect(
          c.displayName,
          'Acme Co',
          reason: 'settings.name should win over the empty top-level name',
        );
        expect(
          c.logoUrl,
          'https://logo.example/acme.png',
          reason: 'logo_url column should survive the round-trip',
        );
      },
    );

    test('preserves isAdmin/isOwner across restart', () async {
      authService.queueLogin(
        _envelope(
          companies: [
            (
              id: 'co_a',
              name: 'Acme',
              token: 'tok_a',
              isAdmin: true,
              isOwner: true,
            ),
          ],
        ),
      );
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      expect(repo.session.value!.companies.single.isAdmin, isTrue);

      final fresh = AuthRepository(
        db: db,
        authService: authService,
        tokenStorage: storage,
        passwordCache: passwordCache,
      );
      await fresh.restore();

      final c = fresh.session.value!.companies.single;
      expect(c.isAdmin, isTrue, reason: 'admin flag survives restart');
      expect(c.isOwner, isTrue, reason: 'owner flag survives restart');
    });

    group('background /refresh heal', () {
      // The v4 schema migration added `is_owner` / `is_admin` columns with
      // DEFAULT false and didn't backfill — so an account owner who upgrades
      // through that bump without re-logging in stays silently downgraded
      // (the company picker shows "Only the account owner can add companies"
      // even though they are). restore() now re-pulls /api/v1/refresh in the
      // background so these flags self-heal on next launch.

      LoginResponseApi refreshed({required bool isOwner}) => _envelope(
        companies: [
          (
            id: 'co_a',
            name: 'Acme',
            token: 'tok_a',
            isAdmin: isOwner,
            isOwner: isOwner,
          ),
        ],
      );

      test('promotes a stale is_owner=false to true via /refresh', () async {
        // Seed the world as if the user had logged in pre-v4: tokens in
        // secure storage, companies row in Drift with is_owner=false.
        authService.queueLogin(
          _envelope(
            companies: [
              (
                id: 'co_a',
                name: 'Acme',
                token: 'tok_a',
                isAdmin: false,
                isOwner: false,
              ),
            ],
          ),
        );
        await repo.login(
          baseUrl: 'https://test',
          isHosted: false,
          email: 'a',
          password: 'b',
        );

        // Now spin up a fresh repo (simulating a cold start) wired to a fake
        // ApiClient. The fake returns the *corrected* envelope on /refresh.
        final refreshHit = Completer<Uri>();
        final fakeHttp = MockClient((req) async {
          if (req.url.path == '/api/v1/refresh') {
            refreshHit.complete(req.url);
            return http.Response(
              jsonEncode(refreshed(isOwner: true).toJson()),
              200,
            );
          }
          return http.Response('not found', 404);
        });
        final fresh = AuthRepository(
          db: db,
          authService: authService,
          tokenStorage: storage,
          passwordCache: passwordCache,
        );
        fresh.apiClient = ApiClient(
          credentials: fresh.credentials,
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: fakeHttp,
        );

        // Listen for the moment _persistAndActivate writes the healed
        // session — more reliable than guessing how many microtasks the
        // background refresh needs.
        final healed = Completer<void>();
        fresh.session.addListener(() {
          if (!healed.isCompleted &&
              fresh.session.value?.currentCompany?.isOwner == true) {
            healed.complete();
          }
        });

        await fresh.restore();
        // restore() restored is_owner=false from Drift.
        expect(fresh.session.value!.currentCompany!.isOwner, isFalse);

        await refreshHit.future.timeout(const Duration(seconds: 2));
        await healed.future.timeout(const Duration(seconds: 2));

        expect(
          fresh.session.value!.currentCompany!.isOwner,
          isTrue,
          reason: '/refresh response should heal the stale flag in memory',
        );
        final rowAfter = (await db.companiesDao.all()).single;
        expect(
          rowAfter.isOwner,
          isTrue,
          reason: 'and persist back to Drift so it survives the next restart',
        );
      });

      test('preserves cached tokens when /refresh returns empty ones', () async {
        // Bug repro: /api/v1/refresh?current_company=false has been observed
        // returning empty `token` strings for non-active companies. Before
        // the fix, _persistAndActivate would overwrite the cached tokens
        // with '', so the next switchCompany activated a blank token, hit
        // 401 on the first request, and bounced the user to /login.
        authService.queueLogin(
          _envelope(
            companies: [
              (
                id: 'co_a',
                name: 'Acme',
                token: 'tok_a',
                isAdmin: false,
                isOwner: false,
              ),
              (
                id: 'co_b',
                name: 'Beta',
                token: 'tok_b',
                isAdmin: false,
                isOwner: false,
              ),
            ],
          ),
        );
        await repo.login(
          baseUrl: 'https://test',
          isHosted: false,
          email: 'a',
          password: 'b',
        );

        final fakeHttp = MockClient((req) async {
          if (req.url.path == '/api/v1/refresh') {
            final body = _envelope(
              companies: [
                // Active company keeps its token...
                (
                  id: 'co_a',
                  name: 'Acme',
                  token: 'tok_a',
                  isAdmin: false,
                  isOwner: false,
                ),
                // ...but the non-active one comes back empty (the wire bug).
                (
                  id: 'co_b',
                  name: 'Beta',
                  token: '',
                  isAdmin: false,
                  isOwner: false,
                ),
              ],
            ).toJson();
            return http.Response(jsonEncode(body), 200);
          }
          return http.Response('not found', 404);
        });
        final fresh = AuthRepository(
          db: db,
          authService: authService,
          tokenStorage: storage,
          passwordCache: passwordCache,
        );
        fresh.apiClient = ApiClient(
          credentials: fresh.credentials,
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: fakeHttp,
        );

        await fresh.restore();
        // Wait until the background refresh has flowed through
        // _persistAndActivate (which assigns _session.value last).
        final refreshed = Completer<void>();
        fresh.session.addListener(() {
          if (!refreshed.isCompleted) refreshed.complete();
        });
        // The session also got set inside restore() before the listener was
        // attached — only the post-refresh assignment will fire it.
        await refreshed.future.timeout(const Duration(seconds: 2));

        // Cached token for co_b must still work after the empty-token /refresh.
        await fresh.switchCompany('co_b');
        expect(
          fresh.credentials.value!.token,
          'tok_b',
          reason: 'good cached token must survive an empty /refresh response',
        );
      });

      test(
        'drops cached tokens for companies the server stops returning',
        () async {
          // User had access to A + B at login. Server later revokes B. /refresh
          // returns only A. The stale B token shouldn't linger in the cache —
          // a subsequent switchCompany('co_b') must be a no-op, not a quiet
          // attempt against a revoked token.
          authService.queueLogin(
            _envelope(
              companies: [
                (
                  id: 'co_a',
                  name: 'Acme',
                  token: 'tok_a',
                  isAdmin: false,
                  isOwner: false,
                ),
                (
                  id: 'co_b',
                  name: 'Beta',
                  token: 'tok_b',
                  isAdmin: false,
                  isOwner: false,
                ),
              ],
            ),
          );
          await repo.login(
            baseUrl: 'https://test',
            isHosted: false,
            email: 'a',
            password: 'b',
          );

          final fakeHttp = MockClient((req) async {
            if (req.url.path == '/api/v1/refresh') {
              final body = _envelope(
                companies: [
                  (
                    id: 'co_a',
                    name: 'Acme',
                    token: 'tok_a',
                    isAdmin: false,
                    isOwner: false,
                  ),
                ],
              ).toJson();
              return http.Response(jsonEncode(body), 200);
            }
            return http.Response('not found', 404);
          });
          final fresh = AuthRepository(
            db: db,
            authService: authService,
            tokenStorage: storage,
            passwordCache: passwordCache,
          );
          fresh.apiClient = ApiClient(
            credentials: fresh.credentials,
            passwordCache: PasswordCache(),
            onUnauthorized: () async {},
            httpClient: fakeHttp,
          );

          await fresh.restore();
          // Wait until the background refresh shrinks the company list to 1.
          final shrunk = Completer<void>();
          fresh.session.addListener(() {
            if (!shrunk.isCompleted &&
                fresh.session.value?.companies.length == 1) {
              shrunk.complete();
            }
          });
          await shrunk.future.timeout(const Duration(seconds: 2));

          await fresh.switchCompany('co_b');
          expect(
            fresh.credentials.value!.token,
            'tok_a',
            reason: 'cached token for a revoked company must be dropped',
          );
        },
      );

      test('leaves the restored session intact when /refresh fails', () async {
        // Same setup as the happy-path test, but the fake throws — simulating
        // offline. restore() must still produce a usable session.
        authService.queueLogin(
          _envelope(
            companies: [
              (
                id: 'co_a',
                name: 'Acme',
                token: 'tok_a',
                isAdmin: false,
                isOwner: false,
              ),
            ],
          ),
        );
        await repo.login(
          baseUrl: 'https://test',
          isHosted: false,
          email: 'a',
          password: 'b',
        );

        final refreshHit = Completer<void>();
        final fakeHttp = MockClient((req) async {
          if (!refreshHit.isCompleted) refreshHit.complete();
          throw http.ClientException('offline');
        });
        final fresh = AuthRepository(
          db: db,
          authService: authService,
          tokenStorage: storage,
          passwordCache: passwordCache,
        );
        fresh.apiClient = ApiClient(
          credentials: fresh.credentials,
          passwordCache: PasswordCache(),
          onUnauthorized: () async {},
          httpClient: fakeHttp,
        );

        await fresh.restore();
        await refreshHit.future.timeout(const Duration(seconds: 2));
        // One extra microtask round so the swallowed-error catch in
        // `_refreshSessionQuietly` resolves before the assertions run.
        await Future<void>.delayed(Duration.zero);

        expect(
          fresh.session.value,
          isNotNull,
          reason: 'session survives a failed background refresh',
        );
        expect(fresh.credentials.value!.token, 'tok_a');
      });
    });

    test('bounces to logged-out state when tokens map is missing the current '
        'companyId', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );

      // Tamper: overwrite the tokens blob so the cached company id has no
      // entry. This is the only failure mode of `restore()` short of a
      // disk corruption — exercise it explicitly.
      await storage.write(
        'invoiceninja.tokens.v1',
        jsonEncode({'co_other': 'tok_other'}),
      );

      final fresh = AuthRepository(
        db: db,
        authService: authService,
        tokenStorage: storage,
        passwordCache: passwordCache,
      );
      await fresh.restore();

      expect(fresh.session.value, isNull);
      expect(fresh.credentials.value, isNull);
      expect(
        await storage.read('invoiceninja.tokens.v1'),
        isNull,
        reason: 'logout drops the stale token map',
      );
    });
  });

  group('companies watcher', () {
    // Bug repro: editing the company name on Settings → Company Details writes
    // the new settings JSON to Drift but used to leave AuthSession.companies
    // stale until the next /refresh or app restart — so the sidebar picker
    // showed the old name. AuthRepository now subscribes to the companies
    // table and rebuilds the session slice on every change.
    test('flips session displayName when settings.name is edited', () async {
      authService.queueLogin(
        _envelope(
          settingsByCompanyId: const {
            'co_a': {'name': 'Acme Co'},
          },
        ),
      );
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      expect(repo.session.value!.currentCompany!.displayName, 'Acme Co');

      // Wait for the next session emission triggered by the Drift write.
      final updated = Completer<void>();
      repo.session.addListener(() {
        if (!updated.isCompleted &&
            repo.session.value?.currentCompany?.displayName == 'Acme Renamed') {
          updated.complete();
        }
      });

      await (db.update(db.companies)..where((c) => c.id.equals('co_a'))).write(
        CompaniesCompanion(
          settings: Value(jsonEncode({'name': 'Acme Renamed'})),
        ),
      );

      await updated.future.timeout(const Duration(seconds: 2));
      expect(repo.session.value!.currentCompany!.displayName, 'Acme Renamed');
    });

    test('no emit when no display-relevant column changed', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      final before = repo.session.value;
      var emissions = 0;
      repo.session.addListener(() {
        if (!identical(repo.session.value, before)) emissions++;
      });

      // updated_at touches a column the watcher rebuild does not consider.
      await (db.update(db.companies)..where((c) => c.id.equals('co_a'))).write(
        const CompaniesCompanion(updatedAt: Value(9999)),
      );
      // Let the Drift stream + microtasks settle.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        emissions,
        0,
        reason: 'updated_at-only writes must not bounce the session value',
      );
      expect(identical(repo.session.value, before), isTrue);
    });

    test('survives logout + login (subscription is re-attached)', () async {
      authService.queueLogin(
        _envelope(
          settingsByCompanyId: const {
            'co_a': {'name': 'Acme One'},
          },
        ),
      );
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      await repo.logout();

      authService.queueLogin(
        _envelope(
          settingsByCompanyId: const {
            'co_a': {'name': 'Acme Two'},
          },
        ),
      );
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      expect(repo.session.value!.currentCompany!.displayName, 'Acme Two');

      final updated = Completer<void>();
      repo.session.addListener(() {
        if (!updated.isCompleted &&
            repo.session.value?.currentCompany?.displayName == 'Acme Three') {
          updated.complete();
        }
      });
      await (db.update(db.companies)..where((c) => c.id.equals('co_a'))).write(
        CompaniesCompanion(settings: Value(jsonEncode({'name': 'Acme Three'}))),
      );
      await updated.future.timeout(const Duration(seconds: 2));
    });
  });

  group('biometric', () {
    test('setBiometricEnabled persists and updates session', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      expect(repo.session.value!.biometricEnabled, isFalse);

      await repo.setBiometricEnabled(true);
      expect(repo.session.value!.biometricEnabled, isTrue);
      expect(await storage.read('invoiceninja.biometric_enabled.v1'), 'true');

      await repo.setBiometricEnabled(false);
      expect(repo.session.value!.biometricEnabled, isFalse);
      expect(
        await storage.read('invoiceninja.biometric_enabled.v1'),
        isNull,
        reason: 'disabling deletes the key rather than writing "false"',
      );
    });

    test('logout clears the biometric flag', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      await repo.setBiometricEnabled(true);
      await repo.logout();
      expect(
        await storage.read('invoiceninja.biometric_enabled.v1'),
        isNull,
        reason:
            'leaving the flag would surface a lock with no session behind it',
      );
      expect(repo.requiresBiometricUnlock.value, isFalse);
    });

    test('restore sets requiresBiometricUnlock when flag was on', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      await repo.setBiometricEnabled(true);

      // Second AuthRepository sharing the same storage + db simulates a
      // cold launch.
      final repo2 = AuthRepository(
        db: db,
        authService: authService,
        tokenStorage: storage,
        passwordCache: PasswordCache(),
      );
      await repo2.restore();

      expect(repo2.isAuthenticated, isTrue);
      expect(repo2.session.value!.biometricEnabled, isTrue);
      expect(repo2.requiresBiometricUnlock.value, isTrue);
    });

    test('restore leaves the gate down when flag was off', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );

      final repo2 = AuthRepository(
        db: db,
        authService: authService,
        tokenStorage: storage,
        passwordCache: PasswordCache(),
      );
      await repo2.restore();

      expect(repo2.requiresBiometricUnlock.value, isFalse);
    });

    test('completeBiometricUnlock flips the gate', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      await repo.setBiometricEnabled(true);

      final repo2 = AuthRepository(
        db: db,
        authService: authService,
        tokenStorage: storage,
        passwordCache: PasswordCache(),
      );
      await repo2.restore();

      // Notify listener fires when the lock drops.
      var fired = 0;
      repo2.requiresBiometricUnlock.addListener(() => fired++);
      repo2.completeBiometricUnlock();
      expect(repo2.requiresBiometricUnlock.value, isFalse);
      expect(fired, 1);
      // Idempotent: a second call doesn't re-fire.
      repo2.completeBiometricUnlock();
      expect(fired, 1);
    });
  });

  group('onActiveCompanyChanged hook', () {
    // The hook is wired by DI to SyncRepository.drainOnce so pending outbox
    // rows for the active company flush right after the active company
    // becomes non-null or switches.
    test('fires from login with the activated company id', () async {
      authService.queueLogin(_envelope());
      final calls = <String>[];
      repo.onActiveCompanyChanged = calls.add;

      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );

      expect(calls, ['co_a']);
    });

    test('fires from switchCompany with the target company id', () async {
      authService.queueLogin(
        _envelope(
          companies: [
            (
              id: 'co_a',
              name: 'Acme',
              token: 'tok_a',
              isAdmin: false,
              isOwner: false,
            ),
            (
              id: 'co_b',
              name: 'Beta',
              token: 'tok_b',
              isAdmin: false,
              isOwner: false,
            ),
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

      // Wire the hook AFTER login so the login-side fire-through doesn't
      // pollute this assertion.
      final calls = <String>[];
      repo.onActiveCompanyChanged = calls.add;

      await repo.switchCompany('co_b');

      expect(calls, ['co_b']);
    });

    test('fires from restore so a cold-launched session drains too', () async {
      // Seed the user once, then build a fresh repo to simulate next launch.
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );

      final fresh = AuthRepository(
        db: db,
        authService: authService,
        tokenStorage: storage,
        passwordCache: passwordCache,
      );
      final calls = <String>[];
      fresh.onActiveCompanyChanged = calls.add;

      await fresh.restore();
      // The background `_refreshSessionQuietly` runs without an apiClient set
      // on this repo — it throws StateError, which is logged and swallowed.
      // So the hook fires exactly once, from restore() itself.
      expect(calls, ['co_a']);
    });

    test('no fire on switchCompany when the target token is missing', () async {
      authService.queueLogin(_envelope());
      await repo.login(
        baseUrl: 'https://test',
        isHosted: false,
        email: 'a',
        password: 'b',
      );
      final calls = <String>[];
      repo.onActiveCompanyChanged = calls.add;

      // No-op early return because no token is cached for co_missing.
      await repo.switchCompany('co_missing');

      expect(
        calls,
        isEmpty,
        reason:
            'we must not drain for a company we can not authenticate against',
      );
    });
  });
}
