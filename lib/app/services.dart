import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;

import '../data/db/app_database.dart';
import '../data/models/value/company_format_settings.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/client_sync_dispatcher.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/statics_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../data/repositories/user_settings_repository.dart';
import '../data/repositories/user_settings_sync_dispatcher.dart';
import '../data/services/api_client.dart';
import '../data/services/auth_service.dart';
import '../data/services/clients_api.dart';
import '../data/services/password_cache.dart';
import '../data/services/statics_service.dart';
import '../data/services/token_storage.dart';
import '../data/services/user_settings_api.dart';
import '../domain/entity_registry.dart';
import '../domain/entity_type.dart';
import '../domain/sync/mutation.dart';
import '../utils/formatting.dart';
import 'locale_controller.dart';
import 'theme_controller.dart';

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
  /// Falls back to [CompanyFormatSettings.fallback] when the company row is
  /// missing — keeps the UI working on a stale/empty cache instead of
  /// throwing.
  Future<Formatter> formatterFor(String companyId) async {
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

  /// Construct the full graph. The DB is passed in so `main.dart` can pick
  /// the open-with-recovery code path and surface a banner if needed.
  static Services build({required AppDatabase db, TokenStorage? tokenStorage}) {
    final passwordCache = PasswordCache();
    final authService = AuthService();
    final auth = AuthRepository(
      db: db,
      authService: authService,
      tokenStorage: tokenStorage ?? SecureTokenStorage(),
    );
    final serverVersion = ValueNotifier<String?>(null);
    final clientTooOld =
        ValueNotifier<({String minRequired, String current})?>(null);
    final apiClient = ApiClient(
      credentials: auth.credentials,
      passwordCache: passwordCache,
      onUnauthorized: auth.logout,
      onServerVersion: (v) => serverVersion.value = v,
      onClientTooOld: (info) => clientTooOld.value = info,
    );
    final clientsApi = ClientsApi(apiClient);
    final clientRepo = ClientRepository(db: db, api: clientsApi);
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
