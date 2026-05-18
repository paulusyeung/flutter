// Deep-link regression for the invoice-lock gate. A cold deep link to
// `/invoices/:id/edit` never goes through InvoiceActions.dispatch, so the
// gate lives in InvoiceEditScreen's fetchExisting closure. This boots the
// screen straight at the edit route for a sent invoice under
// `lock_invoices=when_sent` and asserts: the reason-specific dialog shows,
// and (no back stack) it navigates to the detail screen.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/services/connectivity_watcher.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/ui/features/invoices/views/invoice_edit_screen.dart';

import '../../../_localization_helper.dart';

void main() {
  testWidgets(
    'cold deep link to a locked invoice edit → dialog, then detail',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());

      await db.companiesDao.upsertAccount(
        AccountsCompanion.insert(
          id: 'acct',
          email: 'user@example.com',
          plan: 'pro',
          numTrialDays: 0,
          updatedAt: 0,
        ),
      );
      await db.companiesDao.upsertAll([
        CompaniesCompanion.insert(
          id: 'co',
          name: 'Acme',
          displayName: const Value('Acme'),
          settings: jsonEncode({'lock_invoices': 'when_sent'}),
          permissions: '',
          accountId: 'acct',
          token: 'tok',
          updatedAt: 0,
        ),
      ]);

      final storage = InMemoryTokenStorage();
      await storage.write('invoiceninja.tokens.v1', jsonEncode({'co': 'tok'}));
      await storage.write('invoiceninja.base_url.v1', 'https://example.com');
      await storage.write('invoiceninja.is_hosted.v1', 'true');
      await storage.write('invoiceninja.current_company.v1', 'co');

      final services = Services.build(
        db: db,
        tokenStorage: storage,
        connectivityWatcher: ConnectivityWatcher.fixed(online: false),
      );
      await services.auth.restore();
      services.refreshScheduler.stop();
      addTearDown(() async {
        services.refreshScheduler.dispose();
        await services.auth.dispose();
        await db.close();
      });

      // status_id 2 = sent → locked under when_sent.
      await services.invoices.applyUpdateResponse(
        companyId: 'co',
        serverResponse: const InvoiceApi(
          id: 'inv1',
          statusId: '2',
          updatedAt: 1700000000,
        ),
      );

      final router = GoRouter(
        initialLocation: '/invoices/inv1/edit',
        routes: [
          GoRoute(
            path: '/invoices/:id/edit',
            builder: (_, state) =>
                InvoiceEditScreen(existingId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/invoices/:id',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('DETAIL'))),
          ),
        ],
      );

      final theme = ThemeData.light().copyWith(
        extensions: <ThemeExtension<dynamic>>[InTheme.light],
        dividerColor: InTheme.light.border,
        scaffoldBackgroundColor: InTheme.light.bg,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: theme,
          supportedLocales: kTestSupportedLocales,
          localizationsDelegates: kTestLocalizationsDelegates,
          routerConfig: router,
          builder: (_, child) => Provider<Services>.value(
            value: services,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
      // Scaffold load (fetchExisting) + the post-frame dialog/nav.
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Sent invoices are locked'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      // No back stack on a cold deep link → landed on the detail route.
      expect(find.text('DETAIL'), findsOneWidget);
      expect(find.byType(InvoiceEditScreen), findsNothing);
    },
  );
}
