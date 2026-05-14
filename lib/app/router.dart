import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/auth/views/client_too_old_screen.dart';
import 'package:admin/ui/features/auth/views/lock_screen.dart';
import 'package:admin/ui/features/auth/views/login_screen.dart';
import 'package:admin/ui/features/dashboard/views/dashboard_screen.dart';
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
/// /<basePath>            -> list
/// /<basePath>/new        -> create  (onExit guard)
/// /<basePath>/:id        -> detail
/// /<basePath>/:id/edit   -> edit    (onExit guard)
/// /<basePath>/:id/<...>  -> [extraChildRoutes]
/// ```
///
/// Centralises the dirty-guard wiring on the two edit routes so every
/// entity gets it automatically — adding an entity module is one registry
/// entry, not 30 lines of copy-pasted `GoRoute`s.
GoRoute buildEntityRouteBlock({
  required String basePath,
  required GoRouterWidgetBuilder list,
  required GoRouterWidgetBuilder create,
  required GoRouterWidgetBuilder detail,
  required GoRouterWidgetBuilder edit,
  List<RouteBase> extraChildRoutes = const [],
}) {
  return GoRoute(
    path: basePath,
    builder: list,
    routes: [
      GoRoute(path: 'new', builder: create, onExit: _confirmExitIfDirty),
      GoRoute(
        path: ':id',
        builder: detail,
        routes: [
          GoRoute(path: 'edit', builder: edit, onExit: _confirmExitIfDirty),
          ...extraChildRoutes,
        ],
      ),
    ],
  );
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
