import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/features/billing_shared/line_item_editor/product_stock_label.dart';

import '../../../_localization_helper.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('productStockText', () {
    test('brackets the quantity — including zero (never blank)', () {
      expect(productStockText(Decimal.zero), '[0]');
      expect(productStockText(Decimal.fromInt(12)), '[12]');
      expect(productStockText(Decimal.parse('12.5')), '[12.5]');
    });
  });

  group('isOutOfStock', () {
    test('true at or below zero', () {
      expect(isOutOfStock(Decimal.zero), isTrue);
      expect(isOutOfStock(Decimal.fromInt(-3)), isTrue);
    });

    test('false when positive', () {
      expect(isOutOfStock(Decimal.fromInt(1)), isFalse);
      expect(isOutOfStock(Decimal.parse('0.5')), isFalse);
    });
  });

  group('ProductStockLabel', () {
    testWidgets('renders the muted count when in stock', (tester) async {
      await _pump(
        tester,
        ProductStockLabel(quantity: Decimal.fromInt(12), show: true),
      );
      expect(find.text('[12]'), findsOneWidget);
      final text = tester.widget<Text>(find.text('[12]'));
      expect(text.style?.color, InTheme.light.ink3);
    });

    testWidgets('renders the count in overdue red when out of stock', (
      tester,
    ) async {
      await _pump(
        tester,
        ProductStockLabel(quantity: Decimal.zero, show: true),
      );
      expect(find.text('[0]'), findsOneWidget);
      final text = tester.widget<Text>(find.text('[0]'));
      expect(text.style?.color, InTheme.light.overdue);
    });

    testWidgets('renders nothing when show is false', (tester) async {
      await _pump(
        tester,
        ProductStockLabel(quantity: Decimal.fromInt(5), show: false),
      );
      expect(find.text('[5]'), findsNothing);
      expect(find.byType(Text), findsNothing);
    });
  });
}
