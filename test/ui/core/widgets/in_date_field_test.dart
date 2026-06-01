import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/models/value/datetime_format.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/utils/formatting.dart';

import '../../../_localization_helper.dart';

const _settings = CompanyFormatSettings(
  currencyId: '1',
  countryId: '840',
  dateFormatId: 'X',
  useCommaAsDecimalPlace: false,
  showCurrencyCode: false,
  enableMilitaryTime: false,
  locale: '',
);

final _formatter = Formatter(
  settings: _settings,
  currencies: const {},
  countries: const {},
  dateFormats: const {'X': DatetimeFormat(id: 'X', format: 'd/MMM/yyyy')},
);

Future<void> _pump(WidgetTester tester, {Formatter? formatter}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: InDateField(
            value: DateTime(2026, 5, 14),
            formatter: formatter,
            onChanged: (_) {},
            labelText: 'Date',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the company-formatted date when a Formatter is passed', (
    tester,
  ) async {
    await _pump(tester, formatter: _formatter);
    expect(find.text('14/May/2026'), findsOneWidget);
    expect(find.text('2026-05-14'), findsNothing);
  });

  testWidgets('falls back to ISO when no Formatter is passed', (tester) async {
    await _pump(tester);
    expect(find.text('2026-05-14'), findsOneWidget);
  });
}
