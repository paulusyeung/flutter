import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/api/tax_config_api_model.dart';
import 'package:admin/ui/features/settings/widgets/subregion_edit_dialog.dart';

import '../../../../_localization_helper.dart';

/// Pumps `MaterialApp` + a button that opens [SubregionEditDialog] with the
/// supplied args. Returns the captured pop result (or null on cancel).
Future<TaxSubregionApi?> _open(
  WidgetTester tester, {
  required TaxSubregionApi initial,
  Map<String, List<String>>? fieldErrors,
}) async {
  TaxSubregionApi? captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                captured = await SubregionEditDialog.show(
                  context,
                  subregionKey: 'DE',
                  initial: initial,
                  fieldErrors: fieldErrors,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  // The caller drives the dialog from here; the closure captures `captured`
  // for inspection after Save/Cancel.
  return captured;
}

/// Resolve the [InputDecoration] of a [TextField] keyed by its visible label.
InputDecoration _decorationForLabel(WidgetTester tester, String label) {
  final fields = tester.widgetList<TextField>(find.byType(TextField));
  for (final f in fields) {
    if (f.decoration?.labelText == label) return f.decoration!;
  }
  fail('no TextField with labelText "$label" found');
}

void main() {
  const initial = TaxSubregionApi(
    taxName: 'VAT',
    taxRate: 19.0,
    reducedTaxRate: 7.0,
    vatNumber: 'DE123',
    applyTax: true,
  );

  group('SubregionEditDialog', () {
    testWidgets(
      'renders no errorText under any field when fieldErrors is null',
      (tester) async {
        await _open(tester, initial: initial);
        for (final label in const [
          'Tax Name',
          'Tax Rate',
          'Reduced Rate',
          'VAT Number',
        ]) {
          expect(_decorationForLabel(tester, label).errorText, isNull);
        }
      },
    );

    testWidgets('surfaces the right errorText under each scoped field', (
      tester,
    ) async {
      await _open(
        tester,
        initial: initial,
        fieldErrors: const {
          'tax_name': ['Name too long'],
          'tax_rate': ['Must be a number'],
        },
      );
      expect(
        _decorationForLabel(tester, 'Tax Name').errorText,
        'Name too long',
      );
      expect(
        _decorationForLabel(tester, 'Tax Rate').errorText,
        'Must be a number',
      );
      // Untouched fields stay clean.
      expect(_decorationForLabel(tester, 'Reduced Rate').errorText, isNull);
      expect(_decorationForLabel(tester, 'VAT Number').errorText, isNull);
    });

    testWidgets(
      'Save still pops with the edited subregion even when errors are present',
      (tester) async {
        TaxSubregionApi? captured;
        // Mirror _open so we can inspect `captured` post-pop.
        await tester.pumpWidget(
          MaterialApp(
            theme: buildInTheme(InTheme.light),
            localizationsDelegates: kTestLocalizationsDelegates,
            supportedLocales: kTestSupportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      captured = await SubregionEditDialog.show(
                        context,
                        subregionKey: 'DE',
                        initial: initial,
                        fieldErrors: const {
                          'tax_name': ['Name too long'],
                        },
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        // The user fixes the name; the server's authoritative validator
        // re-runs on the next page-level Save. Save in the dialog just
        // returns the edits — it doesn't block on existing errors.
        await tester.enterText(
          find.byType(TextField).first,
          'VAT (corrected)',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        expect(captured, isNotNull);
        expect(captured!.taxName, 'VAT (corrected)');
        expect(captured!.taxRate, 19.0);
      },
    );
  });
}
