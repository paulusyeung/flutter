import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/features/auth/views/client_too_old_screen.dart';
import '../ui/features/auth/views/login_screen.dart';
import '../ui/features/clients/views/client_detail_screen.dart';
import '../ui/features/clients/views/client_edit_screen.dart';
import '../ui/features/clients/views/client_list_screen.dart';
import '../ui/features/dashboard/views/dashboard_screen.dart';
import '../ui/features/settings/views/diagnostics_screen.dart';
import '../ui/features/settings/views/settings_screen.dart';
import '../ui/features/shell/scaffold_with_nav.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Build the app's [GoRouter].
///
/// `isAuthenticated` is read from `AuthRepository` in M1.8. Until then it's
/// passed in so the router can be constructed in tests and in the bootstrap
/// without depending on the auth layer yet.
GoRouter buildRouter({
  required bool Function() isAuthenticated,
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
        return isAuthenticated() ? '/clients' : '/login';
      }
      final loggedIn = isAuthenticated();
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn && !atLogin) return '/login';
      if (loggedIn && atLogin) return '/clients';
      return null;
    },
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route error: ${state.error}'))),
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
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'diagnostics',
                    builder: (context, state) => const DiagnosticsScreen(),
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
