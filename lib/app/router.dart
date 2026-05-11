import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/auth/views/client_too_old_screen.dart';
import 'package:admin/ui/features/auth/views/login_screen.dart';
import 'package:admin/ui/features/clients/views/client_detail_screen.dart';
import 'package:admin/ui/features/clients/views/client_edit_screen.dart';
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:admin/ui/features/settings/settings_routes.dart';
import 'package:admin/ui/features/settings/views/settings_screen.dart';
import 'package:admin/ui/features/settings/views/settings_shell.dart';
import 'package:admin/ui/features/shell/scaffold_with_nav.dart';

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
      return null;
    },
    errorBuilder: (context, state) => _RouteErrorView(error: state.error),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
              GoRoute(
                path: '/clients',
                builder: (context, state) => const ClientListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const ClientEditScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        ClientDetailScreen(id: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => ClientEditScreen(
                          existingId: state.pathParameters['id'],
                        ),
                      ),
                      // M2 cross-entity nav (invoices, tasks, payments) lands here.
                    ],
                  ),
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
