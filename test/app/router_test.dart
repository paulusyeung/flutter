import 'package:admin/app/router.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// `defaultPostLoginRoute` is the post-login landing decision. Admin-portal
/// routes to the dashboard when the active company has `view_dashboard` and
/// falls back to clients otherwise — we mirror that here.

AuthSession _sessionWith(AuthCompany company) => AuthSession(
  baseUrl: 'https://example.test',
  isHosted: false,
  accountId: 'acc-1',
  companies: [company],
  currentCompanyId: company.id,
  plan: '',
  hostedCompanyCount: 0,
);

AuthCompany _company({
  required String permissions,
  bool isAdmin = false,
  bool isOwner = false,
}) => AuthCompany(
  id: 'co-1',
  name: 'Co',
  displayName: 'Co',
  permissions: permissions,
  isAdmin: isAdmin,
  isOwner: isOwner,
);

void main() {
  group('defaultPostLoginRoute', () {
    test('routes to /dashboard when company has view_dashboard', () {
      final session = _sessionWith(_company(permissions: 'view_dashboard'));
      expect(defaultPostLoginRoute(session), '/dashboard');
    });

    test('routes to /dashboard for admins regardless of permissions', () {
      final session = _sessionWith(_company(permissions: '', isAdmin: true));
      expect(defaultPostLoginRoute(session), '/dashboard');
    });

    test('routes to /dashboard for owners regardless of permissions', () {
      final session = _sessionWith(_company(permissions: '', isOwner: true));
      expect(defaultPostLoginRoute(session), '/dashboard');
    });

    test('routes to /clients when restricted user lacks view_dashboard', () {
      final session = _sessionWith(
        _company(permissions: 'view_client,edit_client'),
      );
      expect(defaultPostLoginRoute(session), '/clients');
    });

    test('routes to /clients when there is no session', () {
      expect(defaultPostLoginRoute(null), '/clients');
    });
  });
}
