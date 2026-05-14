/// Boot, redirect, and login smoke tests.
///
/// Each scenario exercises the real `InvoiceNinjaApp` with an in-memory
/// database + token storage. A `MockClient` is supplied throughout so the
/// app's background refresh never reaches the real network.
///
/// **Do not run these locally.** They take over the foreground app and
/// interrupt the user's session — see CLAUDE.md "Integration tests". They
/// run in GitHub CI.
library;

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/biometric_service.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/main.dart';
import 'package:admin/ui/features/auth/views/lock_screen.dart';
import 'package:admin/ui/features/auth/views/login_screen.dart';
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/dashboard/views/dashboard_screen.dart';

/// Always-cancels biometric stand-in so the integration-test driver never
/// hangs waiting on a real platform prompt. The lock screen kicks off
/// `unlock()` from `addPostFrameCallback`, so we just need the call to
/// resolve quickly with `false`.
class _AlwaysCancelBiometric implements BiometricService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate({required String reason}) async => false;
}

/// Suppresses every outbound request with a 500. Used by scenarios that
/// don't care about the network — `AuthRepository.restore()` fires a
/// best-effort `_refreshSessionQuietly()` after restore, and we don't want
/// it to reach the real internet from CI.
http.Client _silentNetwork() => MockClient((_) async => http.Response('', 500));

/// Seed Drift + token storage so `AuthRepository.restore()` finds a complete
/// session. `permissions` is a comma-separated string; with `isAdmin: false`
/// and `isOwner: false` it's the only thing that gates `view_dashboard`.
Future<({AppDatabase db, InMemoryTokenStorage storage})> _seedSession({
  required String permissions,
  bool isAdmin = false,
  bool isOwner = false,
  bool biometricEnabled = false,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  await db.companiesDao.upsertAccount(
    AccountsCompanion.insert(
      id: 'acct_1',
      email: '',
      plan: 'pro',
      numTrialDays: 14,
      updatedAt: nowMs,
    ),
  );
  await db.companiesDao.upsertAll([
    CompaniesCompanion.insert(
      id: 'co_a',
      name: 'Acme',
      settings: '{}',
      permissions: permissions,
      accountId: 'acct_1',
      token: 'tok_a',
      isOwner: Value(isOwner),
      isAdmin: Value(isAdmin),
      updatedAt: nowMs,
    ),
  ]);
  final storage = InMemoryTokenStorage();
  await storage.write('invoiceninja.tokens.v1', '{"co_a":"tok_a"}');
  await storage.write('invoiceninja.base_url.v1', 'https://test');
  await storage.write('invoiceninja.is_hosted.v1', 'false');
  await storage.write('invoiceninja.current_company.v1', 'co_a');
  if (biometricEnabled) {
    await storage.write('invoiceninja.biometric_enabled.v1', 'true');
  }
  return (db: db, storage: storage);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots into the login screen with no persisted creds', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final services = Services.build(
      db: db,
      tokenStorage: InMemoryTokenStorage(),
      httpClient: _silentNetwork(),
    );
    await services.auth.restore();

    await tester.pumpWidget(
      InvoiceNinjaApp(
        services: services,
        dbWasReset: false,
        initialLocation: '/login',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('login_submit')), findsOneWidget);
    // Email + password (and the optional OTP) — at least the first two.
    expect(find.byType(TextField), findsAtLeastNWidgets(2));
  });

  testWidgets(
    'app boots into the lock screen when biometric is enabled with a valid session',
    (tester) async {
      final seed = await _seedSession(
        permissions: '',
        isAdmin: true,
        isOwner: true,
        biometricEnabled: true,
      );
      addTearDown(seed.db.close);

      final services = Services.build(
        db: seed.db,
        tokenStorage: seed.storage,
        biometricService: _AlwaysCancelBiometric(),
        httpClient: _silentNetwork(),
      );
      await services.auth.restore();

      // Bypass `/login` initialLocation special-case: the router redirect
      // will move us to `/lock?from=…` because `requiresBiometricUnlock` is
      // true.
      await tester.pumpWidget(
        InvoiceNinjaApp(
          services: services,
          dbWasReset: false,
          initialLocation: '/dashboard',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('lock_unlock')), findsOneWidget);
      expect(find.byKey(const ValueKey('lock_sign_out')), findsOneWidget);
    },
  );

  testWidgets('lock screen Sign Out returns to /login', (tester) async {
    final seed = await _seedSession(
      permissions: '',
      isAdmin: true,
      isOwner: true,
      biometricEnabled: true,
    );
    addTearDown(seed.db.close);

    final services = Services.build(
      db: seed.db,
      tokenStorage: seed.storage,
      biometricService: _AlwaysCancelBiometric(),
      httpClient: _silentNetwork(),
    );
    await services.auth.restore();

    await tester.pumpWidget(
      InvoiceNinjaApp(
        services: services,
        dbWasReset: false,
        initialLocation: '/dashboard',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lock_sign_out')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'authenticated boot lands on /dashboard when company can view dashboard',
    (tester) async {
      final seed = await _seedSession(
        permissions: '',
        isAdmin: true,
        isOwner: true,
      );
      addTearDown(seed.db.close);

      final services = Services.build(
        db: seed.db,
        tokenStorage: seed.storage,
        httpClient: _silentNetwork(),
      );
      await services.auth.restore();

      await tester.pumpWidget(
        InvoiceNinjaApp(
          services: services,
          dbWasReset: false,
          initialLocation: '/dashboard',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    },
  );

  testWidgets(
    'authenticated boot lands on /clients when view_dashboard is denied',
    (tester) async {
      // Plain user (not admin, not owner) with permissions that don't
      // include `view_dashboard`. defaultPostLoginRoute() should fall
      // through to /clients.
      final seed = await _seedSession(permissions: 'view_client,edit_client');
      addTearDown(seed.db.close);

      final services = Services.build(
        db: seed.db,
        tokenStorage: seed.storage,
        httpClient: _silentNetwork(),
      );
      await services.auth.restore();

      // Land on the dashboard URL on purpose: the router's redirect should
      // bounce us to /clients because the company lacks view_dashboard.
      await tester.pumpWidget(
        InvoiceNinjaApp(
          services: services,
          dbWasReset: false,
          initialLocation: '/dashboard',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClientListScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    },
  );

  testWidgets('login submit + refresh land on /dashboard', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Smallest envelope that satisfies AuthRepository._persistAndActivate.
    // Mirrors the shape used by test/data/repositories/auth_repository_test
    // _envelope() — kept inline here so the wire format is visible at the
    // call site.
    final envelope = jsonEncode({
      'data': [
        {
          'is_admin': true,
          'is_owner': true,
          'permissions': '',
          'permissions_updated_at': 0,
          'company': {'id': 'co_a', 'name': 'Acme', 'settings': {}},
          'token': {'token': 'tok_a'},
          'account': {
            'id': 'acct_1',
            'default_company_id': 'co_a',
            'plan': 'pro',
            'num_trial_days': 14,
          },
          'settings': <String, dynamic>{},
          'user': {'id': 'u_1'},
        },
      ],
    });

    final mockClient = MockClient((req) async {
      if (req.url.path == '/api/v1/login') {
        return http.Response(
          envelope,
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (req.url.path == '/api/v1/refresh') {
        return http.Response(
          envelope,
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      return http.Response('not stubbed: ${req.url}', 500);
    });

    final services = Services.build(
      db: db,
      tokenStorage: InMemoryTokenStorage(),
      httpClient: mockClient,
    );
    await services.auth.restore();

    await tester.pumpWidget(
      InvoiceNinjaApp(
        services: services,
        dbWasReset: false,
        initialLocation: '/login',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // The login form has email + password + OTP fields in order. Enter
    // creds into the first two; the OTP field is optional and stays blank.
    final fields = find.byType(TextField);
    expect(fields, findsAtLeastNWidgets(2));
    await tester.enterText(fields.at(0), 'me@example.com');
    await tester.enterText(fields.at(1), 'hunter2');
    await tester.tap(find.byKey(const ValueKey('login_submit')));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
