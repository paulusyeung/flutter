import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/app/env.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/token_storage.dart';

final _log = Logger('AuthRepository');

/// Hard cap on companies per account (matches admin-portal's UI limit).
const int kMaxCompaniesPerAccount = 10;

/// Invoice Ninja stores the user-visible company name inside `settings.name`.
/// The top-level `display_name` / `name` fields are typically empty, so they
/// only serve as fallbacks. Mirrors admin-portal's `company_model.dart:528`.
String _companyDisplayName({
  required Map<String, dynamic> settings,
  required String displayName,
  required String name,
}) {
  final settingsName = settings['name'];
  if (settingsName is String && settingsName.trim().isNotEmpty) {
    return settingsName;
  }
  if (displayName.isNotEmpty) return displayName;
  if (name.isNotEmpty) return name;
  return 'Untitled';
}

/// `settings.company_logo` carries an absolute URL on self-hosted instances
/// and an Invoice Ninja CDN URL on hosted ones. Empty / missing → null so the
/// avatar falls through to its initials path.
String? _companyLogoUrl(Map<String, dynamic> settings) {
  final v = settings['company_logo'];
  if (v is String && v.trim().isNotEmpty) return v.trim();
  return null;
}

/// Why "New Company" is unavailable, or `ok` if it is. The picker renders
/// the matching reason as an inline subtitle on the disabled row.
enum CanAddCompanyResult { ok, notOwner, capReached, hostedPlanLimit, demoMode }

/// What the rest of the app sees about the current login. Held as a single
/// immutable value so the shell can listen via [AuthRepository.session].
@immutable
class AuthSession {
  const AuthSession({
    required this.baseUrl,
    required this.isHosted,
    required this.accountId,
    required this.companies,
    required this.currentCompanyId,
    this.plan = '',
    this.hostedCompanyCount = 0,
  });

  final String baseUrl;
  final bool isHosted;
  final String accountId;

  /// Sorted by display name; UI uses this for the company switcher.
  final List<AuthCompany> companies;

  final String currentCompanyId;

  /// Account plan slug, e.g. `pro`, `enterprise`, `` (free). Drives whether
  /// the hosted company-count limit gates "New Company".
  final String plan;

  /// On hosted, the max number of companies the account's plan allows.
  /// `0` on self-hosted (limit doesn't apply).
  final int hostedCompanyCount;

  AuthCompany? get currentCompany {
    for (final c in companies) {
      if (c.id == currentCompanyId) return c;
    }
    return companies.isEmpty ? null : companies.first;
  }

  /// Hosted plan is "paid" (no per-company-count limit) when the plan slug
  /// is one of the entitled tiers. Matches admin-portal's `isPaidAccount`.
  bool get _isPaidPlan =>
      plan == 'pro' || plan == 'enterprise' || plan == 'premium_business_plus';

  /// First-failing reason for adding a new company, or `ok` when allowed.
  /// Order: demo build > not owner > hard cap > hosted plan limit.
  CanAddCompanyResult get canAddCompany {
    if (Env.demoMode) return CanAddCompanyResult.demoMode;
    final me = currentCompany;
    if (me == null || !me.isOwner) return CanAddCompanyResult.notOwner;
    if (companies.length >= kMaxCompaniesPerAccount) {
      return CanAddCompanyResult.capReached;
    }
    if (isHosted && !_isPaidPlan && companies.length >= hostedCompanyCount) {
      return CanAddCompanyResult.hostedPlanLimit;
    }
    return CanAddCompanyResult.ok;
  }

  AuthSession copyWith({String? currentCompanyId}) => AuthSession(
    baseUrl: baseUrl,
    isHosted: isHosted,
    accountId: accountId,
    companies: companies,
    currentCompanyId: currentCompanyId ?? this.currentCompanyId,
    plan: plan,
    hostedCompanyCount: hostedCompanyCount,
  );
}

@immutable
class AuthCompany {
  const AuthCompany({
    required this.id,
    required this.name,
    required this.displayName,
    required this.permissions,
    required this.isAdmin,
    required this.isOwner,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String displayName;

  /// Absolute URL to the company's uploaded logo, or null when none is set.
  final String? logoUrl;

  /// Comma-separated permission strings — the format admin-portal uses too.
  final String permissions;

  final bool isAdmin;
  final bool isOwner;

  bool can(String permission) {
    if (isAdmin || isOwner) return true;
    if (permissions.isEmpty) return false;
    return permissions.split(',').contains(permission);
  }
}

/// Storage keys used in `flutter_secure_storage`. The map of `(companyId →
/// token)` is stored as a single JSON blob to keep the secure-storage API
/// minimal.
const _kTokensKey = 'invoiceninja.tokens.v1';
const _kBaseUrlKey = 'invoiceninja.base_url.v1';
const _kIsHostedKey = 'invoiceninja.is_hosted.v1';
const _kCurrentCompanyIdKey = 'invoiceninja.current_company.v1';

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
    DateTime Function()? now,
  }) : _db = db,
       _auth = authService,
       _secure = tokenStorage,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final AuthService _auth;
  final TokenStorage _secure;
  final DateTime Function() _now;

  /// Wired by DI after [ApiClient] is constructed — they have a mutual
  /// dependency (ApiClient needs [credentials] + [logout]), so the cycle is
  /// broken by injecting this lazily.
  ApiClient? _api;
  set apiClient(ApiClient client) => _api = client;
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
    if (token == null) {
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
    await _secure.write(_kCurrentCompanyIdKey, companyId);
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

    // 2. Refresh — same `LoginResponseApi` envelope as `/login`, with
    //    every company + its token.
    final raw = await _requireApi.getOneWithQuery(
      '/api/v1/refresh',
      query: const {
        'current_company': 'false',
        'updated_at': '0',
        'first_load': 'true',
        'include_static': 'true',
        'einvoice': 'true',
      },
    );
    if (raw is! Map<String, dynamic>) {
      throw StateError('Unexpected /refresh response shape: ${raw.runtimeType}');
    }
    final response = LoginResponseApi.fromJson(raw);

    // 3. Re-persist; preserve the previously-active company so the user
    //    doesn't get bounced back to `account.defaultCompanyId`.
    await _persistAndActivate(
      response: response,
      baseUrl: s.baseUrl,
      isHosted: s.isHosted,
      preserveActiveCompanyId: activeCompanyId,
    );

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

  /// Called by [ApiClient] when a 401 lands. Wipes everything and flips
  /// [credentials] back to null so the redirect to `/login` fires.
  Future<void> logout() async {
    _session.value = null;
    _credentials.value = null;
    _tokensByCompany = const {};
    await _secure.delete(_kTokensKey);
    await _secure.delete(_kBaseUrlKey);
    await _secure.delete(_kIsHostedKey);
    await _secure.delete(_kCurrentCompanyIdKey);
    await _db.wipe();
  }

  /// Read on app start: if we have a token cached, rebuild the session from
  /// Drift + secure storage so the user lands inside the shell immediately.
  Future<void> restore() async {
    final tokensRaw = await _secure.read(_kTokensKey);
    final baseUrl = await _secure.read(_kBaseUrlKey);
    if (tokensRaw == null || baseUrl == null) return;
    final isHostedRaw = await _secure.read(_kIsHostedKey);
    final isHosted = isHostedRaw == 'true';
    final currentId = await _secure.read(_kCurrentCompanyIdKey) ?? '';
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
                : _companyLogoUrl(settings);
            return AuthCompany(
              id: c.id,
              name: c.name,
              displayName: _companyDisplayName(
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
    if (activeToken == null) {
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
    final tokens = <String, String>{
      for (final uc in response.data) uc.company.id: uc.token.token,
    };
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
              _companyDisplayName(
                settings: uc.company.settings,
                displayName: uc.company.displayName,
                name: uc.company.name,
              ),
            ),
            logoUrl: Value(_companyLogoUrl(uc.company.settings)),
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

    await _secure.write(_kTokensKey, jsonEncode(tokens));
    await _secure.write(_kBaseUrlKey, baseUrl);
    await _secure.write(_kIsHostedKey, isHosted ? 'true' : 'false');
    await _secure.write(_kCurrentCompanyIdKey, currentId);

    _tokensByCompany = tokens;
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
              displayName: _companyDisplayName(
                settings: uc.company.settings,
                displayName: uc.company.displayName,
                name: uc.company.name,
              ),
              logoUrl: _companyLogoUrl(uc.company.settings),
              permissions: uc.permissions,
              isAdmin: uc.isAdmin,
              isOwner: uc.isOwner,
            ),
          )
          .toList(growable: false),
      currentCompanyId: currentId,
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
