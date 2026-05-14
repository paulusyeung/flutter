import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/db/app_database.dart' show OutboxRow;
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';
import 'package:admin/ui/features/clients/views/client_detail_screen.dart';
import 'package:admin/ui/features/clients/views/client_edit_screen.dart';
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/clients/views/client_statement_screen.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/ui/features/products/views/product_detail_screen.dart';
import 'package:admin/ui/features/products/views/product_edit_screen.dart';
import 'package:admin/ui/features/products/views/product_list_screen.dart';
import 'package:admin/ui/features/tasks/views/task_detail_screen.dart';
import 'package:admin/ui/features/tasks/views/task_edit_screen.dart';
import 'package:admin/ui/features/tasks/views/task_list_screen.dart';

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
    sidebarSection: SidebarSection.top,
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
    ),
    detailBuilder: (context, state) =>
        TaskDetailScreen(id: state.pathParameters['id']!),
    editBuilder: (context, state) =>
        TaskEditScreen(existingId: state.pathParameters['id']),
  ),
];

/// Disabled placeholder entities — visible in the sidebar greyed-out with a
/// `coming_soon` tooltip so the legacy admin-portal nav surface stays
/// discoverable. Drop the `disabled: true` flag and supply screen builders
/// when each entity's module lands; nothing else in router/sidebar/DI
/// needs to change.
const kDisabledEntityModules = <EntityModuleSpec>[
  EntityModuleSpec(
    type: EntityType.invoice,
    wireName: 'invoice',
    apiPath: '/api/v1/invoices',
    routePath: '/invoices',
    icon: Icons.receipt_long,
    outlinedIcon: Icons.receipt_long_outlined,
    labelKey: 'invoices',
    sidebarOrder: 30,
    disabled: true,
  ),
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
  EntityModuleSpec(
    type: EntityType.expense,
    wireName: 'expense',
    apiPath: '/api/v1/expenses',
    routePath: '/expenses',
    icon: Icons.account_balance_wallet,
    outlinedIcon: Icons.account_balance_wallet_outlined,
    labelKey: 'expenses',
    sidebarOrder: 60,
    disabled: true,
  ),
  EntityModuleSpec(
    type: EntityType.project,
    wireName: 'project',
    apiPath: '/api/v1/projects',
    routePath: '/projects',
    icon: Icons.work,
    outlinedIcon: Icons.work_outline,
    labelKey: 'projects',
    sidebarOrder: 70,
    disabled: true,
  ),
  EntityModuleSpec(
    type: EntityType.vendor,
    wireName: 'vendor',
    apiPath: '/api/v1/vendors',
    routePath: '/vendors',
    icon: Icons.store,
    outlinedIcon: Icons.store_outlined,
    labelKey: 'vendors',
    sidebarOrder: 90,
    disabled: true,
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
  // Future enabled entities append here (6, 7, 8, …) so existing branch
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
