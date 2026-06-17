import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/recurring_invoices/widgets/increase_prices_dialog.dart';

import '../../../_localization_helper.dart';

/// The Increase Prices dialog must reject a no-op / empty percentage: a leading
/// `-` is already blocked by the input formatter, so the remaining gap was 0 /
/// empty, which previously could be submitted.
void main() {
  Widget host(void Function(String?) onResult, {bool useComma = false}) =>
      MaterialApp(
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => onResult(
                await showIncreasePricesDialog(
                  context,
                  useCommaAsDecimalPlace: useComma,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

  bool doneEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

  testWidgets('Done is disabled until a positive percentage is entered', (
    tester,
  ) async {
    await tester.pumpWidget(host((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(doneEnabled(tester), isFalse, reason: 'empty input');

    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    expect(doneEnabled(tester), isFalse, reason: 'zero is a no-op increase');

    await tester.enterText(find.byType(TextField), '5');
    await tester.pump();
    expect(doneEnabled(tester), isTrue, reason: 'positive percentage');

    // The server caps percentage_increase at 100 (BulkRecurringInvoiceRequest);
    // a client-side ceiling prevents N dead 422 outbox rows.
    await tester.enterText(find.byType(TextField), '150');
    await tester.pump();
    expect(doneEnabled(tester), isFalse, reason: '>100 exceeds server max');

    await tester.enterText(find.byType(TextField), '100');
    await tester.pump();
    expect(doneEnabled(tester), isTrue, reason: '100 is the inclusive max');
  });

  testWidgets('submitting returns the entered percentage', (tester) async {
    String? result = 'unset';
    await tester.pumpWidget(host((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '12.5');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(result, '12.5');
  });

  testWidgets('comma-locale: "5,5" returns "5.5", not "55"', (tester) async {
    String? result = 'unset';
    await tester.pumpWidget(host((r) => result = r, useComma: true));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '5,5');
    await tester.pump();
    expect(doneEnabled(tester), isTrue);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // The comma is the decimal separator; sending "55" would be a 10× increase.
    expect(result, '5.5');
  });
}
