// Guards the `lineItemForProduct(...)` factory used by the Product →
// "New Invoice / Quote / Purchase Order" flow. The destination edit
// screens read `?product=<id>`, watch the product from Drift, and call
// `vm.addLineItem(lineItemForProduct(product))` — so this helper is the
// only mapping step between a Product row and a billing line item.
//
// `_lineItemFor` used to live as a private helper in `product_actions.dart`.
// It was promoted to public when the seed identity moved from `extra:` to
// URL query params (see the plan at ~/.claude/plans/i-use-the-creante-…).

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/product.dart';

void main() {
  Product makeProduct({
    String productKey = 'SKU-1',
    String notes = 'A widget',
    Decimal? price,
  }) {
    price ??= Decimal.zero;
    return Product(
      id: 'p1',
      productKey: productKey,
      notes: notes,
      cost: Decimal.parse('5.00'),
      price: price,
      quantity: Decimal.zero,
      maxQuantity: Decimal.zero,
      productImage: '',
      inStockQuantity: Decimal.zero,
      stockNotification: false,
      stockNotificationThreshold: Decimal.zero,
      taxName1: 'VAT',
      taxRate1: Decimal.parse('20'),
      taxName2: 'City',
      taxRate2: Decimal.parse('1.5'),
      taxName3: '',
      taxRate3: Decimal.zero,
      taxId: '',
      customValue1: '',
      customValue2: '',
      customValue3: '',
      customValue4: '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      archivedAt: null,
      isDeleted: false,
    );
  }

  test('cost carries product.price (the sale price), not product.cost', () {
    final p = makeProduct(price: Decimal.parse('19.99'));
    final li = lineItemForProduct(p);
    // The customer is billed `price`; the internal `cost` field on Product
    // is the COGS (what the seller paid) and must NOT land on the line.
    expect(li.cost, Decimal.parse('19.99'));
  });

  test('productKey + notes copied verbatim', () {
    final p = makeProduct(productKey: 'WIDGET-7', notes: 'Top-shelf');
    final li = lineItemForProduct(p);
    expect(li.productKey, 'WIDGET-7');
    expect(li.notes, 'Top-shelf');
  });

  test('all three tax bands propagate (name + rate)', () {
    final li = lineItemForProduct(makeProduct());
    expect(li.taxName1, 'VAT');
    expect(li.taxRate1, Decimal.parse('20'));
    expect(li.taxName2, 'City');
    expect(li.taxRate2, Decimal.parse('1.5'));
    expect(li.taxName3, '');
    expect(li.taxRate3, Decimal.zero);
  });

  test('quantity defaults to 1 via emptyLineItem (not zero)', () {
    final li = lineItemForProduct(makeProduct());
    expect(li.quantity, Decimal.one);
  });
}
