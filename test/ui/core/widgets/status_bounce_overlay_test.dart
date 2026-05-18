import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/widgets/status_bounce_overlay.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_status_pill.dart';

import '../../../_localization_helper.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('StatusBounceOverlay', () {
    testWidgets('renders the alert badge only when hasBounce is true', (
      tester,
    ) async {
      await _pump(
        tester,
        const StatusBounceOverlay(
          hasBounce: true,
          child: Text('Sent'),
        ),
      );
      expect(find.text('Sent'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });

    testWidgets('passes the child straight through when hasBounce is false', (
      tester,
    ) async {
      await _pump(
        tester,
        const StatusBounceOverlay(
          hasBounce: false,
          child: Text('Sent'),
        ),
      );
      expect(find.text('Sent'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsNothing);
    });
  });

  group('InvoiceStatusPill', () {
    testWidgets('overlays the bounce badge when hasBounce is set', (
      tester,
    ) async {
      await _pump(
        tester,
        const InvoiceStatusPill(statusId: '2', hasBounce: true),
      );
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });

    testWidgets('no badge by default', (tester) async {
      await _pump(tester, const InvoiceStatusPill(statusId: '2'));
      expect(find.byIcon(Icons.priority_high), findsNothing);
    });
  });
}
