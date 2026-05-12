/// Boot-and-login-screen smoke test.
///
/// Exercises the real `InvoiceNinjaApp` with an in-memory database + token
/// storage. With no persisted credentials the router lands on `/login`, so
/// rendering the submit button proves DI, routing, theme, and localization
/// are wired correctly end-to-end.
///
/// Run on device:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_smoke_test.dart
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/biometric_service.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/main.dart';
import 'package:admin/ui/features/auth/views/lock_screen.dart';
import 'package:admin/ui/features/auth/views/login_screen.dart';

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
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // Seed Drift + storage so AuthRepository.restore() finds a complete
      // session, then flips the biometric gate.
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
          permissions: '',
          accountId: 'acct_1',
          token: 'tok_a',
          isOwner: const Value(true),
          isAdmin: const Value(true),
          updatedAt: nowMs,
        ),
      ]);
      final storage = InMemoryTokenStorage();
      await storage.write('invoiceninja.tokens.v1', '{"co_a":"tok_a"}');
      await storage.write('invoiceninja.base_url.v1', 'https://test');
      await storage.write('invoiceninja.is_hosted.v1', 'false');
      await storage.write('invoiceninja.current_company.v1', 'co_a');
      await storage.write('invoiceninja.biometric_enabled.v1', 'true');

      final services = Services.build(
        db: db,
        tokenStorage: storage,
        biometricService: _AlwaysCancelBiometric(),
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
}
