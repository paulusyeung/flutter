import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/line_item_api_model.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/billing/line_item_type.dart';

/// Regression: the server emits `type_id: '6'` for expense-linked line items.
/// Before adding `expense('6')`, `fromWire('6')` fell back to `standard`, so
/// loading + re-saving an invoice silently rewrote the type to product.
void main() {
  test('fromWire maps the full 1..6 set', () {
    expect(LineItemType.fromWire('1'), LineItemType.standard);
    expect(LineItemType.fromWire('2'), LineItemType.task);
    expect(LineItemType.fromWire('3'), LineItemType.unpaidFee);
    expect(LineItemType.fromWire('4'), LineItemType.paidFee);
    expect(LineItemType.fromWire('5'), LineItemType.lateFee);
    expect(LineItemType.fromWire('6'), LineItemType.expense);
    expect(LineItemType.expense.wireId, '6');
  });

  test('unknown / empty / null still falls back to standard', () {
    expect(LineItemType.fromWire('99'), LineItemType.standard);
    expect(LineItemType.fromWire(''), LineItemType.standard);
    expect(LineItemType.fromWire(null), LineItemType.standard);
  });

  test(
    'expense line item (type_id 6) round-trips through fromApi/toApiJson',
    () {
      final domain = LineItem.fromApi(
        const LineItemApi(typeId: '6', productKey: 'x', expenseId: 'exp1'),
      );
      expect(domain.typeId, LineItemType.expense);
      expect(domain.toApiJson()['type_id'], '6');
    },
  );
}
