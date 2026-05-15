import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';

/// Schema migration switchboard.
///
/// Every release that changes a table bumps [AppDatabase.schemaVersion] and
/// adds a case to this switch. The accompanying test
/// (`test/data/db/migration_test.dart`) exercises the matrix from every prior
/// schema to the current one.
Future<void> runMigrations(AppDatabase db, Migrator m, int from, int to) async {
  // Each step is double-gated: `from < N` skips steps the user has already
  // applied, and `to >= N` skips steps beyond the target schema version. In
  // production `to == AppDatabase.schemaVersion`, so the upper bound never
  // trims anything — it only matters for the schema verifier tests that
  // migrate up to an older version (`migrateAndValidate(db, 13)`).
  if (from < 2 && to >= 2) {
    // Add filter/sort columns. Every new column has a default so `addColumn`
    // can populate existing rows in-place; the backfill below then pulls the
    // real values out of the `payload` blob so existing local DBs survive
    // the upgrade without re-syncing from the server.
    await m.addColumn(db.clients, db.clients.createdAt);
    await m.addColumn(db.clients, db.clients.customValue1);
    await m.addColumn(db.clients, db.clients.customValue2);
    await m.addColumn(db.clients, db.clients.customValue3);
    await m.addColumn(db.clients, db.clients.customValue4);
    // COALESCE guards against payloads with missing keys or malformed JSON —
    // json_extract returns NULL in those cases, which would otherwise violate
    // the columns' non-null constraint.
    await db.customStatement(r'''
      UPDATE clients SET
        created_at    = COALESCE(json_extract(payload, '$.created_at'), 0),
        custom_value1 = COALESCE(json_extract(payload, '$.custom_value1'), ''),
        custom_value2 = COALESCE(json_extract(payload, '$.custom_value2'), ''),
        custom_value3 = COALESCE(json_extract(payload, '$.custom_value3'), ''),
        custom_value4 = COALESCE(json_extract(payload, '$.custom_value4'), '')
      ''');
  }
  if (from < 3 && to >= 3) {
    // Per-(user, company) settings cache. Single row per company; populated
    // on login and updated through the outbox.
    await m.createTable(db.userSettings);
  }
  if (from < 4 && to >= 4) {
    // Per-(user, company) admin/owner flags. Previously rebuilt from the
    // login response only; on app restart they were hardcoded to false,
    // silently downgrading permissions until the next login. Backfill is
    // unnecessary because permissions on a stale local row are server-
    // enforced — the worst case is a one-login regression for users who
    // upgrade before re-authenticating.
    await m.addColumn(db.companies, db.companies.isAdmin);
    await m.addColumn(db.companies, db.companies.isOwner);
  }
  if (from < 5 && to >= 5) {
    // Read-only dashboard cache (totals/chart/activities/list cards), keyed
    // by `(company_id, kind, filter_hash)`. The repo writes raw API JSON
    // payloads; the UI watches per-row streams.
    await m.createTable(db.dashboardCache);
  }
  if (from < 6 && to >= 6) {
    // Top-level company fields the Company Details page edits. Live in
    // the `/auth/me` envelope (not in `settings`); we persist them so the
    // settings UI doesn't go blank on app restart. Backfill is empty —
    // values land at next login.
    await m.addColumn(db.companies, db.companies.customFields);
    await m.addColumn(db.companies, db.companies.sizeId);
    await m.addColumn(db.companies, db.companies.industryId);
    await m.addColumn(db.companies, db.companies.legalEntityId);
  }
  if (from < 7 && to >= 7) {
    // Persist the logo URL as its own column so the switcher avatar isn't
    // hostage to the `settings` JSON blob round-tripping cleanly. The
    // backfill below pulls whatever survived from the existing blob so
    // users who already logged in don't have to log in again.
    await m.addColumn(db.companies, db.companies.logoUrl);
    await db.customStatement(r'''
      UPDATE companies
      SET logo_url = json_extract(settings, '$.company_logo')
      WHERE logo_url IS NULL
    ''');
    // Heal display_name for rows where it was left null/empty by an old
    // write path that didn't compute the cascade. Falls through:
    //   existing non-empty display_name → settings.name → top-level name.
    await db.customStatement(r'''
      UPDATE companies
      SET display_name = COALESCE(
        NULLIF(display_name, ''),
        json_extract(settings, '$.name'),
        NULLIF(name, '')
      )
      WHERE display_name IS NULL OR display_name = ''
    ''');
  }
  if (from < 8 && to >= 8) {
    // Persist the user's sidebar collapse choice so the rail renders at the
    // correct width on the first frame after restart. Default `false` keeps
    // existing installs expanded (today's behavior) until they toggle.
    await m.addColumn(db.navState, db.navState.sidebarCollapsed);
  }
  if (from < 9 && to >= 9) {
    // Add the Products table — Invoice Ninja's product catalog. No backfill
    // needed (no prior local data exists); the first list load pulls rows
    // from the server via the standard paged sync.
    await m.createTable(db.products);
  }
  if (from < 10 && to >= 10) {
    // Persist 422 field errors on dead outbox rows so the Outbox screen
    // and the edit form can replay per-field messages after restart. Old
    // dead rows leave the column null — the UI falls back to last_error.
    await m.addColumn(db.outbox, db.outbox.fieldErrorsJson);
  }
  if (from < 11 && to >= 11) {
    // Per-brightness palette choice. Null means "use the default variant
    // for that brightness" — equivalent to today's behavior.
    await m.addColumn(db.navState, db.navState.lightVariant);
    await m.addColumn(db.navState, db.navState.darkVariant);
  }
  if (from < 12 && to >= 12) {
    // JSON-encoded list of attachments returned on the company response.
    // Nullable, no backfill — next `applyUpdateResponse` repopulates.
    await m.addColumn(db.companies, db.companies.documents);
  }
  if (from < 13 && to >= 13) {
    // Local-only saved_views table — named snapshots of a list screen's
    // filter+sort+search state plus the column selection. No backfill
    // (opt-in feature, fresh table).
    await m.createTable(db.savedViews);
  }
  if (from < 14 && to >= 14) {
    // Group settings table — the cascade level between company and client.
    // Wired without a top-level nav entry; surfaced under
    // `/settings/group_settings`. No backfill (fresh table); the first
    // list load pulls rows from `/api/v1/group_settings`.
    await m.createTable(db.groupSettings);
  }
  if (from < 15 && to >= 15) {
    // Auth-user profile table — one row per (company_id, id). Powers the
    // Settings > User Details screen; populated on first load from
    // `GET /users/{id}?include=company_user`. No backfill (fresh table).
    await m.createTable(db.users);
  }
  if (from < 16 && to >= 16) {
    // Per-entity documents arrays. Nullable JSON columns — pure additive
    // ALTERs, no backfill (existing rows read as `const <Document>[]`).
    // The on-disk schema mirrors what Company already does at
    // `companies.documents` (added at v12).
    //
    // The existence guard handles users who hit `from < 9` first: the
    // v9 `createTable(db.products)` step uses Drift's current
    // `$ProductsTable`, which now includes `documents` (added to the
    // shared `EntityDocumentsColumn` mixin), so the column is already
    // there by the time we reach this step. Without the guard the v7→v19
    // path fails with `duplicate column name: documents`.
    if (!await _columnExists(db, 'clients', 'documents')) {
      await m.addColumn(db.clients, db.clients.documents);
    }
    if (!await _columnExists(db, 'products', 'documents')) {
      await m.addColumn(db.products, db.products.documents);
    }
  }
  if (from < 17 && to >= 17) {
    // Tasks + task statuses graduate from disabled placeholder to wired
    // entities. Fresh tables, no backfill (no prior local data exists);
    // the first list load pulls rows from the server via the standard
    // paged sync. `is_running` is denormalized on tasks so the global
    // running-timer pill's `watchRunning()` is an O(1) indexed lookup.
    await m.createTable(db.tasks);
    await m.createTable(db.taskStatuses);
  }
  if (from < 18 && to >= 18) {
    // Projects graduates from disabled placeholder to wired entity. Fresh
    // table, no backfill (no prior local data exists); the first list
    // load pulls rows from the server via the standard paged sync.
    await m.createTable(db.projects);
  }
  if (from < 19 && to >= 19) {
    // Company gateways graduate from missing-entirely to wired entity. Fresh
    // table, no backfill — gateway rows live entirely on the server in the
    // existing local cache and only land on first sync after the upgrade.
    await m.createTable(db.companyGateways);
  }
  if (from < 20 && to >= 20) {
    // Payment terms — small bundled reference list, delivered via the
    // /refresh envelope's `company.payment_terms` array. Fresh table, no
    // backfill (first applyBundle on next login seeds rows).
    await m.createTable(db.paymentTerms);
  }
  if (from < 21 && to >= 21) {
    // Tax Settings port: (a) lift the three count fields + calculate_taxes
    // + tax_data onto the companies table as their own columns so the
    // Settings → Tax Settings UI can edit them without touching the
    // `settings` JSON; (b) add the bundled `tax_rates` reference table
    // (delivered via `/refresh?first_load=true` like payment_terms).
    // Backfill is empty — values land on next login / refresh.
    await m.addColumn(db.companies, db.companies.enabledTaxRates);
    await m.addColumn(db.companies, db.companies.enabledItemTaxRates);
    await m.addColumn(db.companies, db.companies.enabledExpenseTaxRates);
    await m.addColumn(db.companies, db.companies.calculateTaxes);
    await m.addColumn(db.companies, db.companies.taxDataJson);
    await m.createTable(db.taxRates);
  }
  if (from < 22 && to >= 22) {
    // Expense categories — small bundled reference list, delivered via the
    // /refresh envelope's `company.expense_categories` array AND paginated
    // through `/api/v1/expense_categories`. Fresh table, no backfill (first
    // applyBundle on next login seeds rows).
    await m.createTable(db.expenseCategories);
  }
  if (from < 23 && to >= 23) {
    // Vendors — top-level CRUD entity, document-bearing. Same denormalized
    // shape as `clients`: identity / address / balance columns surface for
    // list-screen filter/sort, and the full server payload (contacts and
    // all) lives in the `payload` JSON column. Fresh table, no backfill
    // (rows land on first list-page fetch after upgrade).
    await m.createTable(db.vendors);
  }
  if (from < 24 && to >= 24) {
    // Expenses — top-level CRUD entity, document-bearing. Denormalized
    // columns cover everything the list filters / sorts on (number, date,
    // amount, vendor/client/project/category/invoice ids, paid flag,
    // should_be_invoiced flag); the full server payload lives in `payload`
    // so a new field doesn't force a migration. Fresh table, no backfill
    // (rows land on first list-page fetch after upgrade).
    await m.createTable(db.expenses);
  }
  if (from < 25 && to >= 25) {
    // Product Settings port: lift the 12 top-level product configuration
    // fields onto the companies table as their own columns so the
    // Settings → Product Settings UI can edit them without touching the
    // `settings` JSON. Backfill is empty — values land on next
    // applyUpdateResponse / login.
    await m.addColumn(db.companies, db.companies.trackInventory);
    await m.addColumn(db.companies, db.companies.stockNotification);
    await m.addColumn(db.companies, db.companies.inventoryNotificationThreshold);
    await m.addColumn(db.companies, db.companies.enableProductDiscount);
    await m.addColumn(db.companies, db.companies.enableProductCost);
    await m.addColumn(db.companies, db.companies.enableProductQuantity);
    await m.addColumn(db.companies, db.companies.defaultQuantity);
    await m.addColumn(db.companies, db.companies.showProductDetails);
    await m.addColumn(db.companies, db.companies.fillProducts);
    await m.addColumn(db.companies, db.companies.updateProducts);
    await m.addColumn(db.companies, db.companies.convertProducts);
    await m.addColumn(db.companies, db.companies.convertRateToClient);
  }
  if (from < 26 && to >= 26) {
    // Recurring expenses — top-level CRUD entity, document-bearing.
    // Superset of `expenses`: same denormalized identity / amount /
    // vendor-client-project-category / currency columns plus the
    // recurring schedule columns (`frequency_id`, `remaining_cycles`,
    // `next_send_date`, `last_sent_date`, `status_id`) the list page's
    // status chips filter on. Fresh table, no backfill (rows land on
    // first list-page fetch after upgrade).
    await m.createTable(db.recurringExpenses);
  }
  if (from < 27 && to >= 27) {
    // Workflow Settings port: lift the two top-level workflow toggles onto
    // the companies table as their own columns so Settings → Workflow
    // Settings can edit them without going through the `settings` JSON.
    // Backfill is empty — values land on next applyUpdateResponse / login.
    await m.addColumn(db.companies, db.companies.stopOnUnpaidRecurring);
    await m.addColumn(db.companies, db.companies.useQuoteTermsOnConversion);
  }
  if (from < 28 && to >= 28) {
    // Task + Expense Settings port: lift the 11 top-level task toggles and
    // the 15 top-level expense fields onto the companies table. Task fields
    // were merged ahead of this migration (the screen already saves through
    // the outbox, but the local cache lost them on cold restart). All 26
    // columns carry `withDefault(false / '')` so existing rows backfill in
    // place — real values land on the next applyUpdateResponse / login.
    await m.addColumn(db.companies, db.companies.autoStartTasks);
    await m.addColumn(db.companies, db.companies.showTaskEndDate);
    await m.addColumn(db.companies, db.companies.showTasksTable);
    await m.addColumn(db.companies, db.companies.invoiceTaskDatelog);
    await m.addColumn(db.companies, db.companies.invoiceTaskTimelog);
    await m.addColumn(db.companies, db.companies.invoiceTaskHours);
    await m.addColumn(db.companies, db.companies.invoiceTaskItemDescription);
    await m.addColumn(db.companies, db.companies.invoiceTaskProject);
    await m.addColumn(db.companies, db.companies.invoiceTaskProjectHeader);
    await m.addColumn(db.companies, db.companies.invoiceTaskLock);
    await m.addColumn(db.companies, db.companies.invoiceTaskDocuments);
    await m.addColumn(db.companies, db.companies.markExpensesInvoiceable);
    await m.addColumn(db.companies, db.companies.markExpensesPaid);
    await m.addColumn(db.companies, db.companies.convertExpenseCurrency);
    await m.addColumn(db.companies, db.companies.invoiceExpenseDocuments);
    await m.addColumn(db.companies, db.companies.notifyVendorWhenPaid);
    await m.addColumn(db.companies, db.companies.calculateExpenseTaxByAmount);
    await m.addColumn(db.companies, db.companies.expenseInclusiveTaxes);
    await m.addColumn(db.companies, db.companies.expenseMailboxActive);
    await m.addColumn(db.companies, db.companies.expenseMailbox);
    await m.addColumn(
      db.companies,
      db.companies.inboundMailboxAllowCompanyUsers,
    );
    await m.addColumn(db.companies, db.companies.inboundMailboxAllowVendors);
    await m.addColumn(db.companies, db.companies.inboundMailboxAllowClients);
    await m.addColumn(db.companies, db.companies.inboundMailboxWhitelist);
    await m.addColumn(db.companies, db.companies.inboundMailboxBlacklist);
    await m.addColumn(db.companies, db.companies.inboundMailboxAllowUnknown);
  }
  if (from < 29 && to >= 29) {
    // Account Management port (Phase 1): lift the top-level
    // `enabled_modules` bitmask, the three integration fields
    // (`google_analytics_key`, `matomo_id`, `matomo_url`), and the three
    // security fields (`session_timeout`, `default_password_timeout`,
    // `oauth_password_required`) onto the companies table so the new
    // screens can read from watch streams and persist edits optimistically.
    // Defaults (0 / '' / false) backfill in place — real values land on the
    // next login / refresh, which runs `_persistAndActivate` and writes the
    // server value.
    await m.addColumn(db.companies, db.companies.enabledModules);
    await m.addColumn(db.companies, db.companies.googleAnalyticsKey);
    await m.addColumn(db.companies, db.companies.matomoId);
    await m.addColumn(db.companies, db.companies.matomoUrl);
    await m.addColumn(db.companies, db.companies.sessionTimeout);
    await m.addColumn(db.companies, db.companies.defaultPasswordTimeout);
    await m.addColumn(db.companies, db.companies.oauthPasswordRequired);
    await m.addColumn(db.companies, db.companies.isDisabled);
    await m.addColumn(db.companies, db.companies.markdownEnabled);
    await m.addColumn(db.companies, db.companies.markdownEmailEnabled);
    await m.addColumn(db.companies, db.companies.reportIncludeDrafts);
    await m.addColumn(db.companies, db.companies.reportIncludeDeleted);
  }
  if (from < 30 && to >= 30) {
    // Account Management → Integrations → QuickBooks (Phase 4): persist the
    // nested `quickbooks` envelope (access tokens, realm id, per-entity
    // sync direction map) as a JSON blob so the connection state survives
    // cold restart. Nullable, no backfill — the next `applyUpdateResponse`
    // or `/refresh` writes the real value for connected accounts; legacy
    // installs remain `NULL` until the user explicitly connects.
    await m.addColumn(db.companies, db.companies.quickbooksJson);
  }
  if (from < 31 && to >= 31) {
    // Invoice Design: persist the bundled `data[N].company.designs` array so
    // the design pickers can show every available template offline (built-in
    // + custom). Backfill arrives via the next `/refresh?first_load=true`
    // through `DesignRepository.applyBundle`; legacy installs see an empty
    // table until then, and the picker falls back to the static
    // `kBuiltInDesigns` catalog so the UI never renders empty.
    await m.createTable(db.designs);
  }
  if (from < 32 && to >= 32) {
    // Custom Fields port: persist the four per-surcharge "charge taxes"
    // toggles. Paired with the `customFields['surcharge1..4']` slots edited
    // on Settings → Custom Fields → Invoices. Defaults backfill in place —
    // real values arrive on the next applyUpdateResponse / login.
    await m.addColumn(db.companies, db.companies.customSurchargeTaxes1);
    await m.addColumn(db.companies, db.companies.customSurchargeTaxes2);
    await m.addColumn(db.companies, db.companies.customSurchargeTaxes3);
    await m.addColumn(db.companies, db.companies.customSurchargeTaxes4);
  }
  if (from < 33 && to >= 33) {
    // Client Portal port: persist the top-level company fields the page
    // edits. Empty-string defaults backfill via addColumn; real values land
    // on the next applyUpdateResponse / login. `companyKey` already lives
    // on the wire envelope but had no Drift column — round-tripping it
    // lets the Login URL display render after cold restart without a
    // /companies fetch.
    await m.addColumn(db.companies, db.companies.subdomain);
    await m.addColumn(db.companies, db.companies.portalDomain);
    await m.addColumn(db.companies, db.companies.portalMode);
    await m.addColumn(db.companies, db.companies.companyKey);
    await m.addColumn(db.companies, db.companies.clientRegistrationFields);
  }
  if (from < 34 && to >= 34) {
    // Email Settings port: lift the seven top-level SMTP transport fields
    // onto the companies table so the SMTP provider card can edit them
    // without touching the `settings` JSON. Defaults backfill in place
    // (`smtp_verify_peer` defaults true to match the legacy clients'
    // read-time fallback); real values land on the next applyUpdateResponse
    // / login.
    await m.addColumn(db.companies, db.companies.smtpHost);
    await m.addColumn(db.companies, db.companies.smtpPort);
    await m.addColumn(db.companies, db.companies.smtpEncryption);
    await m.addColumn(db.companies, db.companies.smtpUsername);
    await m.addColumn(db.companies, db.companies.smtpPassword);
    await m.addColumn(db.companies, db.companies.smtpLocalDomain);
    await m.addColumn(db.companies, db.companies.smtpVerifyPeer);
  }
  if (from < 35 && to >= 35) {
    // Payment Links — small bundled reference list, delivered via the
    // `/refresh` envelope's `company.subscriptions` array AND paginated
    // through `/api/v1/subscriptions`. The wire name is `subscription`
    // but the local table + Drift class are `PaymentLinks` to match the
    // user-facing label. Fresh table, no backfill (first applyBundle on
    // next login seeds rows).
    await m.createTable(db.paymentLinks);
  }
  if (from < 36 && to >= 36) {
    // Invoices — top-level CRUD entity, document-bearing. Per-entity paged
    // fetch (NOT bundled — they're user-browsable and high-volume). Line
    // items live as JSON inside the `payload` column; no separate
    // `line_items` table. Denormalized columns surface the fields the
    // list page filters / sorts on (status, client, date, due_date,
    // amount, balance, paid_to_date, partial, partial_due_date, number,
    // po_number, design, assigned user). Fresh table, no backfill (rows
    // land on first list-page fetch after upgrade).
    await m.createTable(db.invoices);
  }
  if (from < 37 && to >= 37) {
    // E-Invoice certificate state — three top-level company columns lifted
    // out of the `settings` JSON so the Settings → E-Invoice certificate
    // card can edit + round-trip them through the outbox. Defaults are
    // false / '', so `addColumn` backfills cleanly; real values land on the
    // next `applyUpdateResponse` (login / refresh / company save).
    await m.addColumn(db.companies, db.companies.hasEInvoiceCertificate);
    await m.addColumn(
      db.companies,
      db.companies.eInvoiceCertificatePassphrase,
    );
    await m.addColumn(
      db.companies,
      db.companies.hasEInvoiceCertificatePassphrase,
    );
  }
  if (from < 38 && to >= 38) {
    // Quotes — top-level CRUD entity, document-bearing. Shape mirrors
    // invoices (line items + invitations nested in `payload`, denormalized
    // identity / amount / date / status columns). Fresh table, no
    // backfill (rows land on first list-page fetch after upgrade).
    await m.createTable(db.quotes);
  }
  if (from < 39 && to >= 39) {
    // Bank Accounts (`bank_integration`), Bank Transactions
    // (`bank_transaction`), and Transaction Rules
    // (`bank_transaction_rule`) — three independent entity stacks per the
    // React `/settings/bank_accounts` + `/transactions` surfaces.
    // Per-entity paged fetch (NOT bundled). Fresh tables, no backfill
    // (rows land on first list-page fetch after upgrade).
    await m.createTable(db.bankAccounts);
    await m.createTable(db.bankTransactions);
    await m.createTable(db.transactionRules);
  }
  if (from < 40 && to >= 40) {
    // Credits — top-level CRUD entity, document-bearing. Same shape as
    // invoices/quotes (line items + invitations nested in `payload`,
    // denormalized identity / amount / date / status / paid_to_date
    // columns). Fresh table, no backfill (rows land on first list-page
    // fetch after upgrade).
    await m.createTable(db.credits);
  }
  if (from < 41 && to >= 41) {
    // Schedules (`task_scheduler`) — bundled settings entity backing
    // Settings → Advanced → Schedules. Like payment_terms / task_statuses,
    // arrives in the `/refresh?first_load=true` envelope under
    // `company.task_schedulers` and is upserted via `applyBundle`. Fresh
    // table, no backfill (rows land on the next login/refresh).
    await m.createTable(db.schedules);
  }
  if (from < 42 && to >= 42) {
    // PurchaseOrders — same shape as quotes/credits (line items +
    // invitations nested in `payload`, denormalized identity / amount /
    // date / status / vendor_id / expense_id columns). Fresh table,
    // no backfill (rows land on first list-page fetch after upgrade).
    await m.createTable(db.purchaseOrders);
  }
  if (from < 43 && to >= 43) {
    // RecurringInvoices — invoice-shaped table with the recurring-specific
    // denormalized columns (`frequency_id`, `next_send_date`,
    // `remaining_cycles`, `auto_bill`). Fresh table, no backfill — rows
    // land on first list-page fetch after upgrade.
    await m.createTable(db.recurringInvoices);
  }
  if (from < 44 && to >= 44) {
    // User Management port: extend the auth-only `users` table for the
    // settings-area management list. Adds the standard entity scaffolding
    // (`temp_id`, `created_at`, `archived_at`, `custom_value1..4`,
    // `is_deleted`) plus four management-specific columns
    // (`permissions`, `is_owner`, `is_admin`, `is_locked`) so the list
    // page can filter / sort / role-badge without touching `payload`.
    //
    // The v15 step's `createTable(db.users)` uses the *current* Drift
    // schema — fresh installs that hit both v15 and v44 already have
    // every column, so each ALTER is `_columnExists`-guarded.
    if (!await _columnExists(db, 'users', 'temp_id')) {
      await m.addColumn(db.users, db.users.tempId);
    }
    if (!await _columnExists(db, 'users', 'created_at')) {
      await m.addColumn(db.users, db.users.createdAt);
    }
    if (!await _columnExists(db, 'users', 'archived_at')) {
      await m.addColumn(db.users, db.users.archivedAt);
    }
    if (!await _columnExists(db, 'users', 'custom_value1')) {
      await m.addColumn(db.users, db.users.customValue1);
    }
    if (!await _columnExists(db, 'users', 'custom_value2')) {
      await m.addColumn(db.users, db.users.customValue2);
    }
    if (!await _columnExists(db, 'users', 'custom_value3')) {
      await m.addColumn(db.users, db.users.customValue3);
    }
    if (!await _columnExists(db, 'users', 'custom_value4')) {
      await m.addColumn(db.users, db.users.customValue4);
    }
    if (!await _columnExists(db, 'users', 'is_deleted')) {
      await m.addColumn(db.users, db.users.isDeleted);
    }
    if (!await _columnExists(db, 'users', 'permissions')) {
      await m.addColumn(db.users, db.users.permissions);
    }
    if (!await _columnExists(db, 'users', 'is_owner')) {
      await m.addColumn(db.users, db.users.isOwner);
    }
    if (!await _columnExists(db, 'users', 'is_admin')) {
      await m.addColumn(db.users, db.users.isAdmin);
    }
    if (!await _columnExists(db, 'users', 'is_locked')) {
      await m.addColumn(db.users, db.users.isLocked);
    }
    // Backfill the new columns from `payload` for existing auth-user rows.
    // COALESCE guards against json_extract returning NULL on malformed
    // payloads or absent keys.
    await db.customStatement(r'''
      UPDATE users SET
        created_at    = COALESCE(json_extract(payload, '$.created_at'), 0),
        archived_at   = NULLIF(COALESCE(json_extract(payload, '$.archived_at'), 0), 0),
        custom_value1 = COALESCE(json_extract(payload, '$.custom_value1'), ''),
        custom_value2 = COALESCE(json_extract(payload, '$.custom_value2'), ''),
        custom_value3 = COALESCE(json_extract(payload, '$.custom_value3'), ''),
        custom_value4 = COALESCE(json_extract(payload, '$.custom_value4'), ''),
        is_deleted    = COALESCE(json_extract(payload, '$.is_deleted'), 0),
        permissions   = COALESCE(json_extract(payload, '$.company_user.permissions'), ''),
        is_owner      = COALESCE(json_extract(payload, '$.company_user.is_owner'), 0),
        is_admin      = COALESCE(json_extract(payload, '$.company_user.is_admin'), 0),
        is_locked     = COALESCE(json_extract(payload, '$.company_user.is_locked'), 0)
      ''');
  }
  if (from < 45 && to >= 45) {
    // Payments — top-level CRUD entity, document-bearing. Per-entity paged
    // fetch (NOT bundled — they're user-browsable and high-volume).
    // Denormalized columns cover everything the list filters / sorts on
    // (number, date, amount/applied/refunded, status, type, client / vendor
    // / project, gateway, currency, transaction_reference); the full server
    // payload lives in `payload`. The three nested arrays (`paymentables`,
    // `invoices`, `credits`) are kept as their own JSON columns so the
    // detail + refund screens don't have to re-parse `payload`. Fresh
    // table, no backfill (rows land on first list-page fetch after upgrade).
    await m.createTable(db.payments);
  }
  if (from < 46 && to >= 46) {
    // System Logs — read-only cache of the server's `/api/v1/system_logs`
    // feed backing Settings → System Logs. No outbox / dirty flag (the
    // server is the only writer). Replace-on-refetch cache; the
    // `fetched_at` column drives the "Last refreshed" hint and the
    // 1-hour staleness check. Fresh table, no backfill (rows land on
    // first screen open after upgrade).
    await m.createTable(db.systemLogs);
  }
}

/// `PRAGMA table_info(<table>)` probe. Used by the v15→v16 step to skip
/// `addColumn(documents)` when the column already exists — which happens
/// when the user upgrades from `from < 9` and the v9 `createTable` uses
/// the current Dart schema (now with `documents` from the shared mixin).
Future<bool> _columnExists(AppDatabase db, String table, String column) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.any((r) => r.data['name'] == column);
}

/// Shared denormalized columns every entity table carries: id, company id,
/// tmp id, timestamps, dirty/deleted flags, and the four optional
/// `custom_value` columns Invoice Ninja exposes per entity. Future entity
/// tables (Invoice, Quote, Payment, …) declare their per-entity columns
/// alongside these, and reuse the same backfill pattern in migrations.
///
/// `customFieldCount` lets tables that don't carry custom fields (e.g. tax
/// rates) opt out — 0 skips them entirely, 4 mirrors what Client uses today.
///
/// This is a Drift-table column factory, not a migration helper — Drift's
/// `addColumn` API is per-column anyway, so the actual ALTER TABLE work
/// stays inline in [runMigrations].
class StandardEntityColumns {
  const StandardEntityColumns._();

  /// Documents the contract Invoice/Quote/Product/etc. tables follow. Concrete
  /// table classes mirror this list of columns by name and type. The
  /// `customFieldCount` parameter records the per-entity custom-field arity
  /// in the class doc rather than at runtime.
  static const List<String> requiredColumnNames = <String>[
    'id',
    'company_id',
    'temp_id',
    'updated_at',
    'created_at',
    'archived_at',
    'is_dirty',
    'is_deleted',
    'payload',
  ];

  static const List<String> customFieldColumnNames = <String>[
    'custom_value1',
    'custom_value2',
    'custom_value3',
    'custom_value4',
  ];
}
