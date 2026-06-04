import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/models/value/datetime_format.dart';
import 'package:admin/ui/core/detail/custom_field_detail_rows.dart';
import 'package:admin/utils/formatting.dart';

final _formatter = Formatter(
  settings: const CompanyFormatSettings(
    currencyId: '1',
    countryId: '840',
    dateFormatId: 'X',
    useCommaAsDecimalPlace: false,
    showCurrencyCode: false,
    enableMilitaryTime: false,
    locale: '',
  ),
  currencies: const {},
  countries: const {},
  dateFormats: const {'X': DatetimeFormat(id: 'X', format: 'd/MMM/yyyy')},
);

const _company = Company(
  customFields: {
    'task1': 'Region|North,South',
    'task2': 'Active|switch',
    'task3': 'Due|date',
    // task4 intentionally unconfigured
  },
);

List<({String label, String value})> _rows(
  List<String> values, {
  Formatter? formatter,
}) => customFieldDetailRows(
  company: _company,
  prefix: 'task',
  values: values,
  yes: 'Yes',
  no: 'No',
  formatter: formatter,
);

void main() {
  test('configured slots with values render label + display', () {
    final rows = _rows(['North', 'yes', '', '']);
    expect(rows.length, 2);
    expect(rows[0].label, 'Region');
    expect(rows[0].value, 'North');
    expect(rows[1].label, 'Active');
    expect(rows[1].value, 'Yes'); // switch → localized
  });

  test('unconfigured slot is skipped even with a value (orphan)', () {
    // task4 has no configured label — its value must not produce a row.
    expect(_rows(['', '', '', 'orphan']), isEmpty);
  });

  test('empty values are skipped', () {
    expect(_rows(['', '', '', '']), isEmpty);
  });

  test('date formats with a formatter', () {
    final rows = _rows(['', '', '2026-05-14', ''], formatter: _formatter);
    expect(rows.length, 1);
    expect(rows[0].label, 'Due');
    expect(rows[0].value, '14/May/2026');
  });

  test('garbage date with a formatter is skipped (skip-blank)', () {
    expect(_rows(['', '', 'not-a-date', ''], formatter: _formatter), isEmpty);
  });

  test('null company → empty', () {
    expect(
      customFieldDetailRows(
        company: null,
        prefix: 'task',
        values: const ['x', 'x', 'x', 'x'],
        yes: 'Yes',
        no: 'No',
      ),
      isEmpty,
    );
  });
}
