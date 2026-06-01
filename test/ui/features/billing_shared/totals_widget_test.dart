import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/domain/billing/totals_calculator.dart';
import 'package:admin/ui/features/billing_shared/totals_widget.dart';

import '../../../_localization_helper.dart';

void main() {
  final totals = BillingTotalsResult(
    subtotal: Decimal.parse('100'),
    total: Decimal.parse('118'),
    taxAmount: Decimal.parse('18'),
    taxBreakdown: {'VAT': Decimal.parse('18')},
  );

  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(InTheme.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'slim mode renders only the total row — no subtotal/tax breakdown',
    (tester) async {
      await pump(tester, TotalsWidget(totals: totals, dense: true, slim: true));
      await tester.pump();

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Subtotal'), findsNothing);
      expect(find.text('VAT'), findsNothing);
    },
  );

  testWidgets('non-slim dense mode still renders the full breakdown', (
    tester,
  ) async {
    await pump(tester, TotalsWidget(totals: totals, dense: true));
    await tester.pump();

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('VAT'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });

  // The card chrome is the only BoxDecoration with a borderRadius
  // (InRadii.r3); per-row rules use a plain Border with no radius, so
  // keying on borderRadius isolates the outer card from row dividers.
  bool hasBorderedBox(WidgetTester tester) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(TotalsWidget),
          matching: find.byType(Container),
        ),
      )
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .any((d) => d.border != null && d.borderRadius != null);

  testWidgets(
    'bordered:false renders the rows with no card border decoration',
    (tester) async {
      await pump(tester, TotalsWidget(totals: totals, bordered: false));
      await tester.pump();

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(hasBorderedBox(tester), isFalse);
    },
  );

  testWidgets('default (bordered:true) keeps the card border decoration', (
    tester,
  ) async {
    await pump(tester, TotalsWidget(totals: totals));
    await tester.pump();
    expect(hasBorderedBox(tester), isTrue);
  });
}
