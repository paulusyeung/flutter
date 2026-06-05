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
    Decimal? cost,
    Decimal? quantity,
    String taxId = '',
    String customValue1 = '',
  }) {
    price ??= Decimal.zero;
    cost ??= Decimal.parse('5.00');
    quantity ??= Decimal.zero;
    return Product(
      id: 'p1',
      productKey: productKey,
      notes: notes,
      cost: cost,
      price: price,
      quantity: quantity,
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
      taxId: taxId,
      customValue1: customValue1,
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

  // The unified fill helper shared by the desktop inline table, the picker,
  // and the create-from-product flow. Mirrors React's `useHandleProductChange`.
  group('lineItemFromProduct', () {
    test('#2 unit price = sale price; product_cost = product cost', () {
      final p = makeProduct(
        price: Decimal.parse('19.99'),
        cost: Decimal.parse('7.50'),
      );
      final li = lineItemFromProduct(p);
      expect(li.cost, Decimal.parse('19.99'));
      expect(li.productCost, Decimal.parse('7.50'));
    });

    test('#6 conversionRate scales the unit price', () {
      final p = makeProduct(price: Decimal.parse('100'));
      final li = lineItemFromProduct(p, conversionRate: Decimal.parse('1.5'));
      expect(li.cost, Decimal.parse('150'));
    });

    test('#6 null conversionRate leaves the price untouched', () {
      final p = makeProduct(price: Decimal.parse('100'));
      expect(lineItemFromProduct(p).cost, Decimal.parse('100'));
    });

    test('#4 quantity disabled → always 1, ignoring product quantity', () {
      final p = makeProduct(quantity: Decimal.parse('4'));
      final li = lineItemFromProduct(p, enableProductQuantity: false);
      expect(li.quantity, Decimal.one);
    });

    test('#4 quantity enabled + default_quantity → 1', () {
      final p = makeProduct(quantity: Decimal.parse('4'));
      final li = lineItemFromProduct(
        p,
        enableProductQuantity: true,
        defaultQuantity: true,
      );
      expect(li.quantity, Decimal.one);
    });

    test('#4 quantity enabled, no default → product quantity', () {
      final p = makeProduct(quantity: Decimal.parse('4'));
      final li = lineItemFromProduct(
        p,
        enableProductQuantity: true,
        defaultQuantity: false,
      );
      expect(li.quantity, Decimal.parse('4'));
    });

    test('#4 quantity enabled but product quantity 0 falls back to 1', () {
      final p = makeProduct(quantity: Decimal.zero);
      final li = lineItemFromProduct(p, enableProductQuantity: true);
      expect(li.quantity, Decimal.one);
    });

    test('tax category + custom values propagate (not just tax bands)', () {
      final p = makeProduct(taxId: 'cat-3', customValue1: 'engraved');
      final li = lineItemFromProduct(p);
      expect(li.taxCategoryId, 'cat-3');
      expect(li.customValue1, 'engraved');
    });

    test('base merge overwrites product fields but keeps discount + links', () {
      final base = emptyLineItem().copyWith(
        discount: Decimal.parse('3'),
        taskId: 'task-9',
        cost: Decimal.parse('1'),
      );
      final li = lineItemFromProduct(
        makeProduct(price: Decimal.parse('19.99')),
        base: base,
      );
      expect(li.cost, Decimal.parse('19.99')); // product field overwritten
      expect(li.discount, Decimal.parse('3')); // preserved
      expect(li.taskId, 'task-9'); // preserved
    });
  });
}
