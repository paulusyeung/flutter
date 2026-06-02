import 'package:admin/app/entity_modules.dart' show DisabledEntityDispatcher;
import 'package:admin/app/router.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:flutter/material.dart' show Icons;
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
  String name = 'Co',
  String displayName = 'Co',
}) => AuthCompany(
  id: 'co-1',
  name: name,
  displayName: displayName,
  permissions: permissions,
  isAdmin: isAdmin,
  isOwner: isOwner,
);

const _testRoots = ['/clients', '/products'];

EntityHandlers _handler(
  EntityType type,
  String wire,
  String routePath, {
  SidebarSection section = SidebarSection.top,
  bool disabled = false,
}) => EntityHandlers(
  type: type,
  wireName: wire,
  apiPath: '/api/v1/$wire',
  routePath: routePath,
  icon: Icons.circle,
  dispatcher: DisabledEntityDispatcher(type),
  sidebarSection: section,
  disabled: disabled,
);

/// client (always-on), invoice + task (module-gated), companyGateway
/// (settings-only / SidebarSection.none — never a disabled-root candidate).
EntityRegistry _registry() => EntityRegistry({
  EntityType.client: _handler(EntityType.client, 'client', '/clients'),
  EntityType.invoice: _handler(EntityType.invoice, 'invoice', '/invoices'),
  EntityType.task: _handler(EntityType.task, 'task', '/tasks'),
  EntityType.companyGateway: _handler(
    EntityType.companyGateway,
    'company_gateway',
    '/settings/company_gateways',
    section: SidebarSection.none,
  ),
});

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
      expect(companySafeLocation('/dashboard', _testRoots), '/dashboard');
    });

    test('passes /clients (list) through unchanged', () {
      expect(companySafeLocation('/clients', _testRoots), '/clients');
    });

    test('passes /clients/new through unchanged', () {
      expect(companySafeLocation('/clients/new', _testRoots), '/clients/new');
    });

    test('strips /clients/<id> back to /clients', () {
      expect(companySafeLocation('/clients/abc123', _testRoots), '/clients');
    });

    test('strips /clients/<id>/edit back to /clients', () {
      expect(
        companySafeLocation('/clients/abc123/edit', _testRoots),
        '/clients',
      );
    });

    test('passes /settings/company_details through unchanged', () {
      expect(
        companySafeLocation('/settings/company_details', _testRoots),
        '/settings/company_details',
      );
    });

    test('passes deep settings sub-routes through unchanged', () {
      expect(
        companySafeLocation('/settings/company_details/address', _testRoots),
        '/settings/company_details/address',
      );
    });

    test('preserves query string on safe routes', () {
      expect(
        companySafeLocation('/clients?filter=active', _testRoots),
        '/clients?filter=active',
      );
    });

    test('falls back to /clients for empty input', () {
      expect(companySafeLocation('', _testRoots), '/clients');
    });

    test('falls back to /clients for garbage input', () {
      // `Uri.tryParse` accepts most strings; an empty path is the only
      // structural failure we treat as garbage.
      expect(companySafeLocation('http://', _testRoots), '/clients');
    });
  });

  group('isCompanySetupRequired', () {
    test('false when there is no session', () {
      expect(isCompanySetupRequired(null), isFalse);
    });

    test('true when displayName is empty', () {
      final session = _sessionWith(
        _company(permissions: '', name: '', displayName: ''),
      );
      expect(isCompanySetupRequired(session), isTrue);
    });

    test('true when displayName is the server seed "Untitled Company"', () {
      final session = _sessionWith(
        _company(permissions: '', name: '', displayName: 'Untitled Company'),
      );
      expect(isCompanySetupRequired(session), isTrue);
    });

    test('true when displayName resolves to bare "Untitled" fallback '
        '(every name source empty)', () {
      // `companyDisplayName` returns "Untitled" only when settings.name,
      // displayName, and the row\'s name are all empty.
      final session = _sessionWith(
        _company(permissions: '', name: '', displayName: 'Untitled'),
      );
      expect(isCompanySetupRequired(session), isTrue);
    });

    test('false when user genuinely named the company "Untitled" '
        '(row name column is non-empty)', () {
      // Real-life edge case: the resolver still surfaces the user-typed
      // value via displayName, but the row\'s name column is also
      // "Untitled" — that\'s our signal that the user set this, not a
      // fallback.
      final session = _sessionWith(
        _company(permissions: '', name: 'Untitled', displayName: 'Untitled'),
      );
      expect(isCompanySetupRequired(session), isFalse);
    });

    test('false when company has a real name', () {
      final session = _sessionWith(
        _company(permissions: '', name: 'Acme', displayName: 'Acme Co'),
      );
      expect(isCompanySetupRequired(session), isFalse);
    });
  });

  group('entityRecordPath (row-click target)', () {
    test('row-click always opens the view/detail screen', () {
      expect(
        entityRecordPath(
          routePath: '/invoices',
          id: 'inv1',
          hasDetailScreen: true,
        ),
        '/invoices/inv1',
      );
    });

    test('no detail screen falls back to edit (never a dead route)', () {
      expect(
        entityRecordPath(
          routePath: '/settings/company_gateways',
          id: 'g1',
          hasDetailScreen: false,
        ),
        '/settings/company_gateways/g1/edit',
      );
    });

    test('settings routePath is preserved verbatim', () {
      expect(
        entityRecordPath(
          routePath: '/settings/expense_categories',
          id: 'c1',
          hasDetailScreen: true,
        ),
        '/settings/expense_categories/c1',
      );
    });
  });

  group('disabledEntityRoots', () {
    test('all modules on → nothing disabled', () {
      const allOn = 4096 | 8; // invoices + tasks
      expect(disabledEntityRoots(_registry(), allOn), isEmpty);
    });

    test('disabled module yields its root; client stays always-on', () {
      const tasksOnly = 8;
      final roots = disabledEntityRoots(_registry(), tasksOnly).toSet();
      // invoices off → /invoices disabled; tasks on, client always-on.
      expect(roots, contains('/invoices'));
      expect(roots, isNot(contains('/tasks')));
      expect(roots, isNot(contains('/clients')));
    });

    test('settings-only (SidebarSection.none) entities never appear', () {
      // credits=2 only: non-zero, invoices+tasks both off.
      final roots = disabledEntityRoots(_registry(), 2).toSet();
      expect(roots, isNot(contains('/settings/company_gateways')));
      expect(roots, containsAll(['/invoices', '/tasks']));
    });

    test('all-off mask (0) disables every module root', () {
      // 0 = every module switched off; all module-gated roots are disabled
      // while always-on roots (clients) stay reachable.
      final roots = disabledEntityRoots(_registry(), 0).toSet();
      expect(roots, contains('/invoices'));
      expect(roots, contains('/tasks'));
      expect(roots, isNot(contains('/clients')));
    });
  });
}
