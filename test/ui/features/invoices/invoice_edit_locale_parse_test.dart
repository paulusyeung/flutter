import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/data/repositories/settings_repository.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_edit_view_model.dart';

class _FakeInvoicesApi implements InvoicesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Regression: the invoice-level numeric setters parsed raw user input with
/// `Decimal.tryParse`, which returns null for `"19,5"` — a comma-decimal-locale
/// user's tax rate / surcharge / discount silently became 0. They must route
/// through `parseDecimal(..., useCommaAsDecimalPlace:)`.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  InvoiceEditViewModel vm({required bool useComma}) => InvoiceEditViewModel(
    repo: InvoiceRepository(
      db: db,
      api: _FakeInvoicesApi(),
      settings: SettingsRepository(db: db),
    ),
    companyId: 'co',
    clientRequiredMessage: '',
    crossClientLineItemsMessage: '',
    partialInvalidMessage: '',
    useCommaAsDecimalPlace: useComma,
  );

  final d195 = Decimal.parse('19.5');
  final d150 = Decimal.parse('1.5');

  test('comma locale: tax / surcharge / discount / partial / rate parse', () {
    final m = vm(useComma: true);
    m.setTaxRate1('19,5');
    expect(m.draft.taxRate1, d195);
    m.setCustomSurcharge1('1,50');
    expect(m.draft.customSurcharge1, d150);
    m.setDiscount('1,5', isAmount: true);
    expect(m.draft.discount, d150);
    expect(m.draft.isAmountDiscount, isTrue);
    m.setPartial('1,5');
    expect(m.draft.partial, d150);
    m.setExchangeRate('1,5');
    expect(m.draft.exchangeRate, d150);
  });

  test('comma locale: empty exchange rate falls back to 1, not 0', () {
    final m = vm(useComma: true);
    m.setExchangeRate('');
    expect(m.draft.exchangeRate, Decimal.one);
  });

  test('dot locale: plain decimals still parse', () {
    final m = vm(useComma: false);
    m.setTaxRate1('19.5');
    expect(m.draft.taxRate1, d195);
  });
}
