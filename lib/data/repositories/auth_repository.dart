import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/repositories/auth/auth_helpers.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/token_storage.dart';

export 'package:admin/data/repositories/auth/auth_session.dart'
    show AuthSession, AuthCompany, CanAddCompanyResult, kMaxCompaniesPerAccount;

final _log = Logger('AuthRepository');

/// Owns the user's session: who they are, what company is active, what
/// `ApiCredentials` the network layer should use right now. Persists the
/// token in [FlutterSecureStorage] and the company/account metadata in Drift.
///
/// The UI listens to two things:
///   * [session] — the rich envelope (companies, account, permissions).
///   * [credentials] — what [ApiClient] reads on every request.
class AuthRepository {
  AuthRepository({
    required AppDatabase db,
    required AuthService authService,
    required TokenStorage tokenStorage,
    required PasswordCache passwordCache,
    DateTime Function()? now,
  }) : _db = db,
       _auth = authService,
       _secure = tokenStorage,
       _passwordCache = passwordCache,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final AuthService _auth;
  final TokenStorage _secure;
  final PasswordCache _passwordCache;
  final DateTime Function() _now;

  /// Wired by DI after [ApiClient] is constructed — they have a mutual
  /// dependency (ApiClient needs [credentials] + [logout]), so the cycle is
  /// broken by injecting this lazily.
  ApiClient? _api;
  set apiClient(ApiClient client) => _api = client;

  /// Wired by DI after [SyncRepository] is constructed. Invoked at the top
  /// of [logout] so a pending outbox drain can settle before we wipe the
  /// local DB out from under it. Failures are logged and swallowed; logout
  /// must complete even if the hook throws.
  Future<void> Function()? onBeforeLogout;
  ApiClient get _requireApi {
    final api = _api;
    if (api == null) {
      throw StateError(
        'AuthRepository.apiClient was not set before addCompany() was called',
      );
    }
    return api;
  }

  final ValueNotifier<AuthSession?> _session = ValueNotifier<AuthSession?>(
    null,
  );
  final ValueNotifier<ApiCredentials?> _credentials =
      ValueNotifier<ApiCredentials?>(null);

  ValueListenable<AuthSession?> get session => _session;
  ValueListenable<ApiCredentials?> get credentials => _credentials;

  bool get isAuthenticated => _credentials.value?.isAuthenticated ?? false;

  /// Per-company token map. Kept in memory for fast switching; secure storage
  /// is the durable copy.
  Map<String, String> _tokensByCompany = const {};

  /// Hot login. Calls `/api/v1/login`, persists everything, and primes
  /// [credentials] so subsequent API calls work.
  Future<void> login({
    required String baseUrl,
    required bool isHosted,
    required String email,
    required String password,
    String? oneTimePassword,
  }) async {
    final response = await _auth.login(
      baseUrl: baseUrl,
      isHosted: isHosted,
      email: email,
      password: password,
      oneTimePassword: oneTimePassword,
    );
    await _persistAndActivate(
      response: response,
      baseUrl: baseUrl,
      isHosted: isHosted,
    );
  }

  /// OAuth login (Sign in with Apple, etc). Calls `/api/v1/oauth_login`
  /// then activates the session — identical tail to [login].
  Future<void> oauthLogin({
    required String baseUrl,
    required bool isHosted,
    required String provider,
    String? idToken,
    String? authCode,
    String? accessToken,
    String? email,
  }) async {
    final response = await _auth.oauthLogin(
      baseUrl: baseUrl,
      isHosted: isHosted,
      provider: provider,
      idToken: idToken,
      authCode: authCode,
      accessToken: accessToken,
      email: email,
    );
    await _persistAndActivate(
      response: response,
      baseUrl: baseUrl,
      isHosted: isHosted,
    );
  }

  /// Re-pull `/api/v1/refresh` and re-populate the session. Used by the
  /// Two-Factor screen after a successful enable/disable so the new
  /// `google_2fa_secret` / `verified_phone_number` flags propagate without a
  /// forced logout. Throws on transport/HTTP failures so the caller can
  /// surface a toast.
  Future<void> refreshSession() => _refreshSession();

  /// In-memory short-circuit for the Two-Factor screen. Lets the UI react
  /// immediately after a successful enable/disable while a background
  /// [refreshSession] catches up the rest. No-op when there's no session.
  void markTwoFactorEnabled(bool enabled) {
    final s = _session.value;
    if (s == null) return;
    _session.value = s.copyWith(googleTwoFactorEnabled: enabled);
  }

  /// Same shape as [markTwoFactorEnabled] but for the SMS-verified flag.
  void markPhoneVerified({String? phone}) {
    final s = _session.value;
    if (s == null) return;
    _session.value = s.copyWith(verifiedPhoneNumber: true, userPhone: phone);
  }

  /// Forgot-password — the server emails the user. No session is created.
  Future<void> recoverPassword({
    required String baseUrl,
    required bool isHosted,
    required String email,
  }) =>
      _auth.recoverPassword(baseUrl: baseUrl, isHosted: isHosted, email: email);

  /// Switch the active company. Updates [credentials] so the next API call
  /// uses that company's token. Caller is responsible for any pending-outbox
  /// confirmation prompt before invoking this.
  Future<void> switchCompany(String companyId) async {
    final s = _session.value;
    if (s == null) return;
    final token = _tokensByCompany[companyId];
    // Empty strings slip past a `== null` check but produce a blank
    // `X-API-Token` header, which the server treats as unauthorized and
    // cascades into a forced logout. Treat empty as missing.
    if (token == null || token.isEmpty) {
      _log.warning('switchCompany($companyId): no token cached');
      return;
    }
    _session.value = s.copyWith(currentCompanyId: companyId);
    _credentials.value = ApiCredentials(
      baseUrl: s.baseUrl,
      token: token,
      apiSecret: '',
      isHosted: s.isHosted,
    );
    await _secure.write(kAuthCurrentCompanyIdKey, companyId);
  }

  /// Create a new company under the current account. Mirrors admin-portal's
  /// `addCompany` (auth_repository.dart:180-189 + auth_middleware.dart:360-387):
  /// POST is opaque; the client then re-pulls every company/token via
  /// `/api/v1/refresh` and switches into the newly-arrived one.
  ///
  /// The caller is responsible for any pending-outbox prompt before invoking
  /// this — same contract as [switchCompany].
  Future<void> addCompany() async {
    final s = _session.value;
    if (s == null) {
      throw StateError('addCompany called without an active session');
    }
    final before = s.companies.map((c) => c.id).toSet();
    final activeCompanyId = s.currentCompanyId;

    // 1. POST — server returns the created company; we ignore it and
    //    re-pull below to also pick up the per-company token.
    await _requireApi.postJson(
      '/api/v1/companies',
      body: const {'token_name': 'ios_client'},
    );

    // 2-3. Refresh re-pulls every company + token and re-persists, preserving
    //      the previously-active company so the user doesn't get bounced back
    //      to `account.defaultCompanyId`.
    await _refreshSession(preserveActiveCompanyId: activeCompanyId);

    // 4. Identify the new company by id-set diff. Server order isn't
    //    guaranteed across the two calls; this is the only safe way.
    final after = _session.value!.companies.map((c) => c.id).toSet();
    final added = after.difference(before);
    if (added.isEmpty) {
      throw StateError(
        '/refresh did not return the newly-created company; aborting switch',
      );
    }
    // If multiple companies were added (e.g. another device created one
    // concurrently), pick any — the user can still switch via the picker.
    await switchCompany(added.first);
  }

  /// Pull `/api/v1/refresh` and re-persist the full session. Used by
  /// [addCompany] (to pick up the newly-created company + token) and by
  /// [restore] (to heal stale per-(user,company) flags like `is_owner` /
  /// `is_admin` that older schema migrations left at their column default).
  ///
  /// Throws on transport, HTTP, or parse failures. Callers decide whether to
  /// surface them: [addCompany] re-throws so the UI shows an error;
  /// [restore]'s background heal swallows so an offline cold start still works.
  Future<void> _refreshSession({String? preserveActiveCompanyId}) async {
    final s = _session.value;
    if (s == null) {
      throw StateError('_refreshSession called without an active session');
    }
    final raw = await _requireApi.postJson(
      '/api/v1/refresh',
      query: const {
        'current_company': 'false',
        'updated_at': '0',
        'first_load': 'true',
        'include_static': 'true',
        'einvoice': 'true',
      },
      readOnly: true,
    );
    if (raw is! Map<String, dynamic>) {
      throw StateError(
        'Unexpected /refresh response shape: ${raw.runtimeType}',
      );
    }
    final response = LoginResponseApi.fromJson(raw);
    await _persistAndActivate(
      response: response,
      baseUrl: s.baseUrl,
      isHosted: s.isHosted,
      preserveActiveCompanyId: preserveActiveCompanyId ?? s.currentCompanyId,
    );
  }

  /// Called by [ApiClient] when a 401 lands. Wipes everything and flips
  /// [credentials] back to null so the redirect to `/login` fires.
  Future<void> logout() async {
    // Let any in-flight outbox drain settle BEFORE we wipe the DB — without
    // this, a successful send racing logout could mutate server state on
    // behalf of the user who just logged out.
    final hook = onBeforeLogout;
    if (hook != null) {
      try {
        await hook();
      } catch (e, st) {
        _log.warning('onBeforeLogout failed', e, st);
      }
    }
    _session.value = null;
    _credentials.value = null;
    _tokensByCompany = const {};
    _passwordCache.clear();
    await _secure.delete(kAuthTokensKey);
    await _secure.delete(kAuthBaseUrlKey);
    await _secure.delete(kAuthIsHostedKey);
    await _secure.delete(kAuthCurrentCompanyIdKey);
    await _db.wipe();
  }

  /// Read on app start: if we have a token cached, rebuild the session from
  /// Drift + secure storage so the user lands inside the shell immediately.
  Future<void> restore() async {
    final tokensRaw = await _secure.read(kAuthTokensKey);
    final baseUrl = await _secure.read(kAuthBaseUrlKey);
    if (tokensRaw == null || baseUrl == null) return;
    final isHostedRaw = await _secure.read(kAuthIsHostedKey);
    final isHosted = isHostedRaw == 'true';
    final currentId = await _secure.read(kAuthCurrentCompanyIdKey) ?? '';
    final tokensMap = (jsonDecode(tokensRaw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v.toString()),
    );
    if (tokensMap.isEmpty) return;

    final account = await _db.companiesDao.account();
    final companies = await _db.companiesDao.all();
    if (account == null || companies.isEmpty) {
      // Drift was reset (or never populated). Discard the stale token.
      await logout();
      return;
    }
    _tokensByCompany = tokensMap;
    // `hosted_company_count` isn't a Drift column — it lives inside the
    // serialized `features_json` blob (see `_persistAndActivate`). Decode
    // lazily and tolerate a missing/corrupt blob by defaulting to the
    // server's free-tier limit.
    var hostedCompanyCount = 0;
    final featuresRaw = account.featuresJson;
    if (featuresRaw != null && featuresRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(featuresRaw);
        if (decoded is Map<String, dynamic>) {
          final v = decoded['hosted_company_count'];
          if (v is int) {
            hostedCompanyCount = v;
          } else if (v is num) {
            hostedCompanyCount = v.toInt();
          }
        }
      } catch (_) {
        /* fall through to 0 */
      }
    }
    final session = AuthSession(
      baseUrl: baseUrl,
      isHosted: isHosted,
      accountId: account.id,
      plan: account.plan,
      hostedCompanyCount: hostedCompanyCount,
      companies: companies
          .map((c) {
            Map<String, dynamic> settings = const {};
            try {
              final decoded = jsonDecode(c.settings);
              if (decoded is Map<String, dynamic>) settings = decoded;
            } catch (_) {}
            // Prefer the dedicated `logo_url` column. Fall back to the
            // settings blob for rows that pre-date the v7 migration / for
            // logs that survived a codegen mishap that truncated the JSON.
            final logoFromColumn = c.logoUrl;
            final logoUrl =
                (logoFromColumn != null && logoFromColumn.isNotEmpty)
                ? logoFromColumn
                : companyLogoUrl(settings);
            return AuthCompany(
              id: c.id,
              name: c.name,
              displayName: companyDisplayName(
                settings: settings,
                displayName: c.displayName ?? '',
                name: c.name,
              ),
              logoUrl: logoUrl,
              permissions: c.permissions,
              isAdmin: c.isAdmin,
              isOwner: c.isOwner,
            );
          })
          .toList(growable: false),
      currentCompanyId: currentId.isNotEmpty ? currentId : (companies.first.id),
    );
    final activeToken = tokensMap[session.currentCompanyId];
    if (activeToken == null || activeToken.isEmpty) {
      // The secure-storage token map is corrupt or out of sync with the
      // Drift `companies` table. Surface this loudly and bounce to login
      // rather than activate a credential-less session that would fail
      // every API call.
      _log.warning(
        'restore(): no token for currentCompanyId=${session.currentCompanyId}; '
        'forcing logout',
      );
      await logout();
      return;
    }
    _session.value = session;
    _credentials.value = ApiCredentials(
      baseUrl: baseUrl,
      token: activeToken,
      isHosted: isHosted,
    );

    // Best-effort: re-pull the session in the background so stale
    // per-(user,company) flags (`is_owner`, `is_admin`) and account-level
    // fields (`plan`, `hosted_company_count`) catch up with the server.
    // Older schema migrations added the local `is_owner` column with a
    // default of false and didn't backfill — without this, an account owner
    // who upgraded the app without re-logging in stays silently downgraded
    // (the company picker shows "Only the account owner can add companies"
    // even though they are). If we're offline / unauthorized / parse fails,
    // leave the restored session as-is.
    unawaited(_refreshSessionQuietly());
  }

  Future<void> _refreshSessionQuietly() async {
    try {
      await _refreshSession();
    } catch (e, st) {
      _log.fine('restore(): background refresh skipped', e, st);
    }
  }

  Future<void> _persistAndActivate({
    required LoginResponseApi response,
    required String baseUrl,
    required bool isHosted,
    String? preserveActiveCompanyId,
  }) async {
    if (response.data.isEmpty) {
      throw StateError('Login response had no companies');
    }
    // Merge, don't replace. /refresh?current_company=false has been observed
    // returning empty `token` fields for non-active companies; freezed's
    // `TokenApi.token` defaults to `''`, which would silently wipe good cached
    // tokens and trip a 401 -> forced logout on the next company switch.
    // Only let a non-empty response value override the cached one, and drop
    // any cached entries for companies the server no longer returns.
    final liveIds = {for (final uc in response.data) uc.company.id};
    final tokens = <String, String>{
      for (final entry in _tokensByCompany.entries)
        if (liveIds.contains(entry.key)) entry.key: entry.value,
      for (final uc in response.data)
        if (uc.token.token.isNotEmpty) uc.company.id: uc.token.token,
    };
    final missingTokenIds = [
      for (final uc in response.data)
        if (uc.token.token.isEmpty) uc.company.id,
    ];
    if (missingTokenIds.isNotEmpty) {
      _log.warning(
        'response had empty tokens for companies: ${missingTokenIds.join(', ')}',
      );
    }
    final nowMs = _now().millisecondsSinceEpoch;
    final firstAccount = response.data.first.account;
    // Prefer the caller-supplied active company (used by refresh-on-create
    // so the user doesn't get silently teleported back to the account's
    // default company) when its token is still in the new response.
    final String currentId;
    if (preserveActiveCompanyId != null &&
        preserveActiveCompanyId.isNotEmpty &&
        tokens.containsKey(preserveActiveCompanyId)) {
      currentId = preserveActiveCompanyId;
    } else if (firstAccount.defaultCompanyId.isNotEmpty) {
      currentId = firstAccount.defaultCompanyId;
    } else {
      currentId = response.data.first.company.id;
    }

    await _db.transaction(() async {
      await _db.companiesDao.wipe();
      await _db.companiesDao.upsertAccount(
        AccountsCompanion.insert(
          id: firstAccount.id,
          email: '',
          plan: firstAccount.plan,
          numTrialDays: firstAccount.numTrialDays,
          isHosted: Value(isHosted),
          defaultCompanyId: Value(firstAccount.defaultCompanyId),
          featuresJson: Value(jsonEncode(firstAccount.toJson())),
          updatedAt: nowMs,
        ),
      );
      await _db.companiesDao.upsertAll([
        for (final uc in response.data)
          CompaniesCompanion.insert(
            id: uc.company.id,
            name: uc.company.name,
            displayName: Value(
              companyDisplayName(
                settings: uc.company.settings,
                displayName: uc.company.displayName,
                name: uc.company.name,
              ),
            ),
            logoUrl: Value(companyLogoUrl(uc.company.settings)),
            settings: jsonEncode(uc.company.settings),
            customFields: Value(jsonEncode(uc.company.customFields)),
            sizeId: Value(uc.company.sizeId),
            industryId: Value(uc.company.industryId),
            legalEntityId: Value(uc.company.legalEntityId),
            permissions: uc.permissions,
            accountId: uc.account.id,
            token: uc.token.token,
            isAdmin: Value(uc.isAdmin),
            isOwner: Value(uc.isOwner),
            updatedAt: nowMs,
          ),
      ]);
      // Per-(user, company) settings — split `table_columns` out of the
      // generic settings blob so the picker can watch it directly. Keep
      // the rest under `extra_json` so the PUT we'll later send preserves
      // every field the new app doesn't yet model.
      for (final uc in response.data) {
        final settings = uc.settings;
        final tableColumns = settings['table_columns'];
        final extra = Map<String, dynamic>.from(settings)
          ..remove('table_columns');
        await _db.userSettingsDao.upsert(
          UserSettingsCompanion(
            companyId: Value(uc.company.id),
            userId: Value(uc.user.id),
            tableColumnsJson: Value(
              jsonEncode(
                tableColumns is Map ? tableColumns : <String, dynamic>{},
              ),
            ),
            extraJson: Value(jsonEncode(extra)),
            updatedAt: Value(nowMs),
          ),
        );
      }
    });

    await _secure.write(kAuthTokensKey, jsonEncode(tokens));
    await _secure.write(kAuthBaseUrlKey, baseUrl);
    await _secure.write(kAuthIsHostedKey, isHosted ? 'true' : 'false');
    await _secure.write(kAuthCurrentCompanyIdKey, currentId);

    _tokensByCompany = tokens;
    final firstUser = response.data.first.user;
    _session.value = AuthSession(
      baseUrl: baseUrl,
      isHosted: isHosted,
      accountId: firstAccount.id,
      plan: firstAccount.plan,
      hostedCompanyCount: firstAccount.hostedCompanyCount,
      companies: response.data
          .map(
            (uc) => AuthCompany(
              id: uc.company.id,
              name: uc.company.name,
              displayName: companyDisplayName(
                settings: uc.company.settings,
                displayName: uc.company.displayName,
                name: uc.company.name,
              ),
              logoUrl: companyLogoUrl(uc.company.settings),
              permissions: uc.permissions,
              isAdmin: uc.isAdmin,
              isOwner: uc.isOwner,
            ),
          )
          .toList(growable: false),
      currentCompanyId: currentId,
      userId: firstUser.id,
      userEmail: firstUser.email,
      userPhone: firstUser.phone,
      googleTwoFactorEnabled: firstUser.google2faSecret,
      verifiedPhoneNumber: firstUser.verifiedPhoneNumber,
    );
    _credentials.value = ApiCredentials(
      baseUrl: baseUrl,
      token: tokens[currentId] ?? response.data.first.token.token,
      isHosted: isHosted,
    );
  }

  Future<void> dispose() async {
    _session.dispose();
    _credentials.dispose();
  }
}
