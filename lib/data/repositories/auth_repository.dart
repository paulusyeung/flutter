import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/models/api/user_api_model.dart';
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

  /// Wired by DI to `SyncRepository.drainOnce`. Fires whenever the active
  /// company becomes non-null (login, restore, /refresh, addCompany) or
  /// switches ([switchCompany]) so any outbox rows pending for that company
  /// — left over from a prior session, or queued while we were offline —
  /// drain immediately instead of sitting until the next user action. Fire
  /// and forget; failures surface via the sync engine's own event stream.
  void Function(String companyId)? onActiveCompanyChanged;

  /// Wired by DI to fan-out the per-entity `applyBundle` calls (task
  /// statuses, company gateways, …). Invoked once per company in the
  /// `/login` or `/refresh` envelope, *after* the user / company / settings
  /// rows have been persisted. Lets the auth layer stay ignorant of which
  /// entity repositories exist while still seeding their Drift tables from
  /// the bundled arrays on `data[N].company.*`.
  Future<void> Function({
    required String companyId,
    required CompanyEnvelopeApi company,
  })?
  onPersistBundles;
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

  /// Cold-launch biometric gate. Flipped on by [restore] when the user has
  /// opted in; flipped off by [completeBiometricUnlock]. The router watches
  /// this and redirects to `/lock` while it's true.
  final ValueNotifier<bool> _requiresBiometricUnlock = ValueNotifier<bool>(
    false,
  );

  /// Subscription to the Drift `companies` table. Rebuilds the
  /// `AuthSession.companies` slice whenever a row changes (e.g. the user
  /// edits the company name on Settings → Company Details) so the picker in
  /// the shell sidebar reflects the change without waiting for the next
  /// `/refresh` or app restart. Created on first session activation and torn
  /// down by [logout] / [dispose].
  StreamSubscription<List<CompanyRow>>? _companiesSub;

  ValueListenable<AuthSession?> get session => _session;
  ValueListenable<ApiCredentials?> get credentials => _credentials;
  ValueListenable<bool> get requiresBiometricUnlock => _requiresBiometricUnlock;

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

  /// Merge user-level fields from a `PUT /users/{id}` response into the
  /// active session so the topbar / company picker re-render with the patched
  /// values immediately, without waiting for the next `/refresh`. No-op when
  /// there's no session or the response is for a different user (defensive —
  /// `UserRepository` only enqueues updates for the auth user, but a future
  /// User Management screen could share this code path).
  void applyUserUpdate(UserApi user) {
    final s = _session.value;
    if (s == null) return;
    if (user.id.isNotEmpty && user.id != s.userId) return;
    _session.value = s.copyWith(
      userFirstName: user.firstName,
      userLastName: user.lastName,
      userEmail: user.email,
      userPhone: user.phone,
      googleTwoFactorEnabled: user.google2faSecret,
      verifiedPhoneNumber: user.verifiedPhoneNumber,
    );
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
    onActiveCompanyChanged?.call(companyId);
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

  /// Mark a company as the account's default — what new logins land on
  /// before any per-device override. Wraps `POST /api/v1/companies/{id}/default`
  /// then re-pulls `/refresh` so the local `Accounts.defaultCompanyId` and the
  /// session's `defaultCompanyId` snap to the new value. Throws on
  /// transport / HTTP / parse failure; UI surfaces a toast.
  ///
  /// Mirrors admin-portal `auth_repository.dart:172` (`setDefaultCompany`).
  Future<void> setDefaultCompany(String companyId) async {
    final activeCompanyId = _session.value?.currentCompanyId;
    await _requireApi.postJson(
      '/api/v1/companies/$companyId/default',
      body: const {},
    );
    await _refreshSession(preserveActiveCompanyId: activeCompanyId);
  }

  /// Server-side "end all sessions" — `POST /api/v1/logout` clears every
  /// active token attached to the account. Used by Settings → Account
  /// Management → Security Settings to nuke other devices in one shot.
  ///
  /// Caller must prime the password cache via [showConfirmPasswordSheet] (or
  /// `passwordCache.set`) before calling — the server enforces
  /// `X-API-PASSWORD-BASE64` for this endpoint. On success we run the local
  /// [logout] end-to-end so this device drops back to `/login`; the server's
  /// session invalidation would force the next request to 401 anyway, but
  /// pre-emptively logging out avoids a brief authenticated-with-revoked-
  /// token window.
  Future<void> endAllSessions() async {
    await _requireApi.postJson(
      '/api/v1/logout',
      body: const {},
      requiresPassword: true,
    );
    await logout();
  }

  /// Self-hosted only: redeem a white-label / license key against
  /// `POST /api/v1/claim_license`. Server upgrades the account's plan;
  /// we refresh to pick up the new `plan`, `plan_expires`, and feature flags.
  /// Throws on transport / HTTP / parse failure; UI surfaces a toast.
  ///
  /// Mirrors admin-portal `account_management.dart:550` inline call.
  Future<void> applyLicense(String licenseKey) async {
    await _requireApi.postJson(
      '/api/v1/claim_license',
      query: {'license_key': licenseKey},
      body: const {},
    );
    await refresh();
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
    await _companiesSub?.cancel();
    _companiesSub = null;
    _session.value = null;
    _credentials.value = null;
    _requiresBiometricUnlock.value = false;
    _tokensByCompany = const {};
    _passwordCache.clear();
    await _secure.delete(kAuthTokensKey);
    await _secure.delete(kAuthBaseUrlKey);
    await _secure.delete(kAuthIsHostedKey);
    await _secure.delete(kAuthCurrentCompanyIdKey);
    // A logged-out session has nothing left to unlock; leaving the flag on
    // disk would surface a lock prompt on next launch with no session behind
    // it. Clear it alongside the tokens.
    await _secure.delete(kAuthBiometricEnabledKey);
    await _db.wipe();
  }

  /// Persist the user's biometric preference and reflect it in the active
  /// session so the User Details toggle stays in sync without a `/refresh`.
  /// No-op when there's no active session — writing the flag without a token
  /// behind it would surface a lock screen on next launch with nothing to
  /// unlock.
  Future<void> setBiometricEnabled(bool enabled) async {
    final s = _session.value;
    if (s == null) return;
    if (enabled) {
      await _secure.write(kAuthBiometricEnabledKey, 'true');
    } else {
      await _secure.delete(kAuthBiometricEnabledKey);
    }
    _session.value = s.copyWith(biometricEnabled: enabled);
  }

  /// Called by the lock screen once the user passes the biometric prompt.
  /// Flipping the notifier fires the router's refresh listener, which then
  /// redirects out of `/lock` into the post-login destination.
  void completeBiometricUnlock() {
    if (_requiresBiometricUnlock.value) {
      _requiresBiometricUnlock.value = false;
    }
  }

  /// Pull a fresh server snapshot for the active session. Same wire call
  /// as the post-login refresh: `POST /api/v1/refresh?first_load=true&...`,
  /// then `_persistAndActivate` writes the response across the
  /// `companies`, `users`, `user_settings`, and the bundled per-entity
  /// tables (task_statuses, company_gateways, …). Safe to call on demand
  /// — Settings > User Details fires it on open so the form reflects the
  /// latest profile fields without round-tripping the password-protected
  /// `GET /users/{id}` endpoint. No-op when there's no active session.
  Future<void> refresh() async {
    if (_session.value == null) return;
    await _refreshSession();
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
    // Tolerate any value that isn't exactly `'true'` — a corrupt write
    // shouldn't lock the user out without their explicit opt-in.
    final biometricEnabled =
        (await _secure.read(kAuthBiometricEnabledKey)) == 'true';
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
    // A handful of account-level fields aren't Drift columns — they live
    // inside the serialized `features_json` blob written by
    // `_persistAndActivate`. Decode lazily, tolerating a missing/corrupt
    // blob by defaulting each field to its zero value.
    var hostedCompanyCount = 0;
    var hostedClientCount = 0;
    var planExpires = '';
    var trialPlan = '';
    var trialStarted = '';
    final featuresRaw = account.featuresJson;
    if (featuresRaw != null && featuresRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(featuresRaw);
        if (decoded is Map<String, dynamic>) {
          int asInt(Object? v) {
            if (v is int) return v;
            if (v is num) return v.toInt();
            return 0;
          }

          String asStr(Object? v) => v is String ? v : '';
          hostedCompanyCount = asInt(decoded['hosted_company_count']);
          hostedClientCount = asInt(decoded['hosted_client_count']);
          planExpires = asStr(decoded['plan_expires']);
          trialPlan = asStr(decoded['trial_plan']);
          trialStarted = asStr(decoded['trial_started']);
        }
      } catch (_) {
        /* fall through to defaults */
      }
    }
    final session = AuthSession(
      baseUrl: baseUrl,
      isHosted: isHosted,
      accountId: account.id,
      plan: account.plan,
      planExpires: planExpires,
      trialPlan: trialPlan,
      trialStarted: trialStarted,
      numTrialDays: account.numTrialDays,
      defaultCompanyId: account.defaultCompanyId ?? '',
      hostedClientCount: hostedClientCount,
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
      biometricEnabled: biometricEnabled,
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
    // Flip the gate BEFORE we hand credentials to the router. Setting
    // credentials triggers the router's refreshListenable; if the lock flag
    // weren't set yet the router would route straight into the shell and
    // race the lock screen. Order matters.
    if (biometricEnabled) {
      _requiresBiometricUnlock.value = true;
    }
    _credentials.value = ApiCredentials(
      baseUrl: baseUrl,
      token: activeToken,
      isHosted: isHosted,
    );
    _attachCompaniesWatcher();
    // If the user backgrounded the app with pending outbox rows and the
    // device went offline before the previous process exited, those rows
    // now need a kick — biometric-gated restore included (the drain will
    // only successfully dispatch once the credentials are honored, but
    // queuing it here is harmless because drainOnce is idempotent).
    onActiveCompanyChanged?.call(session.currentCompanyId);

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
            enabledModules: Value(uc.company.enabledModules),
            googleAnalyticsKey: Value(uc.company.googleAnalyticsKey),
            matomoId: Value(uc.company.matomoId),
            matomoUrl: Value(uc.company.matomoUrl),
            sessionTimeout: Value(uc.company.sessionTimeout),
            defaultPasswordTimeout: Value(uc.company.defaultPasswordTimeout),
            oauthPasswordRequired: Value(uc.company.oauthPasswordRequired),
            isDisabled: Value(uc.company.isDisabled),
            markdownEnabled: Value(uc.company.markdownEnabled),
            markdownEmailEnabled: Value(uc.company.markdownEmailEnabled),
            reportIncludeDrafts: Value(uc.company.reportIncludeDrafts),
            reportIncludeDeleted: Value(uc.company.reportIncludeDeleted),
            enabledTaxRates: Value(uc.company.enabledTaxRates),
            enabledItemTaxRates: Value(uc.company.enabledItemTaxRates),
            enabledExpenseTaxRates: Value(uc.company.enabledExpenseTaxRates),
            calculateTaxes: Value(uc.company.calculateTaxes),
            taxDataJson: Value(
              uc.company.taxData == null
                  ? null
                  : jsonEncode(uc.company.taxData!.toJson()),
            ),
            trackInventory: Value(uc.company.trackInventory),
            stockNotification: Value(uc.company.stockNotification),
            inventoryNotificationThreshold: Value(
              uc.company.inventoryNotificationThreshold,
            ),
            enableProductDiscount: Value(uc.company.enableProductDiscount),
            enableProductCost: Value(uc.company.enableProductCost),
            enableProductQuantity: Value(uc.company.enableProductQuantity),
            defaultQuantity: Value(uc.company.defaultQuantity),
            showProductDetails: Value(uc.company.showProductDetails),
            fillProducts: Value(uc.company.fillProducts),
            updateProducts: Value(uc.company.updateProducts),
            convertProducts: Value(uc.company.convertProducts),
            convertRateToClient: Value(uc.company.convertRateToClient),
            stopOnUnpaidRecurring: Value(uc.company.stopOnUnpaidRecurring),
            useQuoteTermsOnConversion: Value(
              uc.company.useQuoteTermsOnConversion,
            ),
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
      // Auth user record. /refresh's `data[N].user` carries the full
      // profile shape — first/last name, signature, language_id,
      // custom_value1..4 — so the User Details screen reads from Drift
      // without round-tripping `GET /users/{id}` (which the server gates
      // with a 412 password check). The `payload` blob is shaped like the
      // `GET /users/{id}` envelope so `UserRepository._fromRow` decodes
      // it unchanged; the nested `company_user.settings` mirrors what the
      // PUT path round-trips.
      for (final uc in response.data) {
        if (uc.user.id.isEmpty) continue;
        final userPayload = <String, dynamic>{
          'id': uc.user.id,
          'first_name': uc.user.firstName,
          'last_name': uc.user.lastName,
          'email': uc.user.email,
          'phone': uc.user.phone,
          'signature': uc.user.signature,
          'language_id': uc.user.languageId,
          'custom_value1': uc.user.customValue1,
          'custom_value2': uc.user.customValue2,
          'custom_value3': uc.user.customValue3,
          'custom_value4': uc.user.customValue4,
          'oauth_provider_id': uc.user.oauthProviderId,
          'company_user': <String, dynamic>{
            'settings': uc.settings,
            'is_admin': uc.isAdmin,
            'is_owner': uc.isOwner,
            'permissions': uc.permissions,
          },
        };
        await _db.userDao.upsert(
          UsersCompanion(
            id: Value(uc.user.id),
            companyId: Value(uc.company.id),
            firstName: Value(uc.user.firstName),
            lastName: Value(uc.user.lastName),
            email: Value(uc.user.email),
            phone: Value(uc.user.phone),
            languageId: Value(uc.user.languageId),
            signature: Value(uc.user.signature),
            updatedAt: Value(nowMs),
            isDirty: const Value(false),
            payload: Value(jsonEncode(userPayload)),
          ),
        );
      }
    });
    // Seed any bundled per-entity arrays in `data[N].company.*` (today:
    // task_statuses + company_gateways). Runs after the main transaction
    // commits — each repo's applyBundle owns its own transaction. Failures
    // are logged and swallowed so a partial-bundle response doesn't keep
    // the user out of the app.
    final bundlesHook = onPersistBundles;
    if (bundlesHook != null) {
      for (final uc in response.data) {
        try {
          await bundlesHook(companyId: uc.company.id, company: uc.company);
        } catch (e, st) {
          _log.warning(
            'onPersistBundles failed for company ${uc.company.id}',
            e,
            st,
          );
        }
      }
    }

    await _secure.write(kAuthTokensKey, jsonEncode(tokens));
    await _secure.write(kAuthBaseUrlKey, baseUrl);
    await _secure.write(kAuthIsHostedKey, isHosted ? 'true' : 'false');
    await _secure.write(kAuthCurrentCompanyIdKey, currentId);

    // Preserve the user's biometric preference across `/refresh` calls.
    // Fresh logins see no value (logout cleared it) so this resolves to false;
    // a background `_refreshSessionQuietly` after `restore` reads whatever the
    // user set on a previous launch. Never touch `_requiresBiometricUnlock` —
    // that flag is owned by `restore` / `completeBiometricUnlock`.
    final biometricEnabled =
        (await _secure.read(kAuthBiometricEnabledKey)) == 'true';

    _tokensByCompany = tokens;
    final firstUser = response.data.first.user;
    _session.value = AuthSession(
      baseUrl: baseUrl,
      isHosted: isHosted,
      accountId: firstAccount.id,
      plan: firstAccount.plan,
      planExpires: firstAccount.planExpires,
      trialPlan: firstAccount.trialPlan,
      trialStarted: firstAccount.trialStarted,
      numTrialDays: firstAccount.numTrialDays,
      defaultCompanyId: firstAccount.defaultCompanyId,
      hostedClientCount: firstAccount.hostedClientCount,
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
      biometricEnabled: biometricEnabled,
      referralCode: firstUser.referralCode,
      referralMeta: firstUser.referralMeta,
    );
    _credentials.value = ApiCredentials(
      baseUrl: baseUrl,
      token: tokens[currentId] ?? response.data.first.token.token,
      isHosted: isHosted,
    );
    _attachCompaniesWatcher();
    onActiveCompanyChanged?.call(currentId);
  }

  /// Subscribe to the Drift `companies` table once per repo lifetime so a
  /// settings-driven name/logo edit (or any other writer) flows back into
  /// `AuthSession.companies` and re-renders the sidebar picker without
  /// waiting for the next `/refresh`. Idempotent — repeated calls (login,
  /// /refresh, restore) reuse the existing subscription.
  void _attachCompaniesWatcher() {
    if (_companiesSub != null) return;
    _companiesSub = _db.companiesDao.watchAll().listen(_onCompaniesChanged);
  }

  void _onCompaniesChanged(List<CompanyRow> rows) {
    final s = _session.value;
    if (s == null) return;
    // Keep only rows that match an id already in the session — guards against
    // the brief mid-transaction state in `_persistAndActivate` (wipe + upsert)
    // and any future writer that touches the table before the session is
    // re-assigned.
    final knownIds = {for (final c in s.companies) c.id};
    final byId = {
      for (final r in rows)
        if (knownIds.contains(r.id)) r.id: r,
    };
    if (byId.length != s.companies.length) return;
    final rebuilt = <AuthCompany>[];
    var changed = false;
    for (final existing in s.companies) {
      final row = byId[existing.id]!;
      Map<String, dynamic> settings = const {};
      if (row.settings.isNotEmpty) {
        try {
          final decoded = jsonDecode(row.settings);
          if (decoded is Map<String, dynamic>) settings = decoded;
        } catch (_) {}
      }
      // Mirror restore()'s logo precedence: dedicated column wins, settings
      // blob is the fallback for pre-v7 rows.
      final logoFromColumn = row.logoUrl;
      final logoUrl = (logoFromColumn != null && logoFromColumn.isNotEmpty)
          ? logoFromColumn
          : companyLogoUrl(settings);
      final displayName = companyDisplayName(
        settings: settings,
        displayName: row.displayName ?? '',
        name: row.name,
      );
      if (existing.name != row.name ||
          existing.displayName != displayName ||
          existing.logoUrl != logoUrl ||
          existing.permissions != row.permissions ||
          existing.isAdmin != row.isAdmin ||
          existing.isOwner != row.isOwner) {
        changed = true;
      }
      rebuilt.add(
        AuthCompany(
          id: existing.id,
          name: row.name,
          displayName: displayName,
          logoUrl: logoUrl,
          permissions: row.permissions,
          isAdmin: row.isAdmin,
          isOwner: row.isOwner,
        ),
      );
    }
    if (!changed) return;
    _session.value = s.copyWith(companies: rebuilt);
  }

  Future<void> dispose() async {
    await _companiesSub?.cancel();
    _companiesSub = null;
    _session.dispose();
    _credentials.dispose();
    _requiresBiometricUnlock.dispose();
  }
}
