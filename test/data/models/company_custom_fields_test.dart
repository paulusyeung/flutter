import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';

void main() {
  group('CompanyCustomFields.customFieldLabel', () {
    test('returns the label half of a `Label|preset1,preset2` value', () {
      const company = Company(
        id: 'co',
        name: 'Acme',
        customFields: {'client1': 'Region|North,South,East,West'},
      );
      expect(company.customFieldLabel('client1'), 'Region');
    });

    test('returns the whole value when there is no pipe', () {
      const company = Company(
        id: 'co',
        name: 'Acme',
        customFields: {'client1': 'Region'},
      );
      expect(company.customFieldLabel('client1'), 'Region');
    });

    test('returns empty when the key is missing', () {
      const company = Company(
        id: 'co',
        name: 'Acme',
        customFields: {'client1': 'Region|North,South'},
      );
      expect(company.customFieldLabel('client2'), '');
      expect(company.customFieldLabel('product1'), '');
    });

    test('returns empty when the value is the empty string', () {
      const company = Company(
        id: 'co',
        name: 'Acme',
        customFields: {'client1': ''},
      );
      expect(company.customFieldLabel('client1'), '');
    });

    test('returns empty when customFields is empty', () {
      const company = Company(id: 'co', name: 'Acme');
      expect(company.customFieldLabel('client1'), '');
    });

    test('supports product / invoice prefixes', () {
      const company = Company(
        id: 'co',
        name: 'Acme',
        customFields: {'product1': 'SKU|', 'invoice2': 'PO Number|'},
      );
      expect(company.customFieldLabel('product1'), 'SKU');
      expect(company.customFieldLabel('invoice2'), 'PO Number');
    });
  });
}
