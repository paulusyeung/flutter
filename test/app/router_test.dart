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

  group('companySafeLocation', () {
    test('passes /dashboard through unchanged', () {
      expect(companySafeLocation('/dashboard'), '/dashboard');
    });

    test('passes /clients (list) through unchanged', () {
      expect(companySafeLocation('/clients'), '/clients');
    });

    test('passes /clients/new through unchanged', () {
      expect(companySafeLocation('/clients/new'), '/clients/new');
    });

    test('strips /clients/<id> back to /clients', () {
      expect(companySafeLocation('/clients/abc123'), '/clients');
    });

    test('strips /clients/<id>/edit back to /clients', () {
      expect(companySafeLocation('/clients/abc123/edit'), '/clients');
    });

    test('passes /settings/company_details through unchanged', () {
      expect(
        companySafeLocation('/settings/company_details'),
        '/settings/company_details',
      );
    });

    test('passes deep settings sub-routes through unchanged', () {
      expect(
        companySafeLocation('/settings/company_details/address'),
        '/settings/company_details/address',
      );
    });

    test('preserves query string on safe routes', () {
      expect(
        companySafeLocation('/clients?filter=active'),
        '/clients?filter=active',
      );
    });

    test('falls back to /clients for empty input', () {
      expect(companySafeLocation(''), '/clients');
    });

    test('falls back to /clients for garbage input', () {
      // `Uri.tryParse` accepts most strings; an empty path is the only
      // structural failure we treat as garbage.
      expect(companySafeLocation('http://'), '/clients');
    });
  });
}
