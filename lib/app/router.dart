import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/auth/views/client_too_old_screen.dart';
import 'package:admin/ui/features/auth/views/lock_screen.dart';
import 'package:admin/ui/features/auth/views/login_screen.dart';
import 'package:admin/ui/features/clients/views/client_detail_screen.dart';
import 'package:admin/ui/features/clients/views/client_edit_screen.dart';
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/clients/views/client_statement_screen.dart';
import 'package:admin/ui/features/products/views/product_detail_screen.dart';
import 'package:admin/ui/features/products/views/product_edit_screen.dart';
import 'package:admin/ui/features/products/views/product_list_screen.dart';
import 'package:admin/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:admin/ui/features/settings/settings_routes.dart';
import 'package:admin/ui/features/settings/views/settings_screen.dart';
import 'package:admin/ui/features/settings/views/settings_shell.dart';
import 'package:admin/ui/features/shell/scaffold_with_nav.dart';
import 'package:admin/ui/features/sync/views/outbox_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Post-login landing: dashboard when the active company can view it,
/// clients otherwise. Mirrors admin-portal's behavior — `AuthCompany.can`
/// treats admins and owners as having every permission.
String defaultPostLoginRoute(AuthSession? session) {
  final canViewDashboard =
      session?.currentCompany?.can('view_dashboard') ?? false;
  return canViewDashboard ? '/dashboard' : '/clients';
}

/// Entity-list roots whose `<root>/<id>[/edit]` children reference a specific
/// entity in the current company. After a company switch those IDs become
/// stale, so [companySafeLocation] strips them back to the list. Add more
/// roots here as entities land in M2+ (`/invoices`, `/payments`, …).
const _entityListRoots = <String>['/clients', '/products'];

/// Returns the route to land on after a company switch from [currentLocation].
/// Any path under an [_entityListRoots] entry that references a specific
/// entity ID is stripped back to that list root; every other path (including
/// `<root>/new` create forms and arbitrary settings sub-routes) passes through
/// unchanged, query string and all.
String companySafeLocation(String currentLocation) {
  final uri = Uri.tryParse(currentLocation);
  if (uri == null || uri.path.isEmpty) return '/clients';
  for (final root in _entityListRoots) {
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
/// entity gets it automatically — adding an `Invoice` module is one call
/// to this helper, not 30 lines of copy-pasted `GoRoute`s.
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
/// `isAuthenticated` is read from `AuthRepository` in M1.8. Until then it's
/// passed in so the router can be constructed in tests and in the bootstrap
/// without depending on the auth layer yet.
GoRouter buildRouter({
  required bool Function() isAuthenticated,
  required String Function() postLoginRoute,
  required Listenable refreshListenable,
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
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              buildEntityRouteBlock(
                basePath: '/clients',
                list: (context, state) => const ClientListScreen(),
                create: (context, state) => const ClientEditScreen(),
                detail: (context, state) =>
                    ClientDetailScreen(id: state.pathParameters['id']!),
                edit: (context, state) =>
                    ClientEditScreen(existingId: state.pathParameters['id']),
                extraChildRoutes: [
                  GoRoute(
                    path: 'statement',
                    builder: (context, state) => ClientStatementScreen(
                      clientId: state.pathParameters['id']!,
                    ),
                  ),
                  // M2 cross-entity nav (invoices, tasks, payments) lands here.
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              buildEntityRouteBlock(
                basePath: '/products',
                list: (context, state) => const ProductListScreen(),
                create: (context, state) => const ProductEditScreen(),
                detail: (context, state) =>
                    ProductDetailScreen(id: state.pathParameters['id']!),
                edit: (context, state) =>
                    ProductEditScreen(existingId: state.pathParameters['id']),
              ),
            ],
          ),
          StatefulShellBranch(
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
                    redirect: (context, state) {
                      if (state.uri.path != '/settings') return null;
                      final wide =
                          MediaQuery.sizeOf(context).width >= Breakpoints.wide;
                      return wide ? '/settings/company_details' : null;
                    },
                    builder: (context, state) => const SettingsScreen(),
                    routes: settingsRoutes,
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sync/outbox',
                builder: (context, state) => const OutboxScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
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
