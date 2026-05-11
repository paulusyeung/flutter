import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/company_settings_api_model.dart';

void main() {
  group('CompanySettingsApi mapping', () {
    test('fromJson + toJson round-trips a representative payload', () {
      // A subset modeled on a real /auth/me response — covers each field
      // type the model declares (String, int, double, bool, Map<List<...>>).
      const payload = '''
{
  "id": "Wpmbk5ezJn",
  "name": "Acme Inc",
  "company_logo": "https://cdn.invoiceninja.com/logo.png",
  "address1": "1 Main",
  "city": "Berlin",
  "country_id": "276",
  "vat_number": "DE123",
  "id_number": "REG-9",
  "classification": "company",
  "currency_id": "1",
  "language_id": "1",
  "timezone_id": "1",
  "tax_rate1": 19.0,
  "tax_name1": "VAT",
  "invoice_number_counter": 42,
  "counter_padding": 4,
  "auto_archive_invoice": false,
  "send_reminders": true,
  "use_comma_as_decimal_place": true,
  "invoice_terms": "Net 30",
  "purchase_order_terms": "POs settle in 14 days",
  "default_task_rate": 75.5,
  "pdf_variables": {
    "invoice_columns": ["item", "quantity", "cost"]
  }
}
''';
      final parsed = CompanySettingsApi.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );

      expect(parsed.name, 'Acme Inc');
      expect(parsed.taxRate1, 19.0);
      expect(parsed.invoiceNumberCounter, 42);
      expect(parsed.autoArchiveInvoice, false);
      expect(parsed.sendReminders, true);
      expect(parsed.useCommaAsDecimalPlace, true);
      expect(parsed.invoiceTerms, 'Net 30');
      expect(parsed.purchaseOrderTerms, 'POs settle in 14 days');
      expect(parsed.defaultTaskRate, 75.5);
      expect(parsed.pdfVariables?['invoice_columns'], [
        'item',
        'quantity',
        'cost',
      ]);

      // toJson strips nulls (`includeIfNull: false`) — the round-trip
      // therefore has only the keys we set, but every key we did set must
      // come back equal.
      final encoded = parsed.toJson();
      final reparsed = CompanySettingsApi.fromJson(encoded);
      expect(reparsed, parsed);
    });

    test('toJson omits null fields so cascade overrides are wire-honest', () {
      const partial = CompanySettingsApi(name: 'Acme', vatNumber: null);
      final encoded = partial.toJson();
      expect(encoded.containsKey('name'), isTrue);
      expect(encoded.containsKey('vat_number'), isFalse);
    });
  });
}
