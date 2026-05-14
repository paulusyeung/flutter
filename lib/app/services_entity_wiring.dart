import 'package:admin/app/services_document_handlers.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/api/expense_api_model.dart';
import 'package:admin/data/models/api/expense_category_api_model.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/models/api/company_gateway_api_model.dart';
import 'package:admin/data/models/api/group_setting_api_model.dart';
import 'package:admin/data/models/api/payment_term_api_model.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/api/project_api_model.dart';
import 'package:admin/data/models/api/recurring_expense_api_model.dart';
import 'package:admin/data/models/api/task_api_model.dart';
import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/models/api/tax_rate_api_model.dart';
import 'package:admin/data/models/api/vendor_api_model.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/repositories/company_gateway_repository.dart';
import 'package:admin/data/repositories/expense_category_repository.dart';
import 'package:admin/data/repositories/expense_repository.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/data/repositories/payment_term_repository.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/data/repositories/project_repository.dart';
import 'package:admin/data/repositories/recurring_expense_repository.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/data/repositories/task_status_repository.dart';
import 'package:admin/data/repositories/tax_rate_repository.dart';
import 'package:admin/data/repositories/vendor_repository.dart';
import 'package:admin/data/services/activities_api.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/base_entity_api.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/company_gateways_api.dart';
import 'package:admin/data/services/documents_api.dart';
import 'package:admin/data/services/expense_categories_api.dart';
import 'package:admin/data/services/expenses_api.dart';
import 'package:admin/data/services/group_settings_api.dart';
import 'package:admin/data/services/payment_terms_api.dart';
import 'package:admin/data/services/products_api.dart';
import 'package:admin/data/services/projects_api.dart';
import 'package:admin/data/services/recurring_expenses_api.dart';
import 'package:admin/data/services/task_statuses_api.dart';
import 'package:admin/data/services/tasks_api.dart';
import 'package:admin/data/services/tax_rates_api.dart';
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
    required this.groupSettingsApi,
    required this.groupSettings,
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
  final GroupSettingsApi groupSettingsApi;
  final GroupSettingRepository groupSettings;

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
        upload:
            ({
              required entityId,
              required localPath,
              required idempotencyKey,
            }) async {
              final response = await clientsApi.uploadDocument(
                clientId: entityId,
                filePath: localPath,
                idempotencyKey: idempotencyKey,
              );
              return response.data;
            },
        applyChanged:
            ({required companyId, required entityId, required document}) =>
                clientRepo.applyDocumentChanged(
                  companyId: companyId,
                  clientId: entityId,
                  document: document,
                ),
        applyDeleted:
            ({required companyId, required entityId, required documentId}) =>
                clientRepo.applyDocumentDeleted(
                  companyId: companyId,
                  clientId: entityId,
                  documentId: documentId,
                ),
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
      upload:
          ({
            required entityId,
            required localPath,
            required idempotencyKey,
          }) async {
            final response = await productsApi.uploadDocument(
              productId: entityId,
              filePath: localPath,
              idempotencyKey: idempotencyKey,
            );
            return response.data;
          },
      applyChanged:
          ({required companyId, required entityId, required document}) =>
              productRepo.applyDocumentChanged(
                companyId: companyId,
                productId: entityId,
                document: document,
              ),
      applyDeleted:
          ({required companyId, required entityId, required documentId}) =>
              productRepo.applyDocumentDeleted(
                companyId: companyId,
                productId: entityId,
                documentId: documentId,
              ),
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
      upload:
          ({
            required entityId,
            required localPath,
            required idempotencyKey,
          }) async {
            final response = await projectsApi.uploadDocument(
              projectId: entityId,
              filePath: localPath,
              idempotencyKey: idempotencyKey,
            );
            return response.data;
          },
      applyChanged:
          ({required companyId, required entityId, required document}) =>
              projectRepo.applyDocumentChanged(
                companyId: companyId,
                projectId: entityId,
                document: document,
              ),
      applyDeleted:
          ({required companyId, required entityId, required documentId}) =>
              projectRepo.applyDocumentDeleted(
                companyId: companyId,
                projectId: entityId,
                documentId: documentId,
              ),
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
        upload:
            ({
              required entityId,
              required localPath,
              required idempotencyKey,
            }) async {
              final response = await vendorsApi.uploadDocument(
                vendorId: entityId,
                filePath: localPath,
                idempotencyKey: idempotencyKey,
              );
              return response.data;
            },
        applyChanged:
            ({required companyId, required entityId, required document}) =>
                vendorRepo.applyDocumentChanged(
                  companyId: companyId,
                  vendorId: entityId,
                  document: document,
                ),
        applyDeleted:
            ({required companyId, required entityId, required documentId}) =>
                vendorRepo.applyDocumentDeleted(
                  companyId: companyId,
                  vendorId: entityId,
                  documentId: documentId,
                ),
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
        upload:
            ({
              required entityId,
              required localPath,
              required idempotencyKey,
            }) async {
              final response = await expensesApi.uploadDocument(
                expenseId: entityId,
                filePath: localPath,
                idempotencyKey: idempotencyKey,
              );
              return response.data;
            },
        applyChanged:
            ({required companyId, required entityId, required document}) =>
                expenseRepo.applyDocumentChanged(
                  companyId: companyId,
                  expenseId: entityId,
                  document: document,
                ),
        applyDeleted:
            ({required companyId, required entityId, required documentId}) =>
                expenseRepo.applyDocumentDeleted(
                  companyId: companyId,
                  expenseId: entityId,
                  documentId: documentId,
                ),
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
        upload:
            ({
              required entityId,
              required localPath,
              required idempotencyKey,
            }) async {
              final response = await recurringExpensesApi.uploadDocument(
                recurringExpenseId: entityId,
                filePath: localPath,
                idempotencyKey: idempotencyKey,
              );
              return response.data;
            },
        applyChanged:
            ({required companyId, required entityId, required document}) =>
                recurringExpenseRepo.applyDocumentChanged(
                  companyId: companyId,
                  recurringExpenseId: entityId,
                  document: document,
                ),
        applyDeleted:
            ({required companyId, required entityId, required documentId}) =>
                recurringExpenseRepo.applyDocumentDeleted(
                  companyId: companyId,
                  recurringExpenseId: entityId,
                  documentId: documentId,
                ),
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
    groupSettingsApi: groupSettingsApi,
    groupSettings: groupSettingRepo,
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
    ],
  );
}
