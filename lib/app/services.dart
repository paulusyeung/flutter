import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/client_sync_dispatcher.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/repositories/company_sync_dispatcher.dart';
import 'package:admin/data/repositories/dashboard_repository.dart';
import 'package:admin/data/repositories/settings_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/repositories/sync_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/repositories/user_settings_sync_dispatcher.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/data/services/dashboard_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/data/services/user_settings_api.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/app/locale_controller.dart';
import 'package:admin/app/theme_controller.dart';

/// The bag of singletons the app builds on startup. Provided via
/// `Provider<Services>` so ViewModels can read what they need without
/// hand-wiring every constructor.
///
/// Not a service locator — anything beyond app bootstrap should still take
/// its dependencies via constructor injection (ViewModel ctors do this).
class Services {
  Services._({
    required this.db,
    required this.auth,
    required this.clients,
    required this.company,
    required this.dashboard,
    required this.statics,
    required this.settings,
    required this.userSettings,
    required this.sync,
    required this.passwordCache,
    required this.apiClient,
    required this.theme,
    required this.locale,
    required this.serverVersion,
    required this.clientTooOld,
  });

  final AppDatabase db;
  final AuthRepository auth;
  final ClientRepository clients;
  final CompanyRepository company;
  final DashboardRepository dashboard;
  final StaticsRepository statics;
  final SettingsRepository settings;
  final UserSettingsRepository userSettings;
  final SyncRepository sync;
  final PasswordCache passwordCache;
  final ApiClient apiClient;
  final ThemeController theme;
  final LocaleController locale;

  /// Latest `x-app-version` header value from the server. Set by [ApiClient]
  /// via `onServerVersion`; the Diagnostics screen shows it for support.
  final ValueNotifier<String?> serverVersion;

  /// Non-null when the server has rejected our client version. The router
  /// redirects to `/too-old` whenever this is set so the user sees a
  /// formatted "please update" screen instead of a raw exception.
  final ValueNotifier<({String minRequired, String current})?> clientTooOld;

  /// Build a [Formatter] bound to the given company. Awaits
  /// `statics.ensureLoaded()` (idempotent — a no-op once warm) and reads the
  /// company's settings JSON from Drift.
  ///
  /// Memoized per-company: a detail screen that calls this once per money
  /// field doesn't hit Drift N times. Call [invalidateFormatter] when a
  /// company's settings are updated (e.g. SettingsRepository writes) so the
  /// next read rebuilds.
  ///
  /// Falls back to [CompanyFormatSettings.fallback] when the company row is
  /// missing — keeps the UI working on a stale/empty cache instead of
  /// throwing.
  Future<Formatter> formatterFor(String companyId) {
    final cached = _formatterCache[companyId];
    if (cached != null) return cached;
    final future = _buildFormatter(companyId);
    _formatterCache[companyId] = future;
    // If the build fails (e.g. statics service threw), evict so the next
    // call retries instead of returning a poisoned future forever.
    future.then((_) {}, onError: (_) => _formatterCache.remove(companyId));
    return future;
  }

  Future<Formatter> _buildFormatter(String companyId) async {
    await statics.ensureLoaded();
    final row = await db.companiesDao.byId(companyId);
    final settings = row == null
        ? CompanyFormatSettings.fallback
        : CompanyFormatSettings.fromCompanyJson(
            row.settings.isEmpty
                ? const {}
                : jsonDecode(row.settings) as Map<String, dynamic>,
          );
    return Formatter(
      settings: settings,
      currencies: statics.currencies,
      countries: statics.countries,
      dateFormats: statics.dateFormats,
    );
  }

  /// Drop the cached [Formatter] for [companyId]. Call after writing the
  /// company's settings or after a statics refresh so the next
  /// [formatterFor] rebuilds against fresh state. Cheap when no entry is
  /// cached.
  void invalidateFormatter(String companyId) {
    _formatterCache.remove(companyId);
  }

  /// Drop every cached [Formatter]. Called on logout (via [Services.build]'s
  /// teardown path) so a subsequent login can't observe the previous user's
  /// company-currency settings.
  void invalidateAllFormatters() {
    _formatterCache.clear();
  }

  final Map<String, Future<Formatter>> _formatterCache = {};

  /// Construct the full graph. The DB is passed in so `main.dart` can pick
  /// the open-with-recovery code path and surface a banner if needed.
  static Services build({required AppDatabase db, TokenStorage? tokenStorage}) {
    final passwordCache = PasswordCache();
    final authService = AuthService();
    final auth = AuthRepository(
      db: db,
      authService: authService,
      tokenStorage: tokenStorage ?? SecureTokenStorage(),
      passwordCache: passwordCache,
    );
    final serverVersion = ValueNotifier<String?>(null);
    final clientTooOld = ValueNotifier<({String minRequired, String current})?>(
      null,
    );
    final apiClient = ApiClient(
      credentials: auth.credentials,
      passwordCache: passwordCache,
      onUnauthorized: auth.logout,
      onServerVersion: (v) => serverVersion.value = v,
      onClientTooOld: (info) => clientTooOld.value = info,
    );
    // Close the construction cycle: auth.addCompany uses apiClient to POST
    // /companies + GET /refresh; apiClient already reads auth.credentials.
    auth.apiClient = apiClient;
    final clientsApi = ClientsApi(apiClient);
    final clientRepo = ClientRepository(db: db, api: clientsApi);
    final companiesApi = CompaniesApi(apiClient);
    final companyRepo = CompanyRepository(db: db, api: companiesApi);
    final dashboardApi = DashboardApi(apiClient);
    final dashboardRepo = DashboardRepository(db: db, api: dashboardApi);
    final statics = StaticsRepository(
      db: db,
      service: StaticsService(apiClient),
    );
    final settings = SettingsRepository(db: db);
    final userSettingsApi = UserSettingsApi(apiClient);
    final userSettingsRepo = UserSettingsRepository(db: db);
    final registry = EntityRegistry({
      EntityType.client: EntityHandlers(
        type: EntityType.client,
        wireName: 'client',
        apiPath: '/api/v1/clients',
        routePath: '/clients',
        icon: Icons.people,
        requiresPasswordFor: const {MutationKind.delete},
        dispatcher: ClientSyncDispatcher(api: clientsApi, repo: clientRepo),
      ),
      EntityType.company: EntityHandlers(
        type: EntityType.company,
        wireName: 'company',
        apiPath: '/api/v1/companies',
        routePath: '/settings/company_details',
        icon: Icons.business,
        dispatcher: CompanySyncDispatcher(api: companiesApi, repo: companyRepo),
      ),
      EntityType.user: EntityHandlers(
        type: EntityType.user,
        wireName: kUserSettingsWireName,
        apiPath: '/api/v1/company_users',
        routePath: '/settings/account',
        icon: Icons.person,
        dispatcher: UserSettingsSyncDispatcher(
          api: userSettingsApi,
          repo: userSettingsRepo,
        ),
      ),
    });
    final sync = SyncRepository(db: db, registry: registry);
    final theme = ThemeController(db: db);
    final locale = LocaleController(db: db);
    return Services._(
      db: db,
      auth: auth,
      clients: clientRepo,
      company: companyRepo,
      dashboard: dashboardRepo,
      statics: statics,
      settings: settings,
      userSettings: userSettingsRepo,
      sync: sync,
      passwordCache: passwordCache,
      apiClient: apiClient,
      theme: theme,
      locale: locale,
      serverVersion: serverVersion,
      clientTooOld: clientTooOld,
    );
  }
}
