import 'package:admin/app/services_document_handlers.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/bank_account_api_model.dart';
import 'package:admin/data/models/api/bank_transaction_api_model.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/api/expense_api_model.dart';
import 'package:admin/data/models/api/credit_api_model.dart';
import 'package:admin/data/models/api/purchase_order_api_model.dart';
import 'package:admin/data/models/api/expense_category_api_model.dart';
import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/api/quote_api_model.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/models/api/company_gateway_api_model.dart';
import 'package:admin/data/models/api/design_api_model.dart';
import 'package:admin/data/models/api/group_setting_api_model.dart';
import 'package:admin/data/models/api/payment_term_api_model.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/api/project_api_model.dart';
import 'package:admin/data/models/api/recurring_expense_api_model.dart';
import 'package:admin/data/models/api/schedule_api_model.dart';
import 'package:admin/data/models/api/subscription_api_model.dart';
import 'package:admin/data/models/api/task_api_model.dart';
import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/models/api/tax_rate_api_model.dart';
import 'package:admin/data/models/api/transaction_rule_api_model.dart';
import 'package:admin/data/models/api/vendor_api_model.dart';
import 'package:admin/data/repositories/bank_account_repository.dart';
import 'package:admin/data/repositories/bank_transaction_repository.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/company_gateway_repository.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/data/repositories/expense_category_repository.dart';
import 'package:admin/data/repositories/expense_repository.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/data/repositories/credit_repository.dart';
import 'package:admin/data/repositories/purchase_order_repository.dart';
import 'package:admin/data/repositories/quote_repository.dart';
import 'package:admin/data/repositories/payment_term_repository.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/data/repositories/project_repository.dart';
import 'package:admin/data/repositories/payment_link_repository.dart';
import 'package:admin/data/repositories/recurring_expense_repository.dart';
import 'package:admin/data/repositories/schedule_repository.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/data/repositories/task_status_repository.dart';
import 'package:admin/data/repositories/tax_rate_repository.dart';
import 'package:admin/data/repositories/transaction_rule_repository.dart';
import 'package:admin/data/repositories/vendor_repository.dart';
import 'package:admin/data/services/activities_api.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/bank_accounts_api.dart';
import 'package:admin/data/services/bank_transactions_api.dart';
import 'package:admin/data/services/base_entity_api.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/company_gateways_api.dart';
import 'package:admin/data/services/designs_api.dart';
import 'package:admin/data/services/documents_api.dart';
import 'package:admin/data/services/expense_categories_api.dart';
import 'package:admin/data/services/expenses_api.dart';
import 'package:admin/data/services/group_settings_api.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/data/services/credits_api.dart';
import 'package:admin/data/services/purchase_orders_api.dart';
import 'package:admin/data/services/quotes_api.dart';
import 'package:admin/data/services/payment_terms_api.dart';
import 'package:admin/data/services/products_api.dart';
import 'package:admin/data/services/projects_api.dart';
import 'package:admin/data/services/recurring_expenses_api.dart';
import 'package:admin/data/services/schedules_api.dart';
import 'package:admin/data/services/subscriptions_api.dart';
import 'package:admin/data/services/task_statuses_api.dart';
import 'package:admin/data/services/tasks_api.dart';
import 'package:admin/data/services/tax_rates_api.dart';
import 'package:admin/data/services/transaction_rules_api.dart';
import 'package:admin/data/services/vendors_api.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';

/// Shared services a per-entity wiring block reads from.
class EntityWiringContext {
  EntityWiringContext({
    required this.apiClient,
    required this.db,
    required this.activitiesApi,
    required this.documentsApi,
    required this.kickDrain,
    required this.dispatchers,
  });

  final ApiClient apiClient;
  final AppDatabase db;
  final ActivitiesApi activitiesApi;
  final DocumentsApi documentsApi;
  final void Function(String companyId) kickDrain;
  final Map<EntityType, SyncDispatcher> dispatchers;
}

/// Closure that mirrors a single bundled-entity upsert. Called once per
/// `/refresh` envelope from `auth.onPersistBundles`.
typedef BundleApplier =
    Future<void> Function({
      required String companyId,
      required CompanyEnvelopeApi company,
    });

/// The full set of per-entity APIs + repositories built by [wireEntities],
/// returned typed so [Services.build] can unpack them into its named
/// constructor params without going through a runtime cast bag.
class WiredEntities {
  WiredEntities({
    required this.clientsApi,
    required this.clients,
    required this.productsApi,
    required this.products,
    required this.tasksApi,
    required this.tasks,
    required this.projectsApi,
    required this.projects,
    required this.vendorsApi,
    required this.vendors,
    required this.expensesApi,
    required this.expenses,
    required this.recurringExpensesApi,
    required this.recurringExpenses,
    required this.expenseCategoriesApi,
    required this.expenseCategories,
    required this.companyGatewaysApi,
    required this.companyGateways,
    required this.paymentTermsApi,
    required this.paymentTerms,
    required this.taxRatesApi,
    required this.taxRates,
    required this.taskStatusesApi,
    required this.taskStatuses,
    required this.designsApi,
    required this.designs,
    required this.groupSettingsApi,
    required this.groupSettings,
    required this.subscriptionsApi,
    required this.paymentLinks,
    required this.schedulesApi,
    required this.schedules,
    required this.invoicesApi,
    required this.invoices,
    required this.quotesApi,
    required this.quotes,
    required this.creditsApi,
    required this.credits,
    required this.purchaseOrdersApi,
    required this.purchaseOrders,
    required this.bankAccountsApi,
    required this.bankAccounts,
    required this.bankTransactionsApi,
    required this.bankTransactions,
    required this.transactionRulesApi,
    required this.transactionRules,
    required this.bundleAppliers,
  });

  final ClientsApi clientsApi;
  final ClientRepository clients;
  final ProductsApi productsApi;
  final ProductRepository products;
  final TasksApi tasksApi;
  final TaskRepository tasks;
  final ProjectsApi projectsApi;
  final ProjectRepository projects;
  final VendorsApi vendorsApi;
  final VendorRepository vendors;
  final ExpensesApi expensesApi;
  final ExpenseRepository expenses;
  final RecurringExpensesApi recurringExpensesApi;
  final RecurringExpenseRepository recurringExpenses;
  final ExpenseCategoriesApi expenseCategoriesApi;
  final ExpenseCategoryRepository expenseCategories;
  final CompanyGatewaysApi companyGatewaysApi;
  final CompanyGatewayRepository companyGateways;
  final PaymentTermsApi paymentTermsApi;
  final PaymentTermRepository paymentTerms;
  final TaxRatesApi taxRatesApi;
  final TaxRateRepository taxRates;
  final TaskStatusesApi taskStatusesApi;
  final TaskStatusRepository taskStatuses;
  final DesignsApi designsApi;
  final DesignRepository designs;
  final GroupSettingsApi groupSettingsApi;
  final GroupSettingRepository groupSettings;
  final SubscriptionsApi subscriptionsApi;
  final PaymentLinkRepository paymentLinks;
  final SchedulesApi schedulesApi;
  final ScheduleRepository schedules;
  final InvoicesApi invoicesApi;
  final InvoiceRepository invoices;
  final QuotesApi quotesApi;
  final QuoteRepository quotes;
  final CreditsApi creditsApi;
  final CreditRepository credits;
  final PurchaseOrdersApi purchaseOrdersApi;
  final PurchaseOrderRepository purchaseOrders;
  final BankAccountsApi bankAccountsApi;
  final BankAccountRepository bankAccounts;
  final BankTransactionsApi bankTransactionsApi;
  final BankTransactionRepository bankTransactions;
  final TransactionRulesApi transactionRulesApi;
  final TransactionRuleRepository transactionRules;

  /// Bundled-entity upsert callbacks. Iterate in `auth.onPersistBundles` —
  /// the order matches the order of construction here so a single `for` loop
  /// reproduces what the prior hand-written chain did.
  final List<BundleApplier> bundleAppliers;
}

/// Builds every CRUD-list entity wired into the sync engine. Lifts the
/// previous ~260 LOC of per-entity api+repo+wireEntity blocks out of
/// `Services.build` so adding the next document-bearing entity
/// (expense / vendor / invoice) only touches this file (one block) plus
/// `kWiredEntityModules` (one spec) — not `services.dart` directly.
///
/// `customActions` factories live next to each entity below; sharable trios
/// (documents) flow through [documentMutationHandlers].
WiredEntities wireEntities(EntityWiringContext ctx) {
  // Local closure that mirrors the original `wireEntity<TItem, TInner>(...)`
  // in services.dart — generic functions can't be passed as values, so we
  // re-declare the helper here with access to `ctx.dispatchers`.
  void wire<TItem, TInner>({
    required EntityType type,
    required BaseEntityApi<dynamic, TItem> api,
    required BaseEntityRepository<dynamic, TInner> repo,
    Map<MutationKind, CustomMutationHandler<TInner>>? customActions,
  }) {
    ctx.dispatchers[type] = BaseEntitySyncDispatcher<TItem, TInner>(
      api: api,
      repo: repo,
      dataOf: (i) => (i as dynamic).data as TInner,
      customActions: customActions,
    );
  }

  // ---- Client --------------------------------------------------------------
  final clientsApi = ClientsApi(ctx.apiClient);
  final clientRepo = ClientRepository(
    db: ctx.db,
    api: clientsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<ClientItemApi, ClientApi>(
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
        await ctx.activitiesApi.addNote(
          entity: 'clients',
          entityId: payload['entity_id'] as String,
          notes: payload['notes'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      ...documentMutationHandlers<ClientApi>(
        documentsApi: ctx.documentsApi,
        upload: clientsApi.uploadDocument,
        applyChanged: clientRepo.applyDocumentChanged,
        applyDeleted: clientRepo.applyDocumentDeleted,
      ),
    },
  );

  // ---- Product -------------------------------------------------------------
  final productsApi = ProductsApi(ctx.apiClient);
  final productRepo = ProductRepository(
    db: ctx.db,
    api: productsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<ProductItemApi, ProductApi>(
    type: EntityType.product,
    api: productsApi,
    repo: productRepo,
    customActions: documentMutationHandlers<ProductApi>(
      documentsApi: ctx.documentsApi,
      upload: productsApi.uploadDocument,
      applyChanged: productRepo.applyDocumentChanged,
      applyDeleted: productRepo.applyDocumentDeleted,
    ),
  );

  // ---- Task ----------------------------------------------------------------
  final tasksApi = TasksApi(ctx.apiClient);
  final taskRepo = TaskRepository(
    db: ctx.db,
    api: tasksApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<TaskItemApi, TaskApi>(
    type: EntityType.task,
    api: tasksApi,
    repo: taskRepo,
    customActions: {
      // Kanban drag-drop + task-statuses reorder both ride this handler.
      // Payload carries `{status_ids, task_ids}` (tasks) or just
      // `{status_ids}` (statuses, routed via the task_statuses block below).
      MutationKind.reorder: ({required row, required payload}) async {
        await tasksApi.sort(
          payload: payload,
          idempotencyKey: row.idempotencyKey,
        );
        // Server returned 200. Clear the optimistic `is_dirty` flag on every
        // task in the batch so a subsequent inbound delta can refresh them
        // without being blocked by the in-memory pending flag. The local
        // rows already carry the new ordering — no `applyUpdateResponse`
        // needed (the dispatcher skips it when we return null).
        final taskIdsByStatus =
            (payload['task_ids'] as Map<String, dynamic>?) ?? const {};
        final touched = <String>{
          for (final list in taskIdsByStatus.values)
            ...(list as List).cast<String>(),
        };
        if (touched.isNotEmpty) {
          await taskRepo.clearDirtyForReorder(
            companyId: row.companyId,
            taskIds: touched,
          );
        }
        return null;
      },
    },
  );

  // ---- Project -------------------------------------------------------------
  final projectsApi = ProjectsApi(ctx.apiClient);
  final projectRepo = ProjectRepository(
    db: ctx.db,
    api: projectsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<ProjectItemApi, ProjectApi>(
    type: EntityType.project,
    api: projectsApi,
    repo: projectRepo,
    customActions: documentMutationHandlers<ProjectApi>(
      documentsApi: ctx.documentsApi,
      upload: projectsApi.uploadDocument,
      applyChanged: projectRepo.applyDocumentChanged,
      applyDeleted: projectRepo.applyDocumentDeleted,
    ),
  );

  // ---- Vendor --------------------------------------------------------------
  final vendorsApi = VendorsApi(ctx.apiClient);
  final vendorRepo = VendorRepository(
    db: ctx.db,
    api: vendorsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<VendorItemApi, VendorApi>(
    type: EntityType.vendor,
    api: vendorsApi,
    repo: vendorRepo,
    customActions: {
      MutationKind.addComment: ({required row, required payload}) async {
        await ctx.activitiesApi.addNote(
          entity: 'vendors',
          entityId: payload['entity_id'] as String,
          notes: payload['notes'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      ...documentMutationHandlers<VendorApi>(
        documentsApi: ctx.documentsApi,
        upload: vendorsApi.uploadDocument,
        applyChanged: vendorRepo.applyDocumentChanged,
        applyDeleted: vendorRepo.applyDocumentDeleted,
      ),
    },
  );

  // ---- Expense -------------------------------------------------------------
  final expensesApi = ExpensesApi(ctx.apiClient);
  final expenseRepo = ExpenseRepository(
    db: ctx.db,
    api: expensesApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<ExpenseItemApi, ExpenseApi>(
    type: EntityType.expense,
    api: expensesApi,
    repo: expenseRepo,
    customActions: {
      MutationKind.addComment: ({required row, required payload}) async {
        await ctx.activitiesApi.addNote(
          entity: 'expenses',
          entityId: payload['entity_id'] as String,
          notes: payload['notes'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      ...documentMutationHandlers<ExpenseApi>(
        documentsApi: ctx.documentsApi,
        upload: expensesApi.uploadDocument,
        applyChanged: expenseRepo.applyDocumentChanged,
        applyDeleted: expenseRepo.applyDocumentDeleted,
      ),
    },
  );

  // ---- RecurringExpense ----------------------------------------------------
  // `start` / `stop` route through dedicated `PUT /recurring_expenses/{id}?
  // start=true` / `&stop=true` endpoints. Repository enqueues these as
  // [MutationKind.start] / [MutationKind.stop]; the customActions handlers
  // below call the dedicated API methods. Reused verbatim when
  // `recurring_invoice` lands (three entities × two enum values = same total
  // cardinality as one-value-with-payload, and keeps `customActions`
  // type-safe + the Outbox screen readable).
  final recurringExpensesApi = RecurringExpensesApi(ctx.apiClient);
  final recurringExpenseRepo = RecurringExpenseRepository(
    db: ctx.db,
    api: recurringExpensesApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<RecurringExpenseItemApi, RecurringExpenseApi>(
    type: EntityType.recurringExpense,
    api: recurringExpensesApi,
    repo: recurringExpenseRepo,
    customActions: {
      MutationKind.start: ({required row, required payload}) async {
        final response = await recurringExpensesApi.start(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response.data;
      },
      MutationKind.stop: ({required row, required payload}) async {
        final response = await recurringExpensesApi.stop(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response.data;
      },
      MutationKind.addComment: ({required row, required payload}) async {
        await ctx.activitiesApi.addNote(
          entity: 'recurring_expenses',
          entityId: payload['entity_id'] as String,
          notes: payload['notes'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      ...documentMutationHandlers<RecurringExpenseApi>(
        documentsApi: ctx.documentsApi,
        upload: recurringExpensesApi.uploadDocument,
        applyChanged: recurringExpenseRepo.applyDocumentChanged,
        applyDeleted: recurringExpenseRepo.applyDocumentDeleted,
      ),
    },
  );

  // ---- ExpenseCategory -----------------------------------------------------
  // Settings-only entity reached via Settings → Advanced → Expense
  // Categories. Bundled via `/refresh?first_load=true` (same pattern as
  // task_statuses / payment_terms): the bundleApplier closure at the bottom
  // upserts on every refresh; CRUD also flows through the paginated path
  // for offline edits.
  final expenseCategoriesApi = ExpenseCategoriesApi(ctx.apiClient);
  final expenseCategoryRepo = ExpenseCategoryRepository(
    db: ctx.db,
    api: expenseCategoriesApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<ExpenseCategoryItemApi, ExpenseCategoryApi>(
    type: EntityType.expenseCategory,
    api: expenseCategoriesApi,
    repo: expenseCategoryRepo,
  );

  // ---- CompanyGateway ------------------------------------------------------
  final companyGatewaysApi = CompanyGatewaysApi(ctx.apiClient);
  final companyGatewayRepo = CompanyGatewayRepository(
    db: ctx.db,
    api: companyGatewaysApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<CompanyGatewayItemApi, CompanyGatewayApi>(
    type: EntityType.companyGateway,
    api: companyGatewaysApi,
    repo: companyGatewayRepo,
  );

  // ---- PaymentTerm ---------------------------------------------------------
  final paymentTermsApi = PaymentTermsApi(ctx.apiClient);
  final paymentTermRepo = PaymentTermRepository(
    db: ctx.db,
    api: paymentTermsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<PaymentTermItemApi, PaymentTermApi>(
    type: EntityType.paymentTerm,
    api: paymentTermsApi,
    repo: paymentTermRepo,
  );

  // ---- Schedule ------------------------------------------------------------
  // Bundled settings entity. Server includes `company.task_schedulers` in
  // the `/refresh?first_load=true` envelope; `applyBundle` upserts into
  // the local table. Per-entity paged fetch is still wired so the list
  // can pull a fresh snapshot if the bundle was stale.
  final schedulesApi = SchedulesApi(ctx.apiClient);
  final scheduleRepo = ScheduleRepository(
    db: ctx.db,
    api: schedulesApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<ScheduleItemApi, ScheduleApi>(
    type: EntityType.schedule,
    api: schedulesApi,
    repo: scheduleRepo,
  );

  // ---- TaxRate -------------------------------------------------------------
  // Bundled-only repo today (no CRUD screen) — the Settings → Tax Settings
  // pickers read from Drift via `watchAll`. Wiring `wire<...>(...)` here is
  // fine: `kDisabledEntityModules` carries the matching spec so the entity
  // registry consistency test stays green. When the Tax Rates CRUD page
  // lands, move the spec from `kDisabledEntityModules` to `kWiredEntityModules`
  // and the existing dispatcher / api / repo all keep working.
  //
  // Trade-off: this entity gets a real (functional) sync dispatcher even
  // though it's listed as disabled. There is no UI path today that enqueues
  // a TaxRate mutation, so the live dispatcher is dormant. If a future bug
  // does enqueue one, the outbox will fire real HTTP — preferable to a
  // silent no-op (we'd hear about it via the outbox screen) and matches
  // the contract the CRUD screen will eventually rely on.
  final taxRatesApi = TaxRatesApi(ctx.apiClient);
  final taxRateRepo = TaxRateRepository(
    db: ctx.db,
    api: taxRatesApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<TaxRateItemApi, TaxRateApi>(
    type: EntityType.taxRate,
    api: taxRatesApi,
    repo: taxRateRepo,
  );

  // ---- TaskStatus ----------------------------------------------------------
  final taskStatusesApi = TaskStatusesApi(ctx.apiClient);
  final taskStatusRepo = TaskStatusRepository(
    db: ctx.db,
    api: taskStatusesApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<TaskStatusItemApi, TaskStatusApi>(
    type: EntityType.taskStatus,
    api: taskStatusesApi,
    repo: taskStatusRepo,
    customActions: {
      MutationKind.reorder: ({required row, required payload}) async {
        await taskStatusesApi.sort(
          payload: payload,
          idempotencyKey: row.idempotencyKey,
        );
        final ids =
            (payload['status_ids'] as List?)?.cast<String>() ?? const [];
        if (ids.isNotEmpty) {
          await taskStatusRepo.clearDirtyForReorder(
            companyId: row.companyId,
            statusIds: ids,
          );
        }
        return null;
      },
    },
  );

  // ---- Design --------------------------------------------------------------
  // Bundled via `/refresh?first_load=true` (data[N].company.designs) — the
  // Invoice Design pickers consume the resulting `designs` Drift table.
  // Modeled as a wired entity so the outbox dispatcher handles future
  // create/update/delete from the Custom Designs CRUD screens. No reorder
  // (server has no sort endpoint for designs).
  final designsApi = DesignsApi(ctx.apiClient);
  final designRepo = DesignRepository(
    db: ctx.db,
    api: designsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<DesignItemApi, DesignApi>(
    type: EntityType.design,
    api: designsApi,
    repo: designRepo,
  );

  // ---- GroupSetting --------------------------------------------------------
  final groupSettingsApi = GroupSettingsApi(ctx.apiClient);
  final groupSettingRepo = GroupSettingRepository(
    db: ctx.db,
    api: groupSettingsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<GroupSettingItemApi, GroupSettingApi>(
    type: EntityType.group,
    api: groupSettingsApi,
    repo: groupSettingRepo,
  );

  // ---- PaymentLink (wire: `subscription`) ---------------------------------
  // Settings-only entity reached via Settings → Advanced → Payment Links.
  // Bundled via `/refresh?first_load=true` (same pattern as
  // expense_categories): the bundleApplier closure at the bottom upserts on
  // every refresh; CRUD also flows through the paginated path for offline
  // edits.
  final subscriptionsApi = SubscriptionsApi(ctx.apiClient);
  final paymentLinkRepo = PaymentLinkRepository(
    db: ctx.db,
    api: subscriptionsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<SubscriptionItemApi, SubscriptionApi>(
    type: EntityType.paymentLink,
    api: subscriptionsApi,
    repo: paymentLinkRepo,
  );

  // ---- Invoice ------------------------------------------------------------
  // Document-bearing, with eleven non-CRUD custom actions (mark_sent /
  // mark_paid / email / schedule_email / clone_to_{invoice,quote,credit,
  // recurring,purchase_order} / auto_bill / cancel / run_template). The
  // shape will be reused verbatim by Quote / Credit / PurchaseOrder /
  // RecurringInvoice — the customActions map varies only in *which* kinds
  // it registers.
  final invoicesApi = InvoicesApi(ctx.apiClient);
  final invoiceRepo = InvoiceRepository(
    db: ctx.db,
    api: invoicesApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<InvoiceItemApi, InvoiceApi>(
    type: EntityType.invoice,
    api: invoicesApi,
    repo: invoiceRepo,
    customActions: {
      MutationKind.markSent: ({required row, required payload}) async {
        final response = await invoicesApi.markSent(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.markPaid: ({required row, required payload}) async {
        final response = await invoicesApi.markPaid(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.emailEntity: ({required row, required payload}) async {
        final response = await invoicesApi.email(
          id: payload['id'] as String,
          template: payload['template'] as String,
          subject: payload['subject'] as String?,
          body: payload['body'] as String?,
          ccEmail: payload['cc_email'] as String?,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.scheduleEmail: ({required row, required payload}) async {
        final response = await invoicesApi.scheduleEmail(
          id: payload['id'] as String,
          template: payload['template'] as String,
          sendAt: payload['send_at'] as String,
          subject: payload['subject'] as String?,
          body: payload['body'] as String?,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.cloneToInvoice: ({required row, required payload}) async {
        // Server returns the *new* entity envelope, but we don't apply it
        // back onto the source row — return null so the dispatcher skips
        // applyUpdateResponse. The new entity will land via a sync refresh
        // (or the UI navigates to its edit screen which will fetch it).
        await invoicesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'invoice',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToQuote: ({required row, required payload}) async {
        await invoicesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'quote',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToCredit: ({required row, required payload}) async {
        await invoicesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'credit',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToRecurring: ({required row, required payload}) async {
        await invoicesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'recurring_invoice',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToPurchaseOrder: ({required row, required payload}) async {
        await invoicesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'purchase_order',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.autoBill: ({required row, required payload}) async {
        final response = await invoicesApi.autoBill(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.cancelEntity: ({required row, required payload}) async {
        final response = await invoicesApi.cancel(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.runTemplate: ({required row, required payload}) async {
        final response = await invoicesApi.runTemplate(
          id: payload['id'] as String,
          templateId: payload['template_id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.addComment: ({required row, required payload}) async {
        await ctx.activitiesApi.addNote(
          entity: 'invoices',
          entityId: payload['entity_id'] as String,
          notes: payload['notes'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      ...documentMutationHandlers<InvoiceApi>(
        documentsApi: ctx.documentsApi,
        upload: invoicesApi.uploadDocument,
        applyChanged: invoiceRepo.applyDocumentChanged,
        applyDeleted: invoiceRepo.applyDocumentDeleted,
      ),
    },
  );

  // ---- Quote -------------------------------------------------------------
  // Mirrors Invoice but with quote-specific custom actions (approve,
  // convertToInvoice, convertToProject) instead of mark_paid / auto_bill.
  // All shared kinds (mark_sent, email, schedule_email, clone_to_*,
  // cancel, run_template, addComment, document trio) reuse the exact
  // same handler shape.
  final quotesApi = QuotesApi(ctx.apiClient);
  final quoteRepo = QuoteRepository(
    db: ctx.db,
    api: quotesApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<QuoteItemApi, QuoteApi>(
    type: EntityType.quote,
    api: quotesApi,
    repo: quoteRepo,
    customActions: {
      MutationKind.markSent: ({required row, required payload}) async {
        final response = await quotesApi.markSent(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.approve: ({required row, required payload}) async {
        final response = await quotesApi.approve(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.convertToInvoice: ({required row, required payload}) async {
        // Server returns the *new* invoice envelope, not an update to the
        // source quote. Returning null skips applyUpdateResponse — the
        // new invoice lands via a refresh / explicit navigation.
        await quotesApi.convertToInvoice(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.convertToProject: ({required row, required payload}) async {
        await quotesApi.convertToProject(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.emailEntity: ({required row, required payload}) async {
        final response = await quotesApi.email(
          id: payload['id'] as String,
          template: payload['template'] as String,
          subject: payload['subject'] as String?,
          body: payload['body'] as String?,
          ccEmail: payload['cc_email'] as String?,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.scheduleEmail: ({required row, required payload}) async {
        final response = await quotesApi.scheduleEmail(
          id: payload['id'] as String,
          template: payload['template'] as String,
          sendAt: payload['send_at'] as String,
          subject: payload['subject'] as String?,
          body: payload['body'] as String?,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.cloneToInvoice: ({required row, required payload}) async {
        await quotesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'invoice',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToQuote: ({required row, required payload}) async {
        await quotesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'quote',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToCredit: ({required row, required payload}) async {
        await quotesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'credit',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToRecurring: ({required row, required payload}) async {
        await quotesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'recurring_invoice',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToPurchaseOrder: ({required row, required payload}) async {
        await quotesApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'purchase_order',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cancelEntity: ({required row, required payload}) async {
        final response = await quotesApi.cancel(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.runTemplate: ({required row, required payload}) async {
        final response = await quotesApi.runTemplate(
          id: payload['id'] as String,
          templateId: payload['template_id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.addComment: ({required row, required payload}) async {
        await ctx.activitiesApi.addNote(
          entity: 'quotes',
          entityId: payload['entity_id'] as String,
          notes: payload['notes'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      ...documentMutationHandlers<QuoteApi>(
        documentsApi: ctx.documentsApi,
        upload: quotesApi.uploadDocument,
        applyChanged: quoteRepo.applyDocumentChanged,
        applyDeleted: quoteRepo.applyDocumentDeleted,
      ),
    },
  );

  // ---- BankAccount ---------------------------------------------------------
  // Settings-only entity reached via Settings → Bank Accounts. The
  // `refresh_accounts` custom action asks the upstream provider
  // (Yodlee/Nordigen) to refresh balances + the connected account list.
  final bankAccountsApi = BankAccountsApi(ctx.apiClient);
  final bankAccountRepo = BankAccountRepository(
    db: ctx.db,
    api: bankAccountsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<BankAccountItemApi, BankAccountApi>(
    type: EntityType.bankAccount,
    api: bankAccountsApi,
    repo: bankAccountRepo,
    customActions: {
      MutationKind.refreshAccounts: ({required row, required payload}) async {
        await bankAccountsApi.refreshAccounts(
          idempotencyKey: row.idempotencyKey,
        );
        // Server returns the full list envelope; we discard it here
        // because the bank-accounts list screen is already watching Drift
        // — the next ensurePageLoaded picks up the fresh balances.
        return null;
      },
    },
  );

  // ---- BankTransaction -----------------------------------------------------
  // Top-level workspace entity at `/transactions`. Four `match` variants +
  // two bulk actions (`convert_matched`, `unlink`) all route through this
  // dispatcher's customActions map.
  final bankTransactionsApi = BankTransactionsApi(ctx.apiClient);
  final bankTransactionRepo = BankTransactionRepository(
    db: ctx.db,
    api: bankTransactionsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<BankTransactionItemApi, BankTransactionApi>(
    type: EntityType.transaction,
    api: bankTransactionsApi,
    repo: bankTransactionRepo,
    customActions: {
      MutationKind.matchToPayment: ({required row, required payload}) async {
        final response = await bankTransactionsApi.match(
          transactions:
              (payload['transactions'] as List).cast<Map<String, dynamic>>(),
          idempotencyKey: row.idempotencyKey,
        );
        return response.data.isEmpty ? null : response.data.first;
      },
      MutationKind.linkToPayment: ({required row, required payload}) async {
        final response = await bankTransactionsApi.match(
          transactions:
              (payload['transactions'] as List).cast<Map<String, dynamic>>(),
          idempotencyKey: row.idempotencyKey,
        );
        return response.data.isEmpty ? null : response.data.first;
      },
      MutationKind.matchToExpense: ({required row, required payload}) async {
        final response = await bankTransactionsApi.match(
          transactions:
              (payload['transactions'] as List).cast<Map<String, dynamic>>(),
          idempotencyKey: row.idempotencyKey,
        );
        return response.data.isEmpty ? null : response.data.first;
      },
      MutationKind.linkToExpense: ({required row, required payload}) async {
        final response = await bankTransactionsApi.match(
          transactions:
              (payload['transactions'] as List).cast<Map<String, dynamic>>(),
          idempotencyKey: row.idempotencyKey,
        );
        return response.data.isEmpty ? null : response.data.first;
      },
      MutationKind.convertMatched: ({required row, required payload}) async {
        await bankTransactionsApi.bulkAction(
          action: 'convert_matched',
          ids: (payload['ids'] as List).cast<String>(),
          idempotencyKey: row.idempotencyKey,
        );
        // Bulk response carries the updated rows but the list screen
        // already watches Drift; the next list refresh re-syncs.
        return null;
      },
      MutationKind.unlinkTransaction:
          ({required row, required payload}) async {
        await bankTransactionsApi.bulkAction(
          action: 'unlink',
          ids: (payload['ids'] as List).cast<String>(),
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
    },
  );

  // ---- TransactionRule -----------------------------------------------------
  // Settings-only entity reached via Settings → Bank Accounts → Rules.
  final transactionRulesApi = TransactionRulesApi(ctx.apiClient);
  final transactionRuleRepo = TransactionRuleRepository(
    db: ctx.db,
    api: transactionRulesApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<TransactionRuleItemApi, TransactionRuleApi>(
    type: EntityType.transactionRule,
    api: transactionRulesApi,
    repo: transactionRuleRepo,
  );

  // ---- Credit ------------------------------------------------------------
  // Mirrors Quote shape without the convert-to-X actions. Reuses every
  // shared MutationKind (mark_sent, email, schedule_email, clone_to_*,
  // run_template, addComment, document trio). Credits have a 4-step
  // status (Draft / Sent / Partial / Applied).
  final creditsApi = CreditsApi(ctx.apiClient);
  final creditRepo = CreditRepository(
    db: ctx.db,
    api: creditsApi,
    onEnqueued: ctx.kickDrain,
  );
  wire<CreditItemApi, CreditApi>(
    type: EntityType.credit,
    api: creditsApi,
    repo: creditRepo,
    customActions: {
      MutationKind.markSent: ({required row, required payload}) async {
        final response = await creditsApi.markSent(
          id: payload['id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.emailEntity: ({required row, required payload}) async {
        final response = await creditsApi.email(
          id: payload['id'] as String,
          template: payload['template'] as String,
          subject: payload['subject'] as String?,
          body: payload['body'] as String?,
          ccEmail: payload['cc_email'] as String?,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.scheduleEmail: ({required row, required payload}) async {
        final response = await creditsApi.scheduleEmail(
          id: payload['id'] as String,
          template: payload['template'] as String,
          sendAt: payload['send_at'] as String,
          subject: payload['subject'] as String?,
          body: payload['body'] as String?,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.cloneToInvoice: ({required row, required payload}) async {
        await creditsApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'invoice',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToQuote: ({required row, required payload}) async {
        await creditsApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'quote',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToCredit: ({required row, required payload}) async {
        await creditsApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'credit',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToRecurring: ({required row, required payload}) async {
        await creditsApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'recurring_invoice',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.cloneToPurchaseOrder: ({required row, required payload}) async {
        await creditsApi.cloneTo(
          id: payload['id'] as String,
          targetType: 'purchase_order',
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      MutationKind.runTemplate: ({required row, required payload}) async {
        final response = await creditsApi.runTemplate(
          id: payload['id'] as String,
          templateId: payload['template_id'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return response?.data;
      },
      MutationKind.addComment: ({required row, required payload}) async {
        await ctx.activitiesApi.addNote(
          entity: 'credits',
          entityId: payload['entity_id'] as String,
          notes: payload['notes'] as String,
          idempotencyKey: row.idempotencyKey,
        );
        return null;
      },
      ...documentMutationHandlers<CreditApi>(
        documentsApi: ctx.documentsApi,
        upload: creditsApi.uploadDocument,
        applyChanged: creditRepo.applyDocumentChanged,
        applyDeleted: creditRepo.applyDocumentDeleted,
      ),
    },
  );

  return WiredEntities(
    clientsApi: clientsApi,
    clients: clientRepo,
    productsApi: productsApi,
    products: productRepo,
    tasksApi: tasksApi,
    tasks: taskRepo,
    projectsApi: projectsApi,
    projects: projectRepo,
    vendorsApi: vendorsApi,
    vendors: vendorRepo,
    expensesApi: expensesApi,
    expenses: expenseRepo,
    recurringExpensesApi: recurringExpensesApi,
    recurringExpenses: recurringExpenseRepo,
    expenseCategoriesApi: expenseCategoriesApi,
    expenseCategories: expenseCategoryRepo,
    companyGatewaysApi: companyGatewaysApi,
    companyGateways: companyGatewayRepo,
    paymentTermsApi: paymentTermsApi,
    paymentTerms: paymentTermRepo,
    taxRatesApi: taxRatesApi,
    taxRates: taxRateRepo,
    taskStatusesApi: taskStatusesApi,
    taskStatuses: taskStatusRepo,
    designsApi: designsApi,
    designs: designRepo,
    groupSettingsApi: groupSettingsApi,
    groupSettings: groupSettingRepo,
    subscriptionsApi: subscriptionsApi,
    paymentLinks: paymentLinkRepo,
    schedulesApi: schedulesApi,
    schedules: scheduleRepo,
    invoicesApi: invoicesApi,
    invoices: invoiceRepo,
    quotesApi: quotesApi,
    quotes: quoteRepo,
    creditsApi: creditsApi,
    credits: creditRepo,
    bankAccountsApi: bankAccountsApi,
    bankAccounts: bankAccountRepo,
    bankTransactionsApi: bankTransactionsApi,
    bankTransactions: bankTransactionRepo,
    transactionRulesApi: transactionRulesApi,
    transactionRules: transactionRuleRepo,
    // Fan-out the bundled per-entity arrays the `/refresh` envelope carries
    // alongside the company. Order doesn't matter for correctness (each repo
    // upserts its own slice) but kept stable for log determinism. Add a new
    // bundled entity by appending a closure here.
    bundleAppliers: [
      ({required companyId, required company}) => taskStatusRepo.applyBundle(
        companyId: companyId,
        bundle: company.taskStatuses,
      ),
      ({required companyId, required company}) => companyGatewayRepo
          .applyBundle(companyId: companyId, bundle: company.companyGateways),
      ({required companyId, required company}) => paymentTermRepo.applyBundle(
        companyId: companyId,
        bundle: company.paymentTerms,
      ),
      ({required companyId, required company}) => taxRateRepo.applyBundle(
        companyId: companyId,
        bundle: company.taxRates,
      ),
      ({required companyId, required company}) => expenseCategoryRepo
          .applyBundle(companyId: companyId, bundle: company.expenseCategories),
      ({required companyId, required company}) => designRepo.applyBundle(
        companyId: companyId,
        bundle: company.designs,
      ),
      ({required companyId, required company}) => paymentLinkRepo.applyBundle(
        companyId: companyId,
        bundle: company.subscriptions,
      ),
      ({required companyId, required company}) => scheduleRepo.applyBundle(
        companyId: companyId,
        bundle: company.taskSchedulers,
      ),
    ],
  );
}
