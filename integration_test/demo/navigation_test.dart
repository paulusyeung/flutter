/// Live demo coverage — navigation, lists & detail.
///
/// Real page-by-page list loads, a client detail open, the full primary-
/// entity list tour, and the reports screen — all against
/// `https://demo.invoiceninja.com`. Shared infra is in
/// `../support/demo_harness.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/clients/views/client_detail_screen.dart';
import 'package:admin/ui/features/clients/views/client_list_screen.dart';
import 'package:admin/ui/features/clients/widgets/client_list_tile.dart';
import 'package:admin/ui/features/expenses/views/expense_detail_screen.dart';
import 'package:admin/ui/features/expenses/views/expense_list_screen.dart';
import 'package:admin/ui/features/expenses/widgets/expense_list_tile.dart';
import 'package:admin/ui/features/invoices/views/invoice_detail_screen.dart';
import 'package:admin/ui/features/invoices/views/invoice_list_screen.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_list_tile.dart';
import 'package:admin/ui/features/payments/views/payment_detail_screen.dart';
import 'package:admin/ui/features/payments/views/payment_list_screen.dart';
import 'package:admin/ui/features/payments/widgets/payment_list_tile.dart';
import 'package:admin/ui/features/products/views/product_detail_screen.dart';
import 'package:admin/ui/features/products/views/product_list_screen.dart';
import 'package:admin/ui/features/products/widgets/product_list_tile.dart';
import 'package:admin/ui/features/projects/views/project_detail_screen.dart';
import 'package:admin/ui/features/projects/views/project_list_screen.dart';
import 'package:admin/ui/features/projects/widgets/project_list_tile.dart';
import 'package:admin/ui/features/quotes/views/quote_detail_screen.dart';
import 'package:admin/ui/features/quotes/views/quote_list_screen.dart';
import 'package:admin/ui/features/quotes/widgets/quote_list_tile.dart';
import 'package:admin/ui/features/reports/views/reports_screen.dart';
import 'package:admin/ui/features/tasks/views/task_detail_screen.dart';
import 'package:admin/ui/features/tasks/views/task_list_screen.dart';
import 'package:admin/ui/features/tasks/widgets/task_list_tile.dart';
import 'package:admin/ui/features/vendors/views/vendor_detail_screen.dart';
import 'package:admin/ui/features/vendors/views/vendor_list_screen.dart';
import 'package:admin/ui/features/vendors/widgets/vendor_list_tile.dart';

import '../support/demo_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerDemoReachabilityProbe();

  testWidgets('clients list loads real rows from the demo server', (
    tester,
  ) async {
    if (skipIfUnreachable()) return;

    await bootLoggedIn(tester, initialLocation: '/clients');
    await pumpUntilFound(tester, find.byType(ClientListScreen));
    expect(find.byType(ClientListScreen), findsOneWidget);

    // The demo dataset is always seeded with clients — page one should
    // produce at least one real tile after the live fetch resolves.
    await pumpUntilFound(tester, find.byType(ClientListTile));
    expect(
      find.byType(ClientListTile),
      findsAtLeastNWidgets(1),
      reason: 'demo server should return at least one client',
    );
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('opening a client shows the detail screen with live data', (
    tester,
  ) async {
    if (skipIfUnreachable()) return;

    await bootLoggedIn(tester, initialLocation: '/clients');
    await pumpUntilFound(tester, find.byType(ClientListTile));
    expect(find.byType(ClientListTile), findsAtLeastNWidgets(1));

    await tester.tap(find.byType(ClientListTile).first);
    await pumpUntilFound(tester, find.byType(ClientDetailScreen));
    expect(find.byType(ClientDetailScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ClientDetailScreen),
        matching: find.byType(ErrorView),
      ),
      findsNothing,
    );
  });

  testWidgets('every primary entity list loads from the demo server', (
    tester,
  ) async {
    if (skipIfUnreachable()) return;

    // One login, then tour each list through the real router. Each route
    // triggers a live page-by-page fetch; we assert the screen mounted and
    // no ErrorView surfaced.
    await bootLoggedIn(tester, initialLocation: '/clients');
    await pumpUntilFound(tester, find.byType(ClientListScreen));

    final tour = <({String route, Type screen})>[
      (route: '/products', screen: ProductListScreen),
      (route: '/invoices', screen: InvoiceListScreen),
      (route: '/quotes', screen: QuoteListScreen),
      (route: '/payments', screen: PaymentListScreen),
      (route: '/expenses', screen: ExpenseListScreen),
      (route: '/tasks', screen: TaskListScreen),
      (route: '/projects', screen: ProjectListScreen),
      (route: '/vendors', screen: VendorListScreen),
    ];
    for (final stop in tour) {
      await goAndExpect(tester, route: stop.route, screenType: stop.screen);
    }
  });

  testWidgets('reports screen mounts post-login', (tester) async {
    if (skipIfUnreachable()) return;

    await bootLoggedIn(tester, initialLocation: '/reports');
    await pumpUntilFound(tester, find.byType(ReportsScreen));
    expect(find.byType(ReportsScreen), findsOneWidget);
  });

  testWidgets('primary entity detail screens load from the demo server', (
    tester,
  ) async {
    if (skipIfUnreachable()) return;

    // One login, then open the first row of each list and confirm the
    // detail screen renders live data without an ErrorView. Single app
    // launch — no extra macOS relaunch.
    await bootLoggedIn(tester, initialLocation: '/clients');
    await pumpUntilFound(tester, find.byType(ClientListScreen));

    final cases = <({String route, Type tile, Type detail})>[
      (route: '/products', tile: ProductListTile, detail: ProductDetailScreen),
      (route: '/invoices', tile: InvoiceListTile, detail: InvoiceDetailScreen),
      (route: '/quotes', tile: QuoteListTile, detail: QuoteDetailScreen),
      (route: '/payments', tile: PaymentListTile, detail: PaymentDetailScreen),
      (route: '/expenses', tile: ExpenseListTile, detail: ExpenseDetailScreen),
      (route: '/tasks', tile: TaskListTile, detail: TaskDetailScreen),
      (route: '/projects', tile: ProjectListTile, detail: ProjectDetailScreen),
      (route: '/vendors', tile: VendorListTile, detail: VendorDetailScreen),
    ];
    for (final c in cases) {
      await openFirstRowDetail(
        tester,
        listRoute: c.route,
        listTileType: c.tile,
        detailType: c.detail,
      );
    }
  });

  testWidgets('clients list search filters rows against live data', (
    tester,
  ) async {
    if (skipIfUnreachable()) return;

    await bootLoggedIn(tester, initialLocation: '/clients');
    await pumpUntilFound(tester, find.byType(ClientListTile));
    final before = find.byType(ClientListTile).evaluate().length;
    expect(before, greaterThan(0));

    // The list scaffold's token search is the only TextField on a plain
    // list screen. Typing a query the dataset is very unlikely to match
    // broadly must narrow (or empty) the list — never grow it — and must
    // not crash the screen.
    final searchField = find
        .descendant(
          of: find.byType(ClientListScreen),
          matching: find.byType(TextField),
        )
        .first;
    await tester.enterText(searchField, 'zqxjv-no-such-client');
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(ClientListScreen), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    expect(
      find.byType(ClientListTile).evaluate().length,
      lessThanOrEqualTo(before),
      reason: 'search must filter (never grow) the live list',
    );
  });
}
