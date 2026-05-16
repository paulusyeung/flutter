import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/auth/views/client_too_old_screen.dart';
import 'package:admin/ui/features/auth/views/lock_screen.dart';
import 'package:admin/ui/features/auth/views/login_screen.dart';
import 'package:admin/ui/features/auth/views/setup_wizard_screen.dart';
import 'package:admin/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:admin/ui/features/reports/views/reports_screen.dart';
import 'package:admin/ui/features/settings/settings_routes.dart';
import 'package:admin/ui/features/settings/views/settings_screen.dart';
import 'package:admin/ui/features/settings/views/settings_shell.dart';
import 'package:admin/ui/features/shell/scaffold_with_nav.dart';
import 'package:admin/ui/features/shell/widgets/in_sidebar.dart'
    show kInSidebarWidth, kInSidebarCollapsedWidth;
import 'package:admin/ui/features/sync/views/outbox_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Post-login landing: dashboard when the active company can view it,
/// clients otherwise. Mirrors admin-portal's behavior — `AuthCompany.can`
/// treats admins and owners as having every permission.
String defaultPostLoginRoute(AuthSession? session) {
  final canViewDashboard =
      session?.currentCompany?.can('view_dashboard') ?? false;
  return canViewDashboard ? '/dashboard' : '/clients';
}

/// True when the active company is freshly-created and still needs the
/// user to name it. Both admin-portal (`dashboard_screen.dart:96`) and React
/// (`App.tsx:190`) trigger their setup prompts on the same predicate — empty
/// settings.name or the server's default `'Untitled Company'` seed. The bare
/// `'Untitled'` fallback returned by `companyDisplayName` when *all* name
/// fields are empty is also treated as "needs setup"; a user-typed
/// `'Untitled'` passes through (real value lives in the row's name column).
bool isCompanySetupRequired(AuthSession? session) {
  final c = session?.currentCompany;
  if (c == null) return false;
  final name = c.displayName.trim();
  // Empty AND the resolved-fallback case both mean no real name set.
  // `companyDisplayName` returns `'Untitled'` only when settings.name,
  // displayName, and name on the row are all empty (see `auth_helpers.dart`).
  if (name.isEmpty || name == 'Untitled Company') return true;
  // A row whose stored `name` is non-empty but the resolved value is the
  // bare `'Untitled'` fallback means every name source is empty.
  if (name == 'Untitled' && c.name.isEmpty) return true;
  return false;
}

/// Returns the route to land on after a company switch from [currentLocation].
/// Any path under one of the [entityRoots] entries that references a specific
/// entity ID is stripped back to that list root; every other path (including
/// `<root>/new` create forms and arbitrary settings sub-routes) passes
/// through unchanged, query string and all.
///
/// Pass `services.entityRegistry.uiRoutePaths` for [entityRoots] in
/// production — keeping this function dependency-free of the registry makes
/// it trivially testable.
String companySafeLocation(
  String currentLocation,
  Iterable<String> entityRoots,
) {
  final uri = Uri.tryParse(currentLocation);
  if (uri == null || uri.path.isEmpty) return '/clients';
  for (final root in entityRoots) {
    final prefix = '$root/';
    if (!uri.path.startsWith(prefix)) continue;
    final firstSeg = uri.path.substring(prefix.length).split('/').first;
    if (firstSeg == 'new') return currentLocation;
    return root;
  }
  return currentLocation;
}

/// `GoRoute.onExit` callback for edit screens. Defers to the global
/// [UnsavedChangesGuard] so a stray `context.go(...)` that bypasses the
/// explicit entry-point guards (sidebar, picker, branch switch) still
/// prompts. Not attached to `/settings/company_details` — its tab variants
/// are sibling routes that would each fire `onExit` on every tab switch.
Future<bool> _confirmExitIfDirty(BuildContext context, GoRouterState state) {
  return context.read<Services>().unsavedChangesGuard.confirmIfDirty(context);
}

/// Build the standard entity route block:
///
/// ```
/// /<basePath>            -> list (master pane)
/// /<basePath>/new        -> create form (right pane)  (onExit guard)
/// /<basePath>/:id        -> detail (right pane)
/// /<basePath>/:id/edit   -> edit form (right pane)    (onExit guard)
/// /<basePath>/:id/<...>  -> [extraChildRoutes]        (full-screen, outside split)
/// ```
///
/// On wide desktop windows (≥ `Breakpoints.slideOver`) the list stays
/// mounted at full width and the detail / edit / create floats above
/// it as a slide-over pane (or fills the screen when `?view=full`).
/// On narrower windows the layout collapses to today's full-page
/// navigation.
///
/// Built around go_router's [ShellRoute]: the shell's `pageBuilder`
/// constructs the list once and reuses its Element across child route
/// changes, so list state (selection, scroll, multi-select, filters)
/// survives every row click. The right-pane child changes per
/// navigation; bare URL routes a const sentinel widget that
/// [MasterDetailLayout] reads as "no right pane".
///
/// `extraChildRoutes` (e.g. `/invoices/:id/pdf`) live as siblings to
/// the ShellRoute, so they take the full screen and don't inherit the
/// split chrome.
ShellRoute buildEntityRouteBlock({
  required String basePath,
  required GoRouterWidgetBuilder list,
  required GoRouterWidgetBuilder create,
  required GoRouterWidgetBuilder detail,
  required GoRouterWidgetBuilder edit,
  List<RouteBase> extraChildRoutes = const [],
}) {
  return ShellRoute(
    pageBuilder: (context, state, child) => NoTransitionPage<void>(
      key: ValueKey('master_detail:$basePath'),
      child: Builder(
        builder: (ctx) {
          // Read the URL :id once so the list-tile selection highlight
          // stays in sync with browser back / forward without every
          // tile establishing its own router dependency.
          final selectedId = state.pathParameters['id'];
          // The pane is visible iff the URL has navigated past the bare
          // list path. We can't `is`-check `child` against
          // `_NoPaneSentinel` here — go_router's `ShellRoute.pageBuilder`
          // hands us the inner Navigator widget, not the matched
          // sub-route's widget (see go_router/lib/src/route.dart's
          // `ShellRoute.buildPage`). The matched location is the
          // canonical signal.
          final hasPane = state.matchedLocation != basePath;
          // Read the `?view=full` flag from the URL so MasterDetailLayout
          // can render the pane in full-screen mode when set.
          final viewMode = state.uri.queryParameters['view'];
          return MasterDetailLayout(
            basePath: basePath,
            list: _SelectedIdScope(
              selectedId: selectedId,
              child: list(ctx, state),
            ),
            rightPane: hasPane ? child : null,
            viewMode: viewMode,
          );
        },
      ),
    ),
    routes: [
      // Bare list URL — the shell renders only the list, no right pane.
      GoRoute(
        path: basePath,
        builder: (_, _) => const _NoPaneSentinel(),
      ),
      GoRoute(
        path: '$basePath/new',
        builder: create,
        onExit: _confirmExitIfDirty,
      ),
      GoRoute(
        path: '$basePath/:id',
        // Wrap in a KeyedSubtree whose key includes the URL's `:id` so
        // navigating between rows of the same entity rebuilds the
        // screen's State from scratch. Detail / edit screens capture
        // `widget.id` at `initState` to build their VM — without a
        // fresh State the pane visually sticks on the previous row
        // when the user clicks a different row or presses J / K.
        builder: (context, state) => KeyedSubtree(
          key: ValueKey('detail:$basePath:${state.pathParameters['id']}'),
          child: detail(context, state),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => KeyedSubtree(
              key: ValueKey('edit:$basePath:${state.pathParameters['id']}'),
              child: edit(context, state),
            ),
            onExit: _confirmExitIfDirty,
          ),
          ...extraChildRoutes,
        ],
      ),
    ],
  );
}

/// Empty placeholder rendered by the Navigator at the bare list URL.
/// The slide-over pane is gated on `state.matchedLocation != basePath`
/// (see `buildEntityRouteBlock`'s pageBuilder), so this widget never
/// actually paints anything user-visible — `MasterDetailLayout`
/// suppresses its host pane on the bare URL. Kept as a named class so
/// the route definition reads `builder: ... const _NoPaneSentinel()`
/// rather than a bare `SizedBox.shrink`.
class _NoPaneSentinel extends StatelessWidget {
  const _NoPaneSentinel();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Inherits the URL-derived `selectedId` so list tiles can read it via
/// [_SelectedIdScope.maybeOf] without each tile registering as a
/// `GoRouterState` listener. Updating tiles on URL change is one frame
/// for the scope + one frame for each tile — same cost as today's
/// multi-select selection rebuild.
class _SelectedIdScope extends InheritedWidget {
  const _SelectedIdScope({required this.selectedId, required super.child});

  final String? selectedId;

  static String? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SelectedIdScope>()?.selectedId;

  @override
  bool updateShouldNotify(_SelectedIdScope oldWidget) =>
      selectedId != oldWidget.selectedId;
}

/// Public read-only access to the URL-derived `selectedId`. Used by
/// `EntityListScreenScaffold` to thread the selected id into
/// `EntityListTileOptions` so per-entity tile widgets can render the
/// selected row's accent stripe + background.
String? selectedIdFromRoute(BuildContext context) =>
    _SelectedIdScope.maybeOf(context);

/// Cross-entity navigation helper. Strips the `?view=full` query
/// param when the destination's first path segment differs from the
/// current URL's — e.g. clicking a transaction's matched-invoice
/// chip from `/transactions/tx_42?view=full` routes to `/invoices/:id`
/// without the lingering `view=full` (which would surprise the user
/// by opening an unrelated entity in full-screen mode).
///
/// Same-entity navigation (e.g. `/transactions/tx_1` → `/transactions/tx_2`)
/// preserves the param so toggling full-screen on one row sticks
/// across row clicks.
///
/// Use this for **cross-entity** `LinkText` chip handlers; same-entity
/// row clicks can keep using `context.go(...)` directly.
void goEntity(BuildContext context, String path) {
  final currentUri = GoRouterState.of(context).uri;
  final currentFirstSeg = _firstPathSegment(currentUri.path);
  final nextFirstSeg = _firstPathSegment(path);
  if (currentFirstSeg == nextFirstSeg) {
    // Same entity branch — leave the URL alone (preserve `?view`).
    GoRouter.of(context).go(path);
    return;
  }
  // Cross-entity — strip `?view` from the destination if it
  // accidentally got carried along.
  if (path.contains('?')) {
    final parsed = Uri.parse(path);
    final params = Map<String, String>.from(parsed.queryParameters)
      ..remove('view');
    final stripped = parsed.replace(
      queryParameters: params.isEmpty ? null : params,
    );
    GoRouter.of(context).go(stripped.toString());
  } else {
    GoRouter.of(context).go(path);
  }
}

String _firstPathSegment(String path) {
  final cleaned = path.startsWith('/') ? path.substring(1) : path;
  final i = cleaned.indexOf('/');
  return i < 0 ? cleaned : cleaned.substring(0, i);
}

/// Pure decision for [goEntityRecord]'s target path. Extracted so the
/// rule is unit-testable without a widget tree.
///
/// Row-click always opens the read-only **view** (detail) screen. The
/// only exception is the no-detail-screen guard: entities that have no
/// detail screen fall back to edit so the route is never dead.
String entityRecordPath({
  required String routePath,
  required String id,
  required bool hasDetailScreen,
}) => hasDetailScreen ? '$routePath/$id' : '$routePath/$id/edit';

/// Navigate to a record from a **datatable row tap** (or any
/// equivalent same-entity record jump — kanban cards, next/prev
/// actions). Resolves the entity's `routePath` from the registry
/// verbatim (settings entities are deeply nested, e.g.
/// `/settings/company_gateways`).
///
/// Always the view/detail screen (the resolver in `MasterDetailLayout`
/// decides slide-over vs full-screen). Entities with no detail screen
/// fall back to `/:id/edit` so the route is never dead. Never appends
/// `?view`.
///
/// Not for `EntityType.transactionRule` — that entity is owned by the
/// settings router with no `MasterDetailLayout`; its list keeps a raw
/// `context.go`.
void goEntityRecord(BuildContext context, EntityType type, String id) {
  final handlers = context.read<Services>().entityRegistry[type];
  if (handlers == null || handlers.routePath.isEmpty) return;
  GoRouter.of(context).go(
    entityRecordPath(
      routePath: handlers.routePath,
      id: id,
      hasDetailScreen: handlers.detailBuilder != null,
    ),
  );
}

/// Navigate to a record's **full-width view** (detail) screen. Used by
/// every in-cell link: the Number/identifier cell and cross-entity
/// references (client / vendor / project / category) all open the
/// referenced record's full-width view — editing is reached from the
/// view's Edit button. `?view=full` is explicit so it survives the
/// cross-entity hop (unlike [goEntity], which drops `view`).
void goEntityFullDetail(BuildContext context, String basePath, String id) {
  GoRouter.of(context).go('$basePath/$id?view=full');
}

/// Navigate to a record's **edit** screen from a detail-screen "Edit"
/// action, preserving the current pane mode: a full-screen view becomes
/// a full-screen edit; a slide-over view becomes a slide-over edit.
/// ([goEntity]'s same-entity branch does not re-add `?view`, so the
/// mode must be carried explicitly here.)
void goEntityEdit(BuildContext context, String basePath, String id) {
  final isFull =
      GoRouterState.of(context).uri.queryParameters['view'] == 'full';
  GoRouter.of(
    context,
  ).go(isFull ? '$basePath/$id/edit?view=full' : '$basePath/$id/edit');
}

/// Build the app's [GoRouter].
///
/// `isAuthenticated` is read from `AuthRepository`. The `registry` drives
/// the [StatefulShellRoute.indexedStack] branch list — adding an entity
/// module is one new `EntityBranch` in the registry's branch order, not
/// 30 lines of copy-pasted branch wiring.
GoRouter buildRouter({
  required bool Function() isAuthenticated,
  required String Function() postLoginRoute,
  required Listenable refreshListenable,
  required EntityRegistry registry,
  bool Function()? isClientTooOld,
  bool Function()? isBiometricLockRequired,
  bool Function()? isCompanySetupRequired,
  String initialLocation = '/clients',
}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      // Server-rejected-our-version wins over every other redirect: a new
      // login or list page would just bounce the same way.
      final tooOld = isClientTooOld?.call() ?? false;
      final atTooOld = state.matchedLocation == '/too-old';
      if (tooOld && !atTooOld) return '/too-old';
      if (!tooOld && atTooOld) {
        return isAuthenticated() ? postLoginRoute() : '/login';
      }
      final loggedIn = isAuthenticated();
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn && !atLogin) return '/login';
      if (loggedIn && atLogin) return postLoginRoute();
      // Setup-wizard gate — when the active company hasn't been named yet,
      // gate every authenticated route behind `/setup`. Sits *after* the
      // login check (so logout-from-wizard still routes to `/login`) and
      // *before* the biometric gate (a biometric-locked user must unlock
      // before being asked to name the company). Matches admin-portal's
      // non-dismissible `SettingsWizard` dialog and React's CompanyEdit
      // modal — same trigger condition, full-screen presentation instead.
      final setupNeeded =
          loggedIn && (isCompanySetupRequired?.call() ?? false);
      final atSetup = state.matchedLocation == '/setup';
      if (setupNeeded && !atSetup) return '/setup';
      if (!setupNeeded && atSetup) return postLoginRoute();
      // Biometric gate — only when logged in. Sits *after* the login check
      // so logout from the lock screen still routes the user to `/login`.
      //
      // We round-trip the intended destination on the `/lock` URL so the
      // unlock can resume the user's deep link rather than dumping them on
      // `postLoginRoute()` — admin-portal's "resume where you left off" is a
      // non-negotiable contract (CLAUDE.md).
      final lockRequired = isBiometricLockRequired?.call() ?? false;
      final atLock = state.matchedLocation == '/lock';
      if (loggedIn && lockRequired && !atLock) {
        return '/lock?from=${Uri.encodeQueryComponent(state.uri.toString())}';
      }
      if (loggedIn && !lockRequired && atLock) {
        final from = state.uri.queryParameters['from'];
        // Guard against `from` pointing back at `/lock` (defence-in-depth —
        // would only happen if the persister somehow saved a `/lock` deep
        // link, which `nav_state_persister.dart` already filters).
        if (from != null && from.isNotEmpty && !from.startsWith('/lock')) {
          return from;
        }
        return postLoginRoute();
      }
      return null;
    },
    errorBuilder: (context, state) => _RouteErrorView(error: state.error),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupWizardScreen(),
      ),
      GoRoute(
        path: '/too-old',
        builder: (context, state) => const ClientTooOldScreen(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, navigationShell) =>
            ScaffoldWithNav(navigationShell: navigationShell),
        branches: [
          for (final spec in registry.branchOrder) _buildBranch(spec, registry),
        ],
      ),
    ],
  );
}

StatefulShellBranch _buildBranch(BranchSpec spec, EntityRegistry registry) {
  switch (spec) {
    case EntityBranch():
      final h = registry[spec.type];
      assert(h != null, 'EntityBranch references unregistered ${spec.type}');
      assert(
        h!.listBuilder != null &&
            h.createBuilder != null &&
            h.detailBuilder != null &&
            h.editBuilder != null,
        'Entity ${spec.type} is in branchOrder but missing screen builders',
      );
      return StatefulShellBranch(
        routes: [
          buildEntityRouteBlock(
            basePath: h!.routePath,
            list: h.listBuilder!,
            create: h.createBuilder!,
            detail: h.detailBuilder!,
            edit: h.editBuilder!,
            extraChildRoutes: h.extraChildRoutes,
          ),
        ],
      );
    case FixedBranch():
      return _buildFixedBranch(spec.kind);
  }
}

StatefulShellBranch _buildFixedBranch(FixedBranchKind kind) {
  switch (kind) {
    case FixedBranchKind.dashboard:
      return StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ],
      );
    case FixedBranchKind.settings:
      return StatefulShellBranch(
        routes: [
          ShellRoute(
            builder: (context, state, child) => SettingsShell(child: child),
            routes: [
              GoRoute(
                path: '/settings',
                // On wide viewports the persistent sidebar makes the
                // "select a setting" hint redundant — land directly on
                // Company Details. Narrow keeps the master list as the
                // index. Only fires when the user is *exactly* on
                // `/settings`; deep paths pass through untouched.
                //
                // "Wide" here must match `SettingsShell`'s own
                // `LayoutBuilder` check (constraints ≥ `Breakpoints.wide`)
                // — that's the screen width *minus* the global `InSidebar`.
                // Using raw `MediaQuery` width would redirect at medium
                // widths (≈600–832 px) where the shell falls back to
                // single-pane and the section list never renders, dumping
                // the user on Company Details with no way to the list.
                redirect: (context, state) {
                  if (state.uri.path != '/settings') return null;
                  final screenWidth = MediaQuery.sizeOf(context).width;
                  if (screenWidth < Breakpoints.wide) return null;
                  final collapsed = context.read<Services>().sidebar.value;
                  final sidebarWidth = collapsed
                      ? kInSidebarCollapsedWidth
                      : kInSidebarWidth;
                  final shellWidth = screenWidth - sidebarWidth;
                  return shellWidth >= Breakpoints.wide
                      ? '/settings/company_details'
                      : null;
                },
                builder: (context, state) => const SettingsScreen(),
                routes: settingsRoutes,
              ),
            ],
          ),
        ],
      );
    case FixedBranchKind.outbox:
      return StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/sync/outbox',
            builder: (context, state) => const OutboxScreen(),
          ),
        ],
      );
    case FixedBranchKind.reports:
      return StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      );
  }
}

/// Rendered for any URL go_router can't match. Sits at the root, outside the
/// `StatefulShellRoute`, so it ships its own way home — without this the user
/// loses the shell's nav rail / bottom nav and gets stranded.
class _RouteErrorView extends StatelessWidget {
  const _RouteErrorView({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_off_outlined, size: 64, color: tokens.ink3),
              const SizedBox(height: 16),
              Text(
                context.tr('coming_soon'),
                style: theme.textTheme.titleMedium?.copyWith(color: tokens.ink),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: tokens.ink3),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/dashboard'),
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                icon: const Icon(Icons.home_outlined, size: 16),
                label: Text(context.tr('dashboard')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
