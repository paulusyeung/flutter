import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:http/http.dart' as http;

import 'package:admin/app/entity_modules.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/repositories/company_sync_dispatcher.dart';
import 'package:admin/data/repositories/dashboard_repository.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/data/repositories/product_repository.dart';
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
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/data/services/connectivity_watcher.dart';
import 'package:admin/data/services/documents_api.dart';
import 'package:admin/data/services/dashboard_api.dart';
import 'package:admin/data/services/group_settings_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/products_api.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/data/services/support_api.dart';
import 'package:admin/data/services/task_statuses_api.dart';
import 'package:admin/data/services/tasks_api.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/data/services/two_factor_api.dart';
import 'package:admin/data/services/user_settings_api.dart';
import 'package:admin/data/services/users_api.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/api/group_setting_api_model.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/api/task_api_model.dart';
import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/base_entity_api.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/app/accent_color_controller.dart';
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

    // Per-entity dispatcher registry — populated by [wireEntity] below and
    // by the non-entity blocks (company, user) further down.
    final dispatchers = <EntityType, SyncDispatcher>{};

    // Standard CRUD-list wiring. Caller constructs the api + repo (so each
    // entity keeps its named ctor — some take extra args like `db`); the
    // helper registers the matching dispatcher.
    //
    // The `dataOf: (i) => (i as dynamic).data` cast holds because every
    // `<Entity>ItemApi` freezed envelope has a `.data` field of type
    // `<Entity>Api` by convention. The contract-test harness exercises this
    // path on every entity, so a misshaped envelope fails the suite before
    // it can land in production.
    void wireEntity<TItem, TInner>({
      required EntityType type,
      required BaseEntityApi<dynamic, TItem> api,
      required BaseEntityRepository<dynamic, TInner> repo,
      Map<MutationKind, CustomMutationHandler<TInner>>? customActions,
    }) {
      dispatchers[type] = BaseEntitySyncDispatcher<TItem, TInner>(
        api: api,
        repo: repo,
        dataOf: (i) => (i as dynamic).data as TInner,
        customActions: customActions,
      );
    }

    final activitiesApi = ActivitiesApi(apiClient);
    final documentsApi = DocumentsApi(apiClient);

    final clientsApi = ClientsApi(apiClient);
    final clientRepo = ClientRepository(
      db: db,
      api: clientsApi,
      onEnqueued: kickDrain,
    );
    // Module spec: kWiredEntityModules entry in lib/app/entity_modules.dart.
    wireEntity<ClientItemApi, ClientApi>(
      type: EntityType.client,
      api: clientsApi,
      repo: clientRepo,
      // `customActions` is the canonical hook for non-CRUD entity actions
      // (Invoice's `markPaid`, Task's `start/stop`, etc.). Each entry adds a
      // `MutationKind` value the repository can `enqueueMutation(...)`, plus
      // a one-line dispatch closure invoked when the outbox row drains. See
      // CLAUDE.md § "Adding a new entity" → "Non-standard actions".
      customActions: {
        // POST /api/v1/activities/notes — append a comment. The endpoint
        // isn't under /clients/, so it can't ride [api.action]; we route
        // through the dedicated [ActivitiesApi]. Server response is
        // discarded — the Activity tab refetches once the pending outbox
        // row drains.
        MutationKind.addComment: ({required row, required payload}) async {
          await activitiesApi.addNote(
            entity: 'clients',
            entityId: payload['entity_id'] as String,
            notes: payload['notes'] as String,
            idempotencyKey: row.idempotencyKey,
          );
          return null;
        },
        // POST /api/v1/clients/{id}/upload — multipart with one document.
        // Returns the refreshed client envelope; we lift it to ClientApi so
        // the base dispatcher's auto-applyUpdateResponse refreshes the row
        // (which now carries the new document in its `documents` array).
        MutationKind.documentUpload: ({required row, required payload}) async {
          final localPath = payload['local_path'] as String;
          final clientId = payload['entity_id'] as String;
          if (!File(localPath).existsSync()) {
            // File was moved/deleted between enqueue and dispatch. Drop the
            // row rather than 5xx-looping — matches CompanySyncDispatcher.
            return null;
          }
          final response = await clientsApi.uploadDocument(
            clientId: clientId,
            filePath: localPath,
            idempotencyKey: row.idempotencyKey,
          );
          return response.data;
        },
        // DELETE /api/v1/documents/{id} — server response is empty. Patch
        // the local row directly and return null (no applyUpdateResponse).
        MutationKind.documentDelete: ({required row, required payload}) async {
          final documentId = payload['document_id'] as String;
          final clientId = payload['entity_id'] as String;
          await documentsApi.delete(
            id: documentId,
            idempotencyKey: row.idempotencyKey,
            requiresPassword: true,
          );
          await clientRepo.applyDocumentDeleted(
            companyId: row.companyId,
            clientId: clientId,
            documentId: documentId,
          );
          return null;
        },
        // PUT /api/v1/documents/{id} — server returns the updated document.
        // Patch the local row's `documents` array and return null.
        MutationKind.documentVisibility:
            ({required row, required payload}) async {
              final documentId = payload['document_id'] as String;
              final clientId = payload['entity_id'] as String;
              final isPublic = payload['is_public'] as bool;
              final updated = await documentsApi.setVisibility(
                id: documentId,
                isPublic: isPublic,
                idempotencyKey: row.idempotencyKey,
              );
              if (updated != null) {
                await clientRepo.applyDocumentChanged(
                  companyId: row.companyId,
                  clientId: clientId,
                  document: updated,
                );
              }
              return null;
            },
      },
    );

    final productsApi = ProductsApi(apiClient);
    final productRepo = ProductRepository(
      db: db,
      api: productsApi,
      onEnqueued: kickDrain,
    );
    // Module spec: kWiredEntityModules entry in lib/app/entity_modules.dart.
    wireEntity<ProductItemApi, ProductApi>(
      type: EntityType.product,
      api: productsApi,
      repo: productRepo,
      customActions: {
        MutationKind.documentUpload: ({required row, required payload}) async {
          final localPath = payload['local_path'] as String;
          final productId = payload['entity_id'] as String;
          if (!File(localPath).existsSync()) return null;
          final response = await productsApi.uploadDocument(
            productId: productId,
            filePath: localPath,
            idempotencyKey: row.idempotencyKey,
          );
          return response.data;
        },
        MutationKind.documentDelete: ({required row, required payload}) async {
          final documentId = payload['document_id'] as String;
          final productId = payload['entity_id'] as String;
          await documentsApi.delete(
            id: documentId,
            idempotencyKey: row.idempotencyKey,
            requiresPassword: true,
          );
          await productRepo.applyDocumentDeleted(
            companyId: row.companyId,
            productId: productId,
            documentId: documentId,
          );
          return null;
        },
        MutationKind.documentVisibility:
            ({required row, required payload}) async {
              final documentId = payload['document_id'] as String;
              final productId = payload['entity_id'] as String;
              final isPublic = payload['is_public'] as bool;
              final updated = await documentsApi.setVisibility(
                id: documentId,
                isPublic: isPublic,
                idempotencyKey: row.idempotencyKey,
              );
              if (updated != null) {
                await productRepo.applyDocumentChanged(
                  companyId: row.companyId,
                  productId: productId,
                  document: updated,
                );
              }
              return null;
            },
      },
    );

    final tasksApi = TasksApi(apiClient);
    final taskRepo = TaskRepository(
      db: db,
      api: tasksApi,
      onEnqueued: kickDrain,
    );
    wireEntity<TaskItemApi, TaskApi>(
      type: EntityType.task,
      api: tasksApi,
      repo: taskRepo,
      customActions: {
        // Kanban drag-drop + task-statuses reorder both ride this handler.
        // Payload carries `{status_ids, task_ids}` (tasks) or just
        // `{status_ids}` (statuses, routed via the task_statuses block
        // below).
        MutationKind.reorder: ({required row, required payload}) async {
          await tasksApi.sort(
            payload: payload,
            idempotencyKey: row.idempotencyKey,
          );
          // Server returns 200 with no per-task envelope; the local rows
          // already carry the optimistic ordering. Returning null tells
          // the dispatcher to skip `applyUpdateResponse`.
          return null;
        },
      },
    );

    final taskStatusesApi = TaskStatusesApi(apiClient);
    final taskStatusRepo = TaskStatusRepository(
      db: db,
      api: taskStatusesApi,
      onEnqueued: kickDrain,
    );
    wireEntity<TaskStatusItemApi, TaskStatusApi>(
      type: EntityType.taskStatus,
      api: taskStatusesApi,
      repo: taskStatusRepo,
      customActions: {
        MutationKind.reorder: ({required row, required payload}) async {
          await taskStatusesApi.sort(
            payload: payload,
            idempotencyKey: row.idempotencyKey,
          );
          return null;
        },
      },
    );

    final groupSettingsApi = GroupSettingsApi(apiClient);
    final groupSettingRepo = GroupSettingRepository(
      db: db,
      api: groupSettingsApi,
      onEnqueued: kickDrain,
    );
    wireEntity<GroupSettingItemApi, GroupSettingApi>(
      type: EntityType.group,
      api: groupSettingsApi,
      repo: groupSettingRepo,
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
    // Groups (`group_settings`) — full entity wiring, but no top-level nav.
    // Lives under `/settings/group_settings/...`; the wireEntity call above
    // registered the standard BaseEntitySyncDispatcher in `dispatchers`.
    handlers[EntityType.group] = EntityHandlers(
      type: EntityType.group,
      wireName: 'group',
      apiPath: '/api/v1/group_settings',
      routePath: '/settings/group_settings',
      icon: Icons.group_work_outlined,
      sidebarSection: SidebarSection.none,
      requiresPasswordFor: const {MutationKind.delete},
      dispatcher: dispatchers[EntityType.group]!,
    );
    // Task statuses — full entity wiring, no top-level nav (lives under
    // Settings → Advanced → Task Statuses).
    handlers[EntityType.taskStatus] = EntityHandlers(
      type: EntityType.taskStatus,
      wireName: 'task_status',
      apiPath: '/api/v1/task_statuses',
      routePath: '/settings/task_statuses',
      icon: Icons.label_outline,
      sidebarSection: SidebarSection.none,
      requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
      dispatcher: dispatchers[EntityType.taskStatus]!,
    );
    registry.replaceAll(handlers, branchOrder: kBranchOrder);

    // Close the second construction cycle: logout needs to halt in-flight
    // sync before wiping Drift; SyncRepository itself reads from Drift only,
    // so it can be built without AuthRepository.
    auth.onBeforeLogout = sync.cancel;
    auth.onActiveCompanyChanged = kickDrain;
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
      clients: clientRepo,
      products: productRepo,
      tasks: taskRepo,
      taskStatuses: taskStatusRepo,
      groupSettings: groupSettingRepo,
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
    );
  }
}
