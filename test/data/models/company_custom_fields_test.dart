import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/data/models/domain/custom_field_types.dart';

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

  group('CompanyCustomFields.customFieldType / customFieldOptions', () {
    const company = Company(
      id: 'co',
      name: 'Acme',
      customFields: {
        'client1': 'Single|single_line_text',
        'client2': 'Notes|multi_line_text',
        'client3': 'Active|switch',
        'client4': 'Due|date',
        'invoice1': 'Region|North,South',
        'invoice2': 'Status|',
        'product1': 'Legacy',
      },
    );

    test('resolves each reserved type', () {
      expect(company.customFieldType('client1'), kFieldTypeSingleLineText);
      expect(company.customFieldType('client2'), kFieldTypeMultiLineText);
      expect(company.customFieldType('client3'), kFieldTypeSwitch);
      expect(company.customFieldType('client4'), kFieldTypeDate);
    });

    test('dropdown + options', () {
      expect(company.customFieldType('invoice1'), kFieldTypeDropdown);
      expect(company.customFieldOptions('invoice1'), ['North', 'South']);
      // Empty-suffix dropdown has no options.
      expect(company.customFieldType('invoice2'), kFieldTypeDropdown);
      expect(company.customFieldOptions('invoice2'), isEmpty);
    });

    test('legacy no-pipe value is multi-line text', () {
      expect(company.customFieldType('product1'), kFieldTypeMultiLineText);
      expect(company.customFieldOptions('product1'), isEmpty);
    });

    test('non-dropdown types have no options', () {
      expect(company.customFieldOptions('client1'), isEmpty);
      expect(company.customFieldOptions('client3'), isEmpty);
    });
  });

  group('CompanyCustomFields.customFieldDisplay', () {
    const company = Company(
      id: 'co',
      name: 'Acme',
      customFields: {
        'client1': 'Active|switch',
        'client2': 'Region|North,South',
        'client3': 'Note|single_line_text',
      },
    );

    test('switch → localized yes/no', () {
      expect(
        company.customFieldDisplay('client1', 'yes', yes: 'Yes', no: 'No'),
        'Yes',
      );
      expect(
        company.customFieldDisplay('client1', 'no', yes: 'Yes', no: 'No'),
        'No',
      );
      // Any non-'yes' value reads as No.
      expect(
        company.customFieldDisplay('client1', '', yes: 'Yes', no: 'No'),
        'No',
      );
    });

    test('text / dropdown show the value verbatim', () {
      expect(
        company.customFieldDisplay('client2', 'North', yes: 'Yes', no: 'No'),
        'North',
      );
      expect(
        company.customFieldDisplay('client3', 'hello', yes: 'Yes', no: 'No'),
        'hello',
      );
    });
  });
}
