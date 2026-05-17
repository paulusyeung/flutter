import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:admin/app/entity_modules.dart';
import 'package:admin/app/search_focus_registry.dart';
import 'package:admin/app/services_entity_wiring.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/bank_account_repository.dart';
import 'package:admin/data/repositories/bank_transaction_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/company_gateway_repository.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/repositories/company_sync_dispatcher.dart';
import 'package:admin/data/repositories/dashboard_repository.dart';
import 'package:admin/data/repositories/expense_category_repository.dart';
import 'package:admin/data/repositories/expense_repository.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/data/repositories/payment_repository.dart';
import 'package:admin/data/repositories/payment_term_repository.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/data/repositories/project_repository.dart';
import 'package:admin/data/repositories/credit_repository.dart';
import 'package:admin/data/repositories/purchase_order_repository.dart';
import 'package:admin/data/repositories/quickbooks_repository.dart';
import 'package:admin/data/repositories/recurring_invoice_repository.dart';
import 'package:admin/data/repositories/quote_repository.dart';
import 'package:admin/data/repositories/recurring_expense_repository.dart';
import 'package:admin/data/repositories/reports_repository.dart';
import 'package:admin/data/repositories/saved_views_repository.dart';
import 'package:admin/data/repositories/schedule_repository.dart';
import 'package:admin/data/repositories/settings_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/repositories/system_log_repository.dart';
import 'package:admin/data/repositories/payment_link_repository.dart';
import 'package:admin/data/repositories/sync_repository.dart';
import 'package:admin/data/services/refresh_scheduler.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/data/repositories/task_status_repository.dart';
import 'package:admin/data/repositories/tax_rate_repository.dart';
import 'package:admin/data/repositories/transaction_rule_repository.dart';
import 'package:admin/data/repositories/vendor_repository.dart';
import 'package:admin/data/repositories/two_factor_repository.dart';
import 'package:admin/data/repositories/user_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/repositories/user_settings_sync_dispatcher.dart';
import 'package:admin/data/repositories/token_repository.dart';
import 'package:admin/data/repositories/user_sync_dispatcher.dart';
import 'package:admin/data/repositories/webhook_repository.dart';
import 'package:admin/data/services/activities_api.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/biometric_service.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/data/services/connectivity_watcher.dart';
import 'package:admin/data/services/documents_api.dart';
import 'package:admin/data/services/dashboard_api.dart';
import 'package:admin/data/services/reports_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/data/services/system_api.dart';
import 'package:admin/data/services/system_logs_api.dart';
import 'package:admin/data/services/smtp_api.dart';
import 'package:admin/data/services/templates_api.dart';
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
import 'package:admin/app/debug_capture_store.dart';
import 'package:admin/app/diagnostics_log.dart';
import 'package:admin/app/locale_controller.dart';
import 'package:admin/app/sidebar_controller.dart';
import 'package:admin/app/theme_controller.dart';

final Logger _servicesLog = Logger('Services');

/// Top-level helper so the prefetch can fire from the
/// `auth.onActiveCompanyChanged` wrap inside `Services.build` (where the
/// `Services` instance doesn't exist yet) AND from the instance method
/// [Services.prefetchSidebarEntities]. Both call sites use this same body.
Future<void> _prefetchSidebarOnCompanyChange(
  WiredEntities entities,
  String companyId,
) => _runSidebarPrefetch(entities.firstPagePrefetchers, companyId);

Future<void> _runSidebarPrefetch(
  Map<EntityType, Future<bool> Function(String companyId)> prefetchers,
  String companyId,
) async {
  if (companyId.isEmpty) return;
  final futures = <Future<void>>[];
  for (final spec in kWiredEntityModules) {
    if (spec.sidebarSection == SidebarSection.none) continue;
    final prefetch = prefetchers[spec.type];
    if (prefetch == null) continue;
    futures.add(
      prefetch(companyId).then<void>(
        (_) => null,
        onError: (Object e, StackTrace st) {
          _servicesLog.warning('prefetch failed for ${spec.type.name}', e, st);
        },
      ),
    );
  }
  await Future.wait(futures);
}

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
    required this.vendors,
    required this.expenses,
    required this.recurringExpenses,
    required this.expenseCategories,
    required this.companyGateways,
    required this.paymentTerms,
    required this.taxRates,
    required this.designs,
    required this.groupSettings,
    required this.paymentLinks,
    required this.schedules,
    required this.invoices,
    required this.quotes,
    required this.credits,
    required this.purchaseOrders,
    required this.recurringInvoices,
    required this.bankAccounts,
    required this.bankTransactions,
    required this.transactionRules,
    required this.payments,
    required this.webhooks,
    required this.tokens,
    required this.company,
    required this.companies,
    required this.quickbooks,
    required this.dashboard,
    required this.reports,
    required this.statics,
    required this.system,
    required this.systemLogs,
    required this.settings,
    required this.userSettings,
    required this.user,
    required this.savedViews,
    required this.twoFactor,
    required this.support,
    required this.smtp,
    required this.templates,
    required this.activities,
    required this.sync,
    required this.refreshScheduler,
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
    required this.debugCaptureStore,
    required this.debugPanelRevealed,
    this.diagnosticsLog,
    required Map<EntityType, Stream<int> Function(String companyId)>
    countWatchers,
    required Map<EntityType, Future<bool> Function(String companyId)>
    firstPagePrefetchers,
  }) : _countWatchers = countWatchers,
       _firstPagePrefetchers = firstPagePrefetchers;

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

  /// Vendors — top-level CRUD entity, document-bearing. Parent of every
  /// expense via `vendor_id`. Owns its own contacts list (carried inside
  /// the payload JSON, mirroring Client).
  final VendorRepository vendors;

  /// Expenses — top-level CRUD entity, document-bearing. Links to vendor,
  /// client, project, category, and (optionally) an invoice generated from
  /// the expense. Money fields are `Decimal`; tax tier rates respect
  /// `enabled_expense_tax_rates` from company settings.
  final ExpenseRepository expenses;

  /// Recurring expenses — superset of Expense with frequency / cycles /
  /// next-send-date / stored `status_id`. Start / Stop ride dedicated
  /// `MutationKind.start` / `.stop` outbox rows that route through
  /// `?start=true` / `?stop=true` query params.
  final RecurringExpenseRepository recurringExpenses;

  /// Expense categories — small bundled reference list (id + name + color)
  /// delivered via the `/refresh?first_load=true` envelope alongside the
  /// company AND paginated through `/api/v1/expense_categories` for offline
  /// edits. Settings-only entity reached via Settings → Advanced.
  final ExpenseCategoryRepository expenseCategories;

  /// Payment provider connections (Stripe, PayPal, Authorize.Net, …). Edited
  /// under Settings → Online Payments → Configure Gateways.
  final CompanyGatewayRepository companyGateways;

  /// User-defined payment terms (Net 7, Net 30, …). Edited under Settings →
  /// Advanced → Payment Terms; surfaced as a dropdown on Online Payments →
  /// Defaults. Bundled in the `/refresh` envelope alongside the company.
  final PaymentTermRepository paymentTerms;

  /// Tax rates — small bundled reference list, populates the default-tax
  /// pickers on Settings → Tax Settings. Loaded via `/refresh?first_load=true`
  /// alongside `payment_terms` / `task_statuses`. No CRUD screen yet — the
  /// entity sits in `kDisabledEntityModules` until that page lands.
  final TaxRateRepository taxRates;

  /// Invoice / quote / credit / purchase-order design templates. Bundled via
  /// `/refresh?first_load=true` (data[N].company.designs) — the Invoice
  /// Design pickers and the upcoming Custom Designs CRUD read from this repo.
  final DesignRepository designs;

  final GroupSettingRepository groupSettings;

  /// Payment Links — small bundled reference list delivered via
  /// `/refresh?first_load=true` alongside the company AND paginated
  /// through `/api/v1/subscriptions` for offline edits. Wire name is
  /// `subscription`; we use `payment_link` everywhere internally to
  /// match the user-facing label. Settings-only entity reached via
  /// Settings → Advanced → Payment Links.
  final PaymentLinkRepository paymentLinks;

  /// Schedules ("task schedulers") — bundled settings entity reached via
  /// Settings → Advanced → Schedules. Server includes
  /// `company.task_schedulers` in the `/refresh?first_load=true` envelope;
  /// `ScheduleRepository.applyBundle` upserts into the local table on
  /// every login/refresh.
  final ScheduleRepository schedules;

  /// Invoices — top-level CRUD entity, document-bearing. Line items live as
  /// nested JSON inside the payload (no separate `line_items` table); the
  /// `LineItem` value type is shared with future Quote / Credit /
  /// PurchaseOrder / RecurringInvoice. Custom actions (markSent / markPaid
  /// / email / scheduleEmail / cloneTo{Invoice|Quote|Credit|Recurring|PO}
  /// / autoBill / cancel / runTemplate) ride dedicated `MutationKind`
  /// values routed through `customActions` in `services_entity_wiring`.
  final InvoiceRepository invoices;

  /// Quotes — mirrors Invoice's shape (line items, invitations, taxes,
  /// design, exchange rate) with a quote-specific status enum (Draft /
  /// Sent / Approved / Converted) and the three conversion actions
  /// (`approve`, `convertToInvoice`, `convertToProject`).
  final QuoteRepository quotes;

  /// Credits — mirrors Invoice's shape (line items, invitations, taxes,
  /// design, exchange rate) with a credit-specific status enum (Draft /
  /// Sent / Partial / Applied) and a `paid_to_date` tracker for partial
  /// applications across invoices.
  final CreditRepository credits;

  /// Purchase Orders — vendor-centric mirror of Quote (line items,
  /// invitations, taxes, design, exchange rate). Status lifecycle is
  /// Draft / Sent / Accepted / Received / Cancelled. Owns the `accept`
  /// and `convert_to_expense` custom actions in addition to the usual
  /// mark_sent / email / schedule_email / clone_to_* / run_template /
  /// addComment / cancelEntity surface.
  final PurchaseOrderRepository purchaseOrders;

  /// Recurring Invoices — invoice-shaped template that the server uses to
  /// spawn invoices on a schedule. Owns the `start` / `stop` lifecycle
  /// actions in addition to the usual mark_sent / email / clone_to_* /
  /// run_template surface. Status lifecycle: Draft / Active / Paused /
  /// Completed (with `pending` computed when next_send_date is future).
  final RecurringInvoiceRepository recurringInvoices;

  /// Bank integrations (Yodlee / Nordigen / manual). Edited under
  /// Settings → Bank Accounts. Owns the `refresh_accounts` custom action
  /// that pings the upstream provider for fresh balances.
  final BankAccountRepository bankAccounts;

  /// Bank transactions — top-level workspace entity at `/transactions`.
  /// Owns the four `match` variants (CREDIT/DEBIT × create/link) and the
  /// two bulk actions (`convert_matched`, `unlink`) that move rows
  /// through Unmatched → Matched → Converted.
  final BankTransactionRepository bankTransactions;

  /// Transaction rules — auto-categorize incoming bank transactions.
  /// Edited under Settings → Bank Accounts → Rules.
  final TransactionRuleRepository transactionRules;

  /// Payments — top-level CRUD entity, document-bearing. Two non-CRUD flows
  /// ride dedicated `MutationKind`s: `refundPayment` (`POST /payments/refund`)
  /// and `applyPayment` (`PUT /payments/{id}` with an `invoices` allocations
  /// array). `?email_receipt=…` query flag threads through the outbox via a
  /// synthetic `_send_email` payload key (see `PaymentsApi.create`).
  final PaymentRepository payments;

  /// API webhooks — settings-only entity. Edited under Settings →
  /// Integrations → API Webhooks. Bundled on `/refresh?first_load=true`.
  final WebhookRepository webhooks;

  /// API tokens — settings-only entity. Edited under Settings →
  /// Integrations → API Tokens. Bundled on `/refresh?first_load=true` via
  /// `tokens_hashed` (server returns masked token strings; raw bearer
  /// secret only on create response, see [TokenRepository.newSecrets]).
  final TokenRepository tokens;

  final CompanyRepository company;

  /// HTTP service for `/api/v1/companies` — exposed so screens (today: the
  /// Client Portal Settings tab's subdomain availability probe) can call
  /// endpoints outside the standard outbox flow without re-instantiating
  /// the service.
  final CompaniesApi companies;

  /// QuickBooks integration — Account Management → Integrations →
  /// QuickBooks. State lives on `company.quickbooks`; this repo just owns
  /// the connect / disconnect side-effects (one_time_token + authorize URL,
  /// disconnect endpoint).
  final QuickbooksRepository quickbooks;

  final DashboardRepository dashboard;

  /// Reports — queued-job endpoints (preview / export / email). Used only
  /// by the Reports screen at `/reports`; not part of the entity sync
  /// graph (no Drift table, no outbox row). Each Run POSTs, then polls
  /// the server's `/api/v1/reports/preview/<hash>` (or
  /// `/api/v1/exports/preview/<hash>`) for the materialized result.
  final ReportsRepository reports;

  final StaticsRepository statics;

  /// Self-hosted server diagnostic endpoints (`/health_check`, `/ping`,
  /// `/last_error`) behind the Health Check button in the About dialog.
  /// No persistence — the dialog fetches on open and discards on close.
  final SystemApi system;

  /// Read-only cache of `/api/v1/system_logs` backing Settings → System
  /// Logs. No outbox / mutation surface — the server is the only writer.
  final SystemLogRepository systemLogs;

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

  /// One-off probe behind Settings → Email Settings → "Send Test Email"
  /// (calls `/api/v1/smtp/check`). Bypasses the outbox — see
  /// [SmtpApi] for why.
  final SmtpApi smtp;

  /// Live email-template rendering for Settings → Templates & Reminders.
  /// POSTs to `/api/v1/templates` with the user's draft subject + body,
  /// the server runs variable substitution, and the preview panel renders
  /// the returned HTML.
  final TemplatesApi templates;

  final SyncRepository sync;

  /// Foreground delta-refresh pump (periodic + on-resume). Lifecycle
  /// transitions are routed in by `SyncLifecycleObserver`.
  final RefreshScheduler refreshScheduler;

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

  /// One-slot registry of the currently-mounted token search field's
  /// FocusNode. The global `/` shortcut reads this to focus search on the
  /// active list screen without coupling the shell to any specific list.
  /// Filled by `TokenSearchField.initState`, cleared in `dispose`; `null`
  /// when no list screen is mounted (e.g. Dashboard, Settings).
  final SearchFocusRegistry searchFocus = SearchFocusRegistry();

  /// Debug-only Claude-readable log of uncaught errors + WARNING/SEVERE
  /// Logger records, plus on-demand outbox snapshots. `null` in release
  /// builds and in unit-test wiring; see [DiagnosticsLog] for the format.
  final DiagnosticsLog? diagnosticsLog;

  /// In-memory capture of recent HTTP requests + errors. Off by default and
  /// reset on every app launch — used by the hidden Debug Panel surfaced via
  /// long-press on the System Logs AppBar title. Lives in release builds so
  /// users can self-diagnose in prod.
  final DebugCaptureStore debugCaptureStore;

  /// Whether the hidden Debug Panel band is currently visible at the bottom
  /// of the authenticated app shell. Flipped on by long-press on the System
  /// Logs AppBar title; flipped off by the Hide button in the panel toolbar.
  /// Lives on `Services` (not local screen state) so the panel survives
  /// navigation between routes.
  final ValueNotifier<bool> debugPanelRevealed;

  // -- SidebarBadgeContext -------------------------------------------------

  @override
  Stream<int> watchEntityCount(EntityType type, String companyId) {
    // Built once at construction (in `Services.build`) from the wired
    // entities' typed `watchCount` methods. Sidebar-visible entities are
    // present; settings-only / bundled-only / disabled ones return zero so
    // unwired sidebar rows degrade gracefully (the row just shows no badge).
    final watcher = _countWatchers[type];
    if (watcher == null) return Stream.value(0);
    return watcher(companyId);
  }

  @override
  Stream<int> watchOutboxPending(String companyId) =>
      db.outboxDao.watchPendingCount(companyId: companyId);

  @override
  Stream<int> watchOutboxDead(String companyId) =>
      db.outboxDao.watchDeadCount(companyId: companyId);

  /// Sidebar count streams keyed by entity type. Populated once in
  /// [Services.build] from [WiredEntities.countWatchers] and read by
  /// [watchEntityCount].
  final Map<EntityType, Stream<int> Function(String companyId)>
  _countWatchers;

  /// First-page prefetch callbacks keyed by entity type. Fired in parallel
  /// from [prefetchSidebarEntities] on every active-company change so the
  /// sidebar count badges populate before the user opens each list.
  final Map<EntityType, Future<bool> Function(String companyId)>
  _firstPagePrefetchers;

  /// Pull the first page of every workspace-sidebar entity for [companyId].
  /// Fired fire-and-forget on every login / refresh / company-switch /
  /// restore (via the `onActiveCompanyChanged` chain in [Services.build]).
  /// Each entity is dispatched in parallel; individual failures are caught +
  /// logged so a single 401 / network blip can't take down login. Cursor
  /// short-circuiting keeps subsequent fires cheap — only the first time a
  /// company is seen does this hit the network for every entity.
  Future<void> prefetchSidebarEntities(String companyId) =>
      _runSidebarPrefetch(_firstPagePrefetchers, companyId);

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
    // Mirror the resolved [Formatter] into a sync map so callers in
    // initState / cell-commit paths can read it without awaiting.
    // Cleared alongside the Future cache by [invalidateFormatter].
    future.then(
      (f) => _formatterReady[companyId] = f,
      onError: (_) => _formatterCache.remove(companyId),
    );
    return future;
  }

  final Map<String, Formatter> _formatterReady = {};

  /// Sync accessor for an already-resolved [Formatter]. Returns null if
  /// [formatterFor] hasn't been called yet (or is still in flight).
  /// Used by inline-edit widgets that need locale-aware parsing on
  /// the very first keystroke (e.g. comma-decimal users typing into
  /// the line-item table) without paying for an async fetch each
  /// build.
  Formatter? formatterIfReady(String companyId) => _formatterReady[companyId];

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
    _formatterReady.remove(companyId);
  }

  /// Drop every cached [Formatter]. Called on logout (via [Services.build]'s
  /// teardown path) so a subsequent login can't observe the previous user's
  /// company-currency settings.
  void invalidateAllFormatters() {
    _formatterCache.clear();
    _formatterReady.clear();
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
    DebugCaptureStore? debugCaptureStore,
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
    final debugStore = debugCaptureStore ?? DebugCaptureStore();
    final debugPanelRevealed = ValueNotifier<bool>(false);
    final apiClient = ApiClient(
      credentials: auth.credentials,
      passwordCache: passwordCache,
      onUnauthorized: auth.logout,
      onServerVersion: (v) => serverVersion.value = v,
      onClientTooOld: (info) => clientTooOld.value = info,
      httpClient: httpClient,
      debugCaptureStore: debugStore,
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
    final quickbooksRepo = QuickbooksRepository(
      apiClient: apiClient,
      auth: auth,
    );
    final dashboardApi = DashboardApi(apiClient);
    final dashboardRepo = DashboardRepository(db: db, api: dashboardApi);
    final reportsApi = ReportsApi(apiClient);
    final reportsRepo = ReportsRepository(api: reportsApi);
    final statics = StaticsRepository(
      db: db,
      service: StaticsService(apiClient),
    );
    final systemApi = SystemApi(apiClient);
    final systemLogs = SystemLogRepository(
      db: db,
      api: SystemLogsApi(apiClient),
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
    final smtpApi = SmtpApi(apiClient);
    final templatesApi = TemplatesApi(apiClient);

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
    auth.onPersistBundles =
        ({required companyId, required company, required fullSync}) async {
          for (final apply in entities.bundleAppliers) {
            await apply(
              companyId: companyId,
              company: company,
              fullSync: fullSync,
            );
          }
        };
    // Seed the static catalog from the /refresh envelope's `static` blob
    // instead of a separate GET /api/v1/statics. No-op on the empty map a
    // login response or a delta refresh carries; the 7-day TTL keeps the
    // cold-start network fallback in `statics.ensureLoaded()` intact.
    auth.onApplyStatic = statics.applyStatic;
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
    // Foreground delta-refresh pump. Stop it before logout (no ticks while
    // signed out); (re)start it whenever a company becomes active (login,
    // restore, switch). The periodic timer is also paused/resumed on
    // app background/foreground by `SyncLifecycleObserver`.
    final refreshScheduler = RefreshScheduler(auth: auth);
    final priorOnBeforeLogout = auth.onBeforeLogout;
    auth.onBeforeLogout = () async {
      settingsLevel.reset();
      refreshScheduler.stop();
      if (priorOnBeforeLogout != null) await priorOnBeforeLogout();
    };
    final priorOnActiveCompanyChanged = auth.onActiveCompanyChanged;
    auth.onActiveCompanyChanged = (companyId) {
      settingsLevel.reset();
      refreshScheduler.start();
      priorOnActiveCompanyChanged?.call(companyId);
      // Fire-and-forget: pull the first page of every workspace-sidebar
      // entity so the count badges populate before the user opens each
      // list. Errors are caught + logged per entity so a 401 / network
      // blip can't take down login.
      unawaited(_prefetchSidebarOnCompanyChange(entities, companyId));
    };
    return Services._(
      db: db,
      auth: auth,
      clients: entities.clients,
      products: entities.products,
      tasks: entities.tasks,
      taskStatuses: entities.taskStatuses,
      projects: entities.projects,
      vendors: entities.vendors,
      expenses: entities.expenses,
      recurringExpenses: entities.recurringExpenses,
      expenseCategories: entities.expenseCategories,
      companyGateways: entities.companyGateways,
      paymentTerms: entities.paymentTerms,
      taxRates: entities.taxRates,
      designs: entities.designs,
      groupSettings: entities.groupSettings,
      paymentLinks: entities.paymentLinks,
      schedules: entities.schedules,
      invoices: entities.invoices,
      quotes: entities.quotes,
      credits: entities.credits,
      purchaseOrders: entities.purchaseOrders,
      recurringInvoices: entities.recurringInvoices,
      bankAccounts: entities.bankAccounts,
      bankTransactions: entities.bankTransactions,
      transactionRules: entities.transactionRules,
      payments: entities.payments,
      webhooks: entities.webhooks,
      tokens: entities.tokens,
      company: companyRepo,
      companies: companiesApi,
      quickbooks: quickbooksRepo,
      dashboard: dashboardRepo,
      reports: reportsRepo,
      statics: statics,
      system: systemApi,
      systemLogs: systemLogs,
      settings: settings,
      userSettings: userSettingsRepo,
      user: userRepo,
      savedViews: savedViewsRepo,
      twoFactor: twoFactorRepo,
      support: supportApi,
      smtp: smtpApi,
      templates: templatesApi,
      activities: activitiesApi,
      sync: sync,
      refreshScheduler: refreshScheduler,
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
      debugCaptureStore: debugStore,
      debugPanelRevealed: debugPanelRevealed,
      diagnosticsLog: diagnosticsLog,
      countWatchers: entities.countWatchers,
      firstPagePrefetchers: entities.firstPagePrefetchers,
    );
  }
}
