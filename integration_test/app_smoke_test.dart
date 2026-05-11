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

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/main.dart';
import 'package:admin/ui/features/auth/views/login_screen.dart';

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
}
