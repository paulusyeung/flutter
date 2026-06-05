import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/datetime_format.dart';
import 'package:admin/ui/core/widgets/formatter_scope.dart';
import 'package:admin/ui/features/credits/view_models/credit_edit_view_model.dart';
import 'package:admin/ui/features/credits/widgets/credit_list_tile.dart';
import 'package:admin/utils/formatting.dart';

import '../../../../_localization_helper.dart';

/// The narrow (mobile) credit tile must format the amount through `Formatter`
/// (currency symbol + precision via the per-company cascade), not a bare
/// locale `NumberFormat`. Guards the pre-launch fix where the credit/quote
/// tiles rendered a symbol-less decimal while the invoice tile did not.
Currency _usd() => Currency(
  id: '1',
  name: 'USD',
  code: 'USD',
  symbol: r'$',
  precision: 2,
  thousandSeparator: ',',
  decimalSeparator: '.',
  swapCurrencySymbol: false,
  exchangeRate: Decimal.one,
);

final _formatter = Formatter(
  settings: CompanyFormatSettings.fallback, // currencyId '1' (USD), country 840
  currencies: {'1': _usd()},
  countries: const {
    '840': Country(
      id: '840',
      name: 'United States',
      iso2: 'US',
      iso3: 'USA',
      swapCurrencySymbol: false,
      thousandSeparator: '',
      decimalSeparator: '',
      swapPostalCode: false,
    ),
  },
  dateFormats: const {'5': DatetimeFormat(id: '5', format: 'MMM d, yyyy')},
);

Future<void> _pumpTile(WidgetTester tester, {required bool withScope}) async {
  final tile = CreditListTile(
    credit: emptyCredit().copyWith(amount: Decimal.parse('1234.56')),
    columns: const [],
    onTap: () {},
    wide: false,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: withScope
            ? FormatterScope(formatter: _formatter, child: tile)
            : tile,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('narrow tile formats the amount through Formatter (currency '
      'symbol present)', (tester) async {
    await _pumpTile(tester, withScope: true);
    // Money path: rendered with the company-default USD symbol.
    expect(find.textContaining(r'$'), findsOneWidget);
    expect(find.textContaining('1,234.56'), findsOneWidget);
  });

  testWidgets(
    'narrow tile falls back to locale-only without a FormatterScope',
    (tester) async {
      await _pumpTile(tester, withScope: false);
      // No scope → bare grouped decimal, no currency symbol.
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.textContaining('1,234.56'), findsOneWidget);
    },
  );
}
