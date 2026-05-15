import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/db/app_database.dart' show OutboxRow;
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';
import 'package:admin/ui/features/clients/views/client_detail_screen.dart';
import 'package:admin/ui/features/clients/views/client_edit_screen.dart';
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/clients/views/client_statement_screen.dart';
import 'package:admin/ui/features/expense_categories/views/expense_category_detail_screen.dart';
import 'package:admin/ui/features/expense_categories/views/expense_category_edit_screen.dart';
import 'package:admin/ui/features/expense_categories/views/expense_category_list_screen.dart';
import 'package:admin/ui/features/expenses/views/expense_detail_screen.dart';
import 'package:admin/ui/features/expenses/views/expense_edit_screen.dart';
import 'package:admin/ui/features/expenses/views/expense_list_screen.dart';
import 'package:admin/ui/features/gateways/views/company_gateway_detail_screen.dart';
import 'package:admin/ui/features/gateways/views/company_gateway_edit_screen.dart';
import 'package:admin/ui/features/gateways/views/company_gateway_list_screen.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/ui/features/invoices/views/invoice_detail_screen.dart';
import 'package:admin/ui/features/invoices/views/invoice_edit_screen.dart';
import 'package:admin/ui/features/invoices/views/invoice_list_screen.dart';
import 'package:admin/ui/features/invoices/views/invoice_pdf_route_screen.dart';
import 'package:admin/ui/features/products/views/product_detail_screen.dart';
import 'package:admin/ui/features/products/views/product_edit_screen.dart';
import 'package:admin/ui/features/products/views/product_list_screen.dart';
import 'package:admin/ui/features/projects/views/project_detail_screen.dart';
import 'package:admin/ui/features/projects/views/project_edit_screen.dart';
import 'package:admin/ui/features/projects/views/project_list_screen.dart';
import 'package:admin/ui/features/recurring_expenses/views/recurring_expense_detail_screen.dart';
import 'package:admin/ui/features/recurring_expenses/views/recurring_expense_edit_screen.dart';
import 'package:admin/ui/features/recurring_expenses/views/recurring_expense_list_screen.dart';
import 'package:admin/ui/features/payment_links/views/payment_link_detail_screen.dart';
import 'package:admin/ui/features/payment_links/views/payment_link_edit_screen.dart';
import 'package:admin/ui/features/payment_links/views/payment_link_list_screen.dart';
import 'package:admin/ui/features/tasks/views/task_detail_screen.dart';
import 'package:admin/ui/features/tasks/views/task_edit_screen.dart';
import 'package:admin/ui/features/tasks/views/task_list_screen.dart';
import 'package:admin/ui/features/vendors/views/vendor_detail_screen.dart';
import 'package:admin/ui/features/vendors/views/vendor_edit_screen.dart';
import 'package:admin/ui/features/vendors/views/vendor_list_screen.dart';

/// Static UI module description for one entity. Carries everything the
/// router and sidebar need to render an entity module + the metadata used
/// when wiring its [EntityHandlers] in DI.
///
/// Separated from [EntityHandlers] because module specs are compile-time
/// constants (screen builders, icons, route paths) while the dispatcher
/// is constructed at runtime against the live db + api client.
class EntityModuleSpec {
  const EntityModuleSpec({
    required this.type,
    required this.wireName,
    required this.apiPath,
    required this.routePath,
    required this.icon,
    required this.outlinedIcon,
    required this.labelKey,
    required this.sidebarOrder,
    this.sidebarSection = SidebarSection.top,
    this.disabled = false,
    this.requiresPasswordFor = const {},
    this.listBuilder,
    this.createBuilder,
    this.detailBuilder,
    this.editBuilder,
    this.extraChildRoutes = const [],
    this.badgeStream,
  });

  final EntityType type;
  final String wireName;
  final String apiPath;
  final String routePath;
  final IconData icon;
  final IconData outlinedIcon;
  final String labelKey;
  final int sidebarOrder;

  /// Which section of the main workspace sidebar this entity renders in.
  /// Defaults to [SidebarSection.top]; pass [SidebarSection.none] for
  /// entities that are routable + sync-wired but shouldn't surface in the
  /// workspace nav (e.g. CompanyGateway, which is reachable only via the
  /// Settings sidebar).
  final SidebarSection sidebarSection;

  final bool disabled;
  final Set<MutationKind> requiresPasswordFor;
  final GoRouterWidgetBuilder? listBuilder;
  final GoRouterWidgetBuilder? createBuilder;
  final GoRouterWidgetBuilder? detailBuilder;
  final GoRouterWidgetBuilder? editBuilder;
  final List<RouteBase> extraChildRoutes;
  final SidebarBadgeStream? badgeStream;

  /// Convert this spec into an [EntityHandlers]. The caller supplies the
  /// [dispatcher] (which depends on runtime DI state) and we copy the
  /// static fields across.
  EntityHandlers toHandlers(SyncDispatcher dispatcher) => EntityHandlers(
    type: type,
    wireName: wireName,
    apiPath: apiPath,
    routePath: routePath,
    icon: icon,
    outlinedIcon: outlinedIcon,
    labelKey: labelKey,
    sidebarSection: sidebarSection,
    sidebarOrder: sidebarOrder,
    disabled: disabled,
    requiresPasswordFor: requiresPasswordFor,
    dispatcher: dispatcher,
    listBuilder: listBuilder,
    createBuilder: createBuilder,
    detailBuilder: detailBuilder,
    editBuilder: editBuilder,
    extraChildRoutes: extraChildRoutes,
    badgeStream: badgeStream,
  );
}

/// Wired entity modules: every entity that has list/detail/edit screens
/// today. Adding a new entity = adding one entry here + its per-entity
/// files + one DI block in `services.dart`. The router and sidebar both
/// iterate this list (via [EntityRegistry]) — they need no per-entity
/// touch.
final kWiredEntityModules = <EntityModuleSpec>[
  // DI: wireEntity<ClientItemApi, ClientApi>(...) in lib/app/services.dart.
  EntityModuleSpec(
    type: EntityType.client,
    wireName: 'client',
    apiPath: '/api/v1/clients',
    routePath: '/clients',
    icon: Icons.people,
    outlinedIcon: Icons.people_outline,
    labelKey: 'clients',
    sidebarOrder: 10,
    requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
    listBuilder: (context, state) => const ClientListScreen(),
    createBuilder: (context, state) => const ClientEditScreen(),
    detailBuilder: (context, state) =>
        ClientDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        ClientEditScreen(existingId: state.pathParameters['id']),
    extraChildRoutes: [
      GoRoute(
        path: 'statement',
        builder: (context, state) =>
            ClientStatementScreen(clientId: state.pathParameters['id']!),
      ),
      // M2 cross-entity nav (invoices, tasks, payments) lands here.
    ],
    badgeStream: (ctx, companyId) => ctx.watchClientCount(companyId),
  ),
  // DI: wireEntity<ProductItemApi, ProductApi>(...) in lib/app/services.dart.
  EntityModuleSpec(
    type: EntityType.product,
    wireName: 'product',
    apiPath: '/api/v1/products',
    routePath: '/products',
    icon: Icons.inventory_2,
    outlinedIcon: Icons.inventory_2_outlined,
    labelKey: 'products',
    sidebarOrder: 20,
    requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
    listBuilder: (context, state) => const ProductListScreen(),
    createBuilder: (context, state) => ProductEditScreen(
      cloneFrom: state.extra is Product ? state.extra as Product : null,
    ),
    detailBuilder: (context, state) =>
        ProductDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        ProductEditScreen(existingId: state.pathParameters['id']),
  ),
  EntityModuleSpec(
    type: EntityType.task,
    wireName: 'task',
    apiPath: '/api/v1/tasks',
    routePath: '/tasks',
    icon: Icons.task,
    outlinedIcon: Icons.task_outlined,
    labelKey: 'tasks',
    sidebarOrder: 80,
    requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
    listBuilder: (context, state) => TaskListScreen(
      // `?view=kanban` switches the body to the kanban board; default is
      // the standard list. Read here (not in the screen) so deep links
      // open in the right view from the first frame.
      view: state.uri.queryParameters['view'] == 'kanban'
          ? TasksViewMode.kanban
          : TasksViewMode.list,
    ),
    createBuilder: (context, state) => TaskEditScreen(
      cloneFrom: state.extra is Task ? state.extra as Task : null,
      // `?project=<id>` seeds the new task with the project (and side-
      // effects: clientId from the project, rate from project.task_rate
      // when rate is zero, locks the client picker). Wired by the
      // Project detail "Add task" affordance.
      prefillProjectId: state.uri.queryParameters['project'],
    ),
    detailBuilder: (context, state) =>
        TaskDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        TaskEditScreen(existingId: state.pathParameters['id']),
  ),
  // DI: wireEntity<CompanyGatewayItemApi, CompanyGatewayApi>(...) in lib/app/services.dart.
  EntityModuleSpec(
    type: EntityType.companyGateway,
    wireName: 'company_gateway',
    apiPath: '/api/v1/company_gateways',
    routePath: '/settings/company_gateways',
    icon: Icons.account_balance_wallet,
    outlinedIcon: Icons.account_balance_wallet_outlined,
    labelKey: 'company_gateways',
    // Settings-only entity — reached via the Settings sidebar / the
    // Online Payments "Configure Gateways" button. Keeping it out of the
    // main workspace sidebar matches the legacy admin-portal + React.
    sidebarSection: SidebarSection.none,
    sidebarOrder: 200,
    requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
    listBuilder: (context, state) => const CompanyGatewayListScreen(),
    createBuilder: (context, state) => CompanyGatewayEditScreen(
      initialGatewayKey: state.uri.queryParameters['gateway'],
    ),
    detailBuilder: (context, state) =>
        CompanyGatewayDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        CompanyGatewayEditScreen(existingId: state.pathParameters['id']),
  ),
  // DI: wireEntity<GroupSettingItemApi, GroupSettingApi>(...) in lib/app/services.dart.
  // Settings-only — reached via Settings → Advanced → Group Settings; the
  // settings router owns the actual route tree (see settings_routes.dart).
  EntityModuleSpec(
    type: EntityType.group,
    wireName: 'group',
    apiPath: '/api/v1/group_settings',
    routePath: '/settings/group_settings',
    icon: Icons.group_work_outlined,
    outlinedIcon: Icons.group_work_outlined,
    labelKey: 'group_settings',
    sidebarSection: SidebarSection.none,
    sidebarOrder: 210,
    requiresPasswordFor: const {MutationKind.delete},
  ),
  // DI: wireEntity<TaskStatusItemApi, TaskStatusApi>(...) in lib/app/services.dart.
  EntityModuleSpec(
    type: EntityType.taskStatus,
    wireName: 'task_status',
    apiPath: '/api/v1/task_statuses',
    routePath: '/settings/task_statuses',
    icon: Icons.label_outline,
    outlinedIcon: Icons.label_outline,
    labelKey: 'task_statuses',
    sidebarSection: SidebarSection.none,
    sidebarOrder: 220,
    requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
  ),
  // DI: wireEntity<PaymentTermItemApi, PaymentTermApi>(...) in lib/app/services.dart.
  EntityModuleSpec(
    type: EntityType.paymentTerm,
    wireName: 'payment_term',
    apiPath: '/api/v1/payment_terms',
    routePath: '/settings/payment_terms',
    icon: Icons.schedule_outlined,
    outlinedIcon: Icons.schedule_outlined,
    labelKey: 'payment_terms',
    sidebarSection: SidebarSection.none,
    sidebarOrder: 230,
    requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
  ),
  // DI: wireEntity<ProjectItemApi, ProjectApi>(...) in lib/app/services.dart.
  EntityModuleSpec(
    type: EntityType.project,
    wireName: 'project',
    apiPath: '/api/v1/projects',
    routePath: '/projects',
    icon: Icons.work,
    outlinedIcon: Icons.work_outline,
    labelKey: 'projects',
    sidebarOrder: 70,
    requiresPasswordFor: const {
      MutationKind.delete,
      MutationKind.purge,
      MutationKind.documentDelete,
    },
    listBuilder: (context, state) => const ProjectListScreen(),
    createBuilder: (context, state) => ProjectEditScreen(
      cloneFrom: state.extra is Project ? state.extra as Project : null,
      // `?client=<id>` seeds the picker when the user kicks off
      // "New project" from a Client detail screen.
      prefillClientId: state.uri.queryParameters['client'],
    ),
    detailBuilder: (context, state) =>
        ProjectDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        ProjectEditScreen(existingId: state.pathParameters['id']),
  ),
  // DI: wire<VendorItemApi, VendorApi>(...) in lib/app/services_entity_wiring.dart.
  EntityModuleSpec(
    type: EntityType.vendor,
    wireName: 'vendor',
    apiPath: '/api/v1/vendors',
    routePath: '/vendors',
    icon: Icons.store,
    outlinedIcon: Icons.store_outlined,
    labelKey: 'vendors',
    sidebarOrder: 90,
    requiresPasswordFor: const {
      MutationKind.delete,
      MutationKind.purge,
      MutationKind.documentDelete,
    },
    listBuilder: (context, state) => const VendorListScreen(),
    createBuilder: (context, state) => const VendorEditScreen(),
    detailBuilder: (context, state) =>
        VendorDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        VendorEditScreen(existingId: state.pathParameters['id']),
  ),
  // DI: wire<ExpenseItemApi, ExpenseApi>(...) in lib/app/services_entity_wiring.dart.
  EntityModuleSpec(
    type: EntityType.expense,
    wireName: 'expense',
    apiPath: '/api/v1/expenses',
    routePath: '/expenses',
    icon: Icons.receipt_outlined,
    outlinedIcon: Icons.receipt_outlined,
    labelKey: 'expenses',
    sidebarOrder: 60,
    requiresPasswordFor: const {
      MutationKind.delete,
      MutationKind.purge,
      MutationKind.documentDelete,
    },
    listBuilder: (context, state) => const ExpenseListScreen(),
    createBuilder: (context, state) => ExpenseEditScreen(
      cloneFrom: state.extra is Expense ? state.extra as Expense : null,
    ),
    detailBuilder: (context, state) =>
        ExpenseDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        ExpenseEditScreen(existingId: state.pathParameters['id']),
  ),
  // DI: wire<InvoiceItemApi, InvoiceApi>(...) in
  // lib/app/services_entity_wiring.dart. Document-bearing, with eleven
  // non-CRUD custom actions (markSent/markPaid/email/scheduleEmail/cloneTo*
  // /autoBill/cancel/runTemplate). M1 ships the read-only list + detail
  // header + stub edit; M2 adds PDF/email; M3 adds the full edit form
  // (Details / Contacts / Items / Notes / PDF / E-Invoice tabs); M4 adds
  // payment-schedule wizard + Verifactu + reminders.
  EntityModuleSpec(
    type: EntityType.invoice,
    wireName: 'invoice',
    apiPath: '/api/v1/invoices',
    routePath: '/invoices',
    icon: Icons.receipt_long,
    outlinedIcon: Icons.receipt_long_outlined,
    labelKey: 'invoices',
    sidebarOrder: 30,
    requiresPasswordFor: const {
      MutationKind.delete,
      MutationKind.purge,
      MutationKind.documentDelete,
    },
    listBuilder: (context, state) => const InvoiceListScreen(),
    createBuilder: (context, state) => InvoiceEditScreen(
      cloneFrom: state.extra is Invoice ? state.extra as Invoice : null,
    ),
    detailBuilder: (context, state) =>
        InvoiceDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        InvoiceEditScreen(existingId: state.pathParameters['id']),
    extraChildRoutes: [
      GoRoute(
        path: 'pdf',
        // Full-screen server-rendered PDF preview with print/share/download
        // toolbar provided by the `printing` package. Reached from the
        // detail screen's "View PDF" action or directly via deep link.
        builder: (context, state) =>
            InvoicePdfRouteScreen(id: state.pathParameters['id']!),
      ),
    ],
  ),
  // DI: wire<RecurringExpenseItemApi, RecurringExpenseApi>(...) in
  // lib/app/services_entity_wiring.dart. `start` / `stop` flow through
  // dedicated MutationKind values; the dispatcher's customActions block
  // translates them to `?start=true` / `?stop=true` PUTs.
  EntityModuleSpec(
    type: EntityType.recurringExpense,
    wireName: 'recurring_expense',
    apiPath: '/api/v1/recurring_expenses',
    routePath: '/recurring_expenses',
    icon: Icons.event_repeat,
    outlinedIcon: Icons.event_repeat_outlined,
    labelKey: 'recurring_expenses',
    sidebarOrder: 65,
    requiresPasswordFor: const {
      MutationKind.delete,
      MutationKind.purge,
      MutationKind.documentDelete,
    },
    listBuilder: (context, state) => const RecurringExpenseListScreen(),
    createBuilder: (context, state) => RecurringExpenseEditScreen(
      cloneFrom: state.extra is RecurringExpense
          ? state.extra as RecurringExpense
          : null,
    ),
    detailBuilder: (context, state) =>
        RecurringExpenseDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        RecurringExpenseEditScreen(existingId: state.pathParameters['id']),
  ),
  // DI: wire<ExpenseCategoryItemApi, ExpenseCategoryApi>(...) in
  // lib/app/services_entity_wiring.dart. Settings-only entity reached via
  // Settings → Advanced. Bundled via the `/refresh` envelope alongside
  // task_statuses / payment_terms / tax_rates.
  EntityModuleSpec(
    type: EntityType.expenseCategory,
    wireName: 'expense_category',
    apiPath: '/api/v1/expense_categories',
    routePath: '/settings/expense_categories',
    icon: Icons.label_outlined,
    outlinedIcon: Icons.label_outlined,
    labelKey: 'expense_categories',
    sidebarSection: SidebarSection.none,
    sidebarOrder: 250,
    requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
    listBuilder: (context, state) => const ExpenseCategoryListScreen(),
    createBuilder: (context, state) => ExpenseCategoryEditScreen(
      cloneFrom: state.extra is ExpenseCategory
          ? state.extra as ExpenseCategory
          : null,
    ),
    detailBuilder: (context, state) =>
        ExpenseCategoryDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        ExpenseCategoryEditScreen(existingId: state.pathParameters['id']),
  ),
  // DI: wire<SubscriptionItemApi, SubscriptionApi>(...) in
  // lib/app/services_entity_wiring.dart. The HTTP wire stays as
  // `subscription` (URL: /api/v1/subscriptions, DTO: SubscriptionApi,
  // bundled envelope key: company.subscriptions). The local outbox
  // `entity_type` column + the entity registry's wireName are
  // `payment_link` — these never touch the server. Settings-only entity
  // reached via Settings → Advanced → Payment Links. Bundled via the
  // `/refresh` envelope alongside task_statuses / payment_terms /
  // tax_rates / expense_categories.
  EntityModuleSpec(
    type: EntityType.paymentLink,
    wireName: 'payment_link',
    apiPath: '/api/v1/subscriptions',
    routePath: '/settings/payment_links',
    icon: Icons.link_outlined,
    outlinedIcon: Icons.link_outlined,
    labelKey: 'payment_links',
    sidebarSection: SidebarSection.none,
    sidebarOrder: 260,
    requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
    listBuilder: (context, state) => const PaymentLinkListScreen(),
    createBuilder: (context, state) => PaymentLinkEditScreen(
      cloneFrom: state.extra is PaymentLink
          ? state.extra as PaymentLink
          : null,
    ),
    detailBuilder: (context, state) =>
        PaymentLinkDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        PaymentLinkEditScreen(existingId: state.pathParameters['id']),
  ),
];

/// Disabled placeholder entities — visible in the sidebar greyed-out with a
/// `coming_soon` tooltip so the legacy admin-portal nav surface stays
/// discoverable. Drop the `disabled: true` flag and supply screen builders
/// when each entity's module lands; nothing else in router/sidebar/DI
/// needs to change.
const kDisabledEntityModules = <EntityModuleSpec>[
  EntityModuleSpec(
    type: EntityType.quote,
    wireName: 'quote',
    apiPath: '/api/v1/quotes',
    routePath: '/quotes',
    icon: Icons.request_quote,
    outlinedIcon: Icons.request_quote_outlined,
    labelKey: 'quotes',
    sidebarOrder: 40,
    disabled: true,
  ),
  EntityModuleSpec(
    type: EntityType.payment,
    wireName: 'payment',
    apiPath: '/api/v1/payments',
    routePath: '/payments',
    icon: Icons.payments,
    outlinedIcon: Icons.payments_outlined,
    labelKey: 'payments',
    sidebarOrder: 50,
    disabled: true,
  ),
  // Tax rates — modeled and persisted (via bundle) for the default-tax
  // pickers on Settings → Tax Settings. No CRUD screen yet; the spec sits
  // here so the entity registry knows the type without rendering sidebar
  // chrome. Promote to `kWiredEntityModules` when the list/edit screens land.
  EntityModuleSpec(
    type: EntityType.taxRate,
    wireName: 'tax_rate',
    apiPath: '/api/v1/tax_rates',
    routePath: '/settings/tax_rates',
    icon: Icons.percent_outlined,
    outlinedIcon: Icons.percent_outlined,
    labelKey: 'tax_rates',
    sidebarSection: SidebarSection.none,
    sidebarOrder: 240,
    disabled: true,
    requiresPasswordFor: {MutationKind.delete, MutationKind.purge},
  ),
  // Designs — modeled and persisted (via bundle) for the Invoice Design
  // pickers and the upcoming Custom Designs CRUD list. Promote to
  // `kWiredEntityModules` when the list / edit screens land (the wiring
  // already lives in `services_entity_wiring.dart`).
  EntityModuleSpec(
    type: EntityType.design,
    wireName: 'design',
    apiPath: '/api/v1/designs',
    routePath: '/settings/invoice_design/custom_designs',
    icon: Icons.design_services_outlined,
    outlinedIcon: Icons.design_services_outlined,
    labelKey: 'custom_designs',
    sidebarSection: SidebarSection.none,
    sidebarOrder: 250,
    disabled: true,
    requiresPasswordFor: {MutationKind.delete, MutationKind.purge},
  ),
];

/// Router branch order. Indices stay stable across releases so persisted
/// navigation state (last-visited branch in `nav_state`) keeps working.
/// New entity branches append; never reorder the existing 5.
const kBranchOrder = <BranchSpec>[
  EntityBranch(EntityType.client), // 0
  FixedBranch(FixedBranchKind.dashboard), // 1
  EntityBranch(EntityType.product), // 2
  FixedBranch(FixedBranchKind.settings), // 3
  FixedBranch(FixedBranchKind.outbox), // 4
  EntityBranch(EntityType.task), // 5
  EntityBranch(EntityType.project), // 6
  EntityBranch(EntityType.companyGateway), // 7 — settings entity, sidebar
  //     entry under Advanced.
  EntityBranch(EntityType.vendor), // 8
  EntityBranch(EntityType.expense), // 9
  EntityBranch(EntityType.recurringExpense), // 10
  EntityBranch(EntityType.expenseCategory), // 11 — settings entity, no
  //     workspace sidebar entry. Reached via Settings → Advanced.
  // Tax Rate intentionally skipped — it's a disabled entity (no CRUD screen
  // today). Add an `EntityBranch(EntityType.taxRate)` here when the Tax
  // Rates settings page lands and the spec moves to `kWiredEntityModules`.
  EntityBranch(EntityType.paymentLink), // 12 — Payment Links settings
  //     entity, no workspace sidebar entry. Reached via Settings → Advanced.
  EntityBranch(EntityType.invoice), // 13
  // Future enabled entities append here (14, 15, …) so existing branch
  // indices keep their meaning.
];

/// Dispatcher used for disabled-but-registered entities. Outbox rows for
/// these will never appear (no UI to enqueue them), but if one ever does
/// the throw surfaces as a "marked dead" entry on the outbox screen rather
/// than a silent no-op.
class DisabledEntityDispatcher implements SyncDispatcher {
  const DisabledEntityDispatcher(this.type);
  final EntityType type;
  @override
  Future<void> dispatch({required OutboxRow row, required MutationKind kind}) {
    throw UnimplementedError(
      'No sync dispatcher for $type — entity is registered as disabled. '
      'Drop EntityModuleSpec.disabled=true and supply a real dispatcher.',
    );
  }
}
