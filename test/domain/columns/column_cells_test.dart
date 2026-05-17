import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/value/datetime_format.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/ui/core/widgets/formatter_scope.dart';
import 'package:admin/utils/formatting.dart';

/// 6B — list-table money cells render through `Formatter` (per-client →
/// company currency cascade) when a `FormatterScope` is present, and fall
/// back to locale-only formatting when it isn't. Zero stays an em-dash.
Currency _cur(String id, String code, String symbol) => Currency(
  id: id,
  name: code,
  code: code,
  symbol: symbol,
  precision: 2,
  thousandSeparator: ',',
  decimalSeparator: '.',
  swapCurrencySymbol: false,
  exchangeRate: Decimal.one,
);

final _formatter = Formatter(
  settings: CompanyFormatSettings.fallback, // currencyId '1', countryId '840'
  currencies: {'1': _cur('1', 'USD', r'$'), '3': _cur('3', 'EUR', '€')},
  countries: {
    '840': const Country(
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

Future<String> _render(
  WidgetTester tester,
  Widget Function(BuildContext) build, {
  bool withScope = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final child = Builder(builder: build);
            return withScope
                ? FormatterScope(formatter: _formatter, child: child)
                : child;
          },
        ),
      ),
    ),
  );
  return tester.widget<Text>(find.byType(Text)).data!;
}

void main() {
  testWidgets('zero renders an em-dash (with or without a scope)', (
    tester,
  ) async {
    expect(
      await _render(tester, (c) => cellMoney(Decimal.zero, c)),
      '—',
    );
    expect(
      await _render(
        tester,
        (c) => cellMoney(Decimal.zero, c),
        withScope: false,
      ),
      '—',
    );
  });

  testWidgets('with a scope, a client row uses its clientCurrencyId', (
    tester,
  ) async {
    final text = await _render(
      tester,
      (c) => cellMoney(
        Decimal.parse('1234.5'),
        c,
        clientCurrencyId: '3', // EUR
      ),
    );
    expect(text, contains('€'));
    expect(text, isNot(contains(r'$')));
  });

  testWidgets('with a scope, a billing-doc row (no currency) falls back to '
      'the company default currency', (tester) async {
    final text = await _render(
      tester,
      (c) => cellMoney(Decimal.parse('1234.5'), c), // no currency arg
    );
    expect(text, contains(r'$')); // company default = USD ('1')
  });

  testWidgets('without a scope, falls back to locale-only NumberFormat', (
    tester,
  ) async {
    final text = await _render(
      tester,
      (c) => cellMoney(Decimal.parse('1234.5'), c),
      withScope: false,
    );
    expect(text, '1,234.50');
    expect(text, isNot(contains(r'$')));
    expect(text, isNot(contains('€')));
  });
}
