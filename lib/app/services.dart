import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:http/http.dart' as http;

import 'package:admin/app/entity_modules.dart';
import 'package:admin/app/services_entity_wiring.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/company_gateway_repository.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/repositories/company_sync_dispatcher.dart';
import 'package:admin/data/repositories/dashboard_repository.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/data/repositories/payment_term_repository.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/data/repositories/project_repository.dart';
import 'package:admin/data/repositories/saved_views_repository.dart';
import 'package:admin/data/repositories/settings_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/repositories/sync_repository.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/data/repositories/task_status_repository.dart';
import 'package:admin/data/repositories/two_factor_repository.dart';
import 'package:admin/data/repositories/user_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/repositories/user_settings_sync_dispatcher.dart';
import 'package:admin/data/repositories/user_sync_dispatcher.dart';
import 'package:admin/data/services/activities_api.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/biometric_service.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/data/services/connectivity_watcher.dart';
import 'package:admin/data/services/documents_api.dart';
import 'package:admin/data/services/dashboard_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/data/services/support_api.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/data/services/two_factor_api.dart';
import 'package:admin/data/services/user_settings_api.dart';
import 'package:admin/data/services/users_api.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/app/accent_color_controller.dart';
import 'package:admin/app/diagnostics_log.dart';
import 'package:admin/app/locale_controller.dart';
import 'package:admin/app/sidebar_controller.dart';
import 'package:admin/app/theme_controller.dart';

/// The bag of singletons the app builds on startup. Provided via
/// `Provider<Services>` so ViewModels can read what they need without
/// hand-wiring every constructor.
///
/// Not a service locator — anything beyond app bootstrap should still take
/// its dependencies via constructor injection (ViewModel ctors do this).
///
/// **Split trigger:** when `kWiredEntityModules.length >= 6`, hoist the
/// per-entity `<Entity>sApi` + `<Entity>Repository` + `wireEntity<…>(...)`
/// blocks out of `Services.build` into a `lib/app/services_entities.dart`
/// helper (e.g. a `registerEntities(BuildContext)` extension method that
/// returns the typed repo bag). At 2–3 wired entities the linear block is
/// readable; past that, merges over `Services.build` become a hot spot.
class Services implements SidebarBadgeContext {
  Services._({
    required this.db,
    required this.auth,
    required this.clients,
    required this.products,
    required this.tasks,
    required this.taskStatuses,
    required this.projects,
    required this.companyGateways,
    required this.paymentTerms,
    required this.groupSettings,
    required this.company,
    required this.dashboard,
    required this.statics,
    required this.settings,
    required this.userSettings,
    required this.user,
    required this.savedViews,
    required this.twoFactor,
    required this.support,
    required this.activities,
    required this.sync,
    required this.entityRegistry,
    required this.connectivity,
    required this.passwordCache,
    required this.apiClient,
    required this.biometric,
    required this.theme,
    required this.accentColor,
    required this.locale,
    required this.sidebar,
    required this.settingsLevel,
    required this.serverVersion,
    required this.clientTooOld,
    required this.unsavedChangesGuard,
    this.diagnosticsLog,
  });

  final AppDatabase db;
  final AuthRepository auth;
  final ClientRepository clients;
  final ProductRepository products;

  /// Time tracking — backs the Tasks list/detail/edit screens, the kanban
  /// board, and the global running-timer pill mounted in `AppShell`.
  final TaskRepository tasks;

  /// User-defined task statuses (the kanban columns). Edited under
  /// Settings → Advanced → Task Statuses.
  final TaskStatusRepository taskStatuses;

  /// Projects — the umbrella entity that groups a client's tasks. Owns
  /// `task_rate` / `budgeted_hours` and is the parent of every task picked
  /// from the Task edit form.
  final ProjectRepository projects;

  /// Payment provider connections (Stripe, PayPal, Authorize.Net, …). Edited
  /// under Settings → Online Payments → Configure Gateways.
  final CompanyGatewayRepository companyGateways;

  /// User-defined payment terms (Net 7, Net 30, …). Edited under Settings →
  /// Advanced → Payment Terms; surfaced as a dropdown on Online Payments →
  /// Defaults. Bundled in the `/refresh` envelope alongside the company.
  final PaymentTermRepository paymentTerms;

  final GroupSettingRepository groupSettings;
  final CompanyRepository company;
  final DashboardRepository dashboard;
  final StaticsRepository statics;
  final SettingsRepository settings;
  final UserSettingsRepository userSettings;
  final ActivitiesApi activities;

  /// Reads/writes the authenticated user's profile (the row behind
  /// Settings > User Details). Distinct from [userSettings], which only
  /// handles the per-(user, company) table_columns flow against
  /// `/api/v1/company_users/{id}`.
  final UserRepository user;

  /// Local-only named snapshots of list-screen filter+sort+search state.
  /// Surfaced in the sidebar's "Saved" section and the bookmark sheet on
  /// each list screen.
  final SavedViewsRepository savedViews;

  final TwoFactorRepository twoFactor;
  final SupportApi support;
  final SyncRepository sync;

  /// Per-entity dispatchers + metadata. The sync engine, outbox screen,
  /// permissions checks, router branches, and shell navigation all read
  /// from here so adding a new entity is mechanical.
  final EntityRegistry entityRegistry;

  final ConnectivityWatcher connectivity;
  final PasswordCache passwordCache;
  final ApiClient apiClient;
  final BiometricService biometric;
  final ThemeController theme;

  /// Per-(company, user) accent color resolver. Emits the current user's
  /// `companyUserSettings.accentColor` for the active company; `null` when
  /// the user hasn't picked an override. Listened to by `MaterialApp.router`
  /// so a swatch change or company switch repaints the theme.
  final AccentColorController accentColor;

  final LocaleController locale;
  final SidebarController sidebar;

  /// App-wide settings-edit scope. When a user navigates from a client into
  /// `/settings`, this is set to [SettingsLevel.client]; every settings page
  /// reads it (via the global Provider mounted in `main.dart`) to render
  /// override checkboxes and gate company-only sections. Reset on logout
  /// and company-switch.
  final SettingsLevelController settingsLevel;

  /// Latest `x-app-version` header value from the server. Set by [ApiClient]
  /// via `onServerVersion`; the Diagnostics screen shows it for support.
  final ValueNotifier<String?> serverVersion;

  /// Non-null when the server has rejected our client version. The router
  /// redirects to `/too-old` whenever this is set so the user sees a
  /// formatted "please update" screen instead of a raw exception.
  final ValueNotifier<({String minRequired, String current})?> clientTooOld;

  /// Tracks editors with unsaved in-memory edits so navigation entry points
  /// can prompt before discarding them. Editors opt in via
  /// `UnsavedChangesScope` (lib/ui/core/unsaved_changes/).
  final UnsavedChangesGuard unsavedChangesGuard;

  /// Debug-only Claude-readable log of uncaught errors + WARNING/SEVERE
  /// Logger records, plus on-demand outbox snapshots. `null` in release
  /// builds and in unit-test wiring; see [DiagnosticsLog] for the format.
  final DiagnosticsLog? diagnosticsLog;

  // -- SidebarBadgeContext -------------------------------------------------

  @override
  Stream<int> watchClientCount(String companyId) =>
      clients.watchCount(companyId: companyId);

  @override
  Stream<int> watchOutboxPending(String companyId) =>
      db.outboxDao.watchPendingCount(companyId: companyId);

  @override
  Stream<int> watchOutboxDead(String companyId) =>
      db.outboxDao.watchDeadCount(companyId: companyId);

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
  static Services build({
    required AppDatabase db,
    TokenStorage? tokenStorage,
    BiometricService? biometricService,
    ConnectivityWatcher? connectivityWatcher,
    http.Client? httpClient,
    DiagnosticsLog? diagnosticsLog,
  }) {
    final passwordCache = PasswordCache();
    final authService = AuthService(httpClient: httpClient);
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
      httpClient: httpClient,
    );
    // Close the construction cycle: auth.addCompany uses apiClient to POST
    // /companies + GET /refresh; apiClient already reads auth.credentials.
    auth.apiClient = apiClient;
    // Empty mutable shell — populated below once entity repos exist. The
    // sync engine can be built without a registry filled in yet because
    // dispatch only fires inside [drainOnce], which won't run until after
    // construction completes.
    final registry = EntityRegistry({});
    final sync = SyncRepository(db: db, registry: registry);
    // Wired into every BaseEntityRepository's onEnqueued so a mutation
    // drains as soon as it lands in the outbox (instead of sitting until
    // the next user-driven trigger). Fire-and-forget — drainOnce returns a
    // Future the caller intentionally drops; failures are surfaced via the
    // SyncEvent stream the UI shell already listens to.
    void kickDrain(String companyId) {
      sync.drainOnce(companyId: companyId);
    }

    // Per-entity dispatcher registry — populated by [wireEntities] below and
    // by the non-entity blocks (company, user) further down.
    final dispatchers = <EntityType, SyncDispatcher>{};

    final activitiesApi = ActivitiesApi(apiClient);
    final documentsApi = DocumentsApi(apiClient);

    // Build every CRUD-list entity (api + repository + sync dispatcher
    // registration). One block per entity lives in services_entity_wiring.dart
    // — see the file header for the rationale. Adding a new entity touches
    // that file plus kWiredEntityModules; services.dart stays untouched.
    final entities = wireEntities(
      EntityWiringContext(
        apiClient: apiClient,
        db: db,
        activitiesApi: activitiesApi,
        documentsApi: documentsApi,
        kickDrain: kickDrain,
        dispatchers: dispatchers,
      ),
    );
    final companiesApi = CompaniesApi(apiClient);
    final companyRepo = CompanyRepository(
      db: db,
      api: companiesApi,
      onEnqueued: kickDrain,
    );
    final dashboardApi = DashboardApi(apiClient);
    final dashboardRepo = DashboardRepository(db: db, api: dashboardApi);
    final statics = StaticsRepository(
      db: db,
      service: StaticsService(apiClient),
    );
    final settings = SettingsRepository(db: db);
    final userSettingsApi = UserSettingsApi(apiClient);
    final userSettingsRepo = UserSettingsRepository(
      db: db,
      onEnqueued: kickDrain,
    );
    final usersApi = UsersApi(apiClient);
    final userRepo = UserRepository(
      db: db,
      api: usersApi,
      onEnqueued: kickDrain,
    );
    final savedViewsRepo = SavedViewsRepository(
      db: db,
      userSettings: userSettingsRepo,
    );
    final twoFactorApi = TwoFactorApi(apiClient);
    final twoFactorRepo = TwoFactorRepository(api: twoFactorApi, auth: auth);
    final supportApi = SupportApi(apiClient);

    // Assemble the registry from the static module specs. Wired modules
    // pick up the dispatcher [wireEntity] registered above; disabled
    // modules get a stub dispatcher that throws if invoked.
    final handlers = <EntityType, EntityHandlers>{};
    for (final spec in kWiredEntityModules) {
      final dispatcher = dispatchers[spec.type];
      assert(
        dispatcher != null,
        'Wired entity ${spec.type} has no dispatcher in services.dart',
      );
      handlers[spec.type] = spec.toHandlers(dispatcher!);
    }
    for (final spec in kDisabledEntityModules) {
      handlers[spec.type] = spec.toHandlers(
        DisabledEntityDispatcher(spec.type),
      );
    }
    // Non-entity registrations that exist only for sync (no list/detail UI,
    // not in the sidebar). These don't fit the EntityModuleSpec mould.
    handlers[EntityType.company] = EntityHandlers(
      type: EntityType.company,
      wireName: 'company',
      apiPath: '/api/v1/companies',
      routePath: '/settings/company_details',
      icon: Icons.business,
      sidebarSection: SidebarSection.none,
      dispatcher: CompanySyncDispatcher(api: companiesApi, repo: companyRepo),
    );
    handlers[EntityType.user] = EntityHandlers(
      type: EntityType.user,
      wireName: kUserSettingsWireName,
      // `'user'` rows (full-user PUTs from Settings > User Details) flow
      // through the same composite dispatcher; see [CompositeUserDispatcher].
      extraWireNames: const [kUserWireName],
      apiPath: '/api/v1/company_users',
      routePath: '/settings/account',
      icon: Icons.person,
      sidebarSection: SidebarSection.none,
      dispatcher: CompositeUserDispatcher(
        userSettings: UserSettingsSyncDispatcher(
          api: userSettingsApi,
          repo: userSettingsRepo,
        ),
        user: UserSyncDispatcher(api: usersApi, repo: userRepo, auth: auth),
      ),
    );
    registry.replaceAll(handlers, branchOrder: kBranchOrder);

    // Close the second construction cycle: logout needs to halt in-flight
    // sync before wiping Drift; SyncRepository itself reads from Drift only,
    // so it can be built without AuthRepository.
    auth.onBeforeLogout = sync.cancel;
    auth.onActiveCompanyChanged = kickDrain;
    // Fan-out the bundled per-entity arrays the /refresh envelope carries
    // alongside the company. Each [wireEntities] block contributes its own
    // applier to [entities.bundleAppliers]; this loop runs them in order.
    auth.onPersistBundles = ({required companyId, required company}) async {
      for (final apply in entities.bundleAppliers) {
        await apply(companyId: companyId, company: company);
      }
    };
    // Auto-drain on connectivity transitions to online — the offline edits
    // that piled up will all flush as soon as the radio comes back.
    final connectivity = connectivityWatcher ?? ConnectivityWatcher.live();
    connectivity.onOnline.listen((_) {
      final companyId = auth.session.value?.currentCompanyId;
      if (companyId == null || companyId.isEmpty) return;
      sync.drainOnce(companyId: companyId);
    });
    final theme = ThemeController(db: db);
    final accentColor = AccentColorController(auth: auth, users: userRepo);
    final locale = LocaleController(db: db);
    final sidebar = SidebarController(db: db);
    final settingsLevel = SettingsLevelController();
    // Reset the settings scope whenever the user logs out or switches
    // company — otherwise the next login would inherit a stale clientId
    // from the previous session and the settings shell would render the
    // banner against a missing target.
    final priorOnBeforeLogout = auth.onBeforeLogout;
    auth.onBeforeLogout = () async {
      settingsLevel.reset();
      if (priorOnBeforeLogout != null) await priorOnBeforeLogout();
    };
    final priorOnActiveCompanyChanged = auth.onActiveCompanyChanged;
    auth.onActiveCompanyChanged = (companyId) {
      settingsLevel.reset();
      priorOnActiveCompanyChanged?.call(companyId);
    };
    return Services._(
      db: db,
      auth: auth,
      clients: entities.clients,
      products: entities.products,
      tasks: entities.tasks,
      taskStatuses: entities.taskStatuses,
      projects: entities.projects,
      companyGateways: entities.companyGateways,
      paymentTerms: entities.paymentTerms,
      groupSettings: entities.groupSettings,
      company: companyRepo,
      dashboard: dashboardRepo,
      statics: statics,
      settings: settings,
      userSettings: userSettingsRepo,
      user: userRepo,
      savedViews: savedViewsRepo,
      twoFactor: twoFactorRepo,
      support: supportApi,
      activities: activitiesApi,
      sync: sync,
      entityRegistry: registry,
      connectivity: connectivity,
      passwordCache: passwordCache,
      apiClient: apiClient,
      biometric: biometricService ?? LocalAuthBiometricService(),
      theme: theme,
      accentColor: accentColor,
      locale: locale,
      sidebar: sidebar,
      settingsLevel: settingsLevel,
      serverVersion: serverVersion,
      clientTooOld: clientTooOld,
      unsavedChangesGuard: UnsavedChangesGuard(),
      diagnosticsLog: diagnosticsLog,
    );
  }
}
