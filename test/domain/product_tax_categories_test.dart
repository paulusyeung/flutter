import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/domain/product_tax_categories.dart';

void main() {
  test('kProductTaxCategories covers the server PRODUCT_TYPE ids 1..9 and '
      'every label resolves to an en.json key', () {
    // Server source of truth: Product::PRODUCT_TYPE_* = 1..9
    // (app/Models/Product.php), mirrored by React's useTaxCategories().
    expect(kProductTaxCategories.keys.toList(), [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    ]);

    final en =
        jsonDecode(File('assets/i18n/en.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final entry in kProductTaxCategories.entries) {
      expect(
        en.containsKey(entry.value),
        isTrue,
        reason:
            'en.json is missing the tax-category label key "${entry.value}" '
            '(id ${entry.key})',
      );
    }
  });
}
