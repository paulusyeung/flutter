import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/line_item_api_model.dart';
import 'package:admin/data/models/domain/billing/line_item_type.dart';
import 'package:admin/data/models/value/money.dart';

part 'line_item.freezed.dart';

/// One row inside an invoice / quote / credit / purchase_order / recurring
/// invoice. Shared across all five billing-document types — the only thing
/// that varies between them is the wrapping entity model, not the line
/// items.
///
/// Stored as JSON inside the parent entity's Drift `payload` column (no
/// separate `line_items` table). Round-trips via [LineItem.fromApi] →
/// [LineItemPayload.toApiJson].
///
/// Money/qty/rate use `Decimal`. Tax rates round to 3 decimals during
/// totals math; this domain layer keeps full precision and lets the
/// totals calculator decide how to round.
///
/// All `Decimal` fields are `required` (freezed's `@Default` only accepts
/// const literals, and `Decimal.zero` isn't const-constructible). Callers
/// construct via [LineItem.fromApi] or [emptyLineItem]; per-field setters
/// in the edit VM thread defaults through.
@freezed
abstract class LineItem with _$LineItem {
  const factory LineItem({
    required String productKey,
    required String notes,
    required Decimal cost,
    required Decimal productCost,
    required Decimal quantity,
    required String taxName1,
    required String taxName2,
    required String taxName3,
    required Decimal taxRate1,
    required Decimal taxRate2,
    required Decimal taxRate3,
    required LineItemType typeId,
    required String customValue1,
    required String customValue2,
    required String customValue3,
    required String customValue4,
    required Decimal discount,
    String? taskId,
    String? expenseId,
    required String taxCategoryId,
    int? createdAt,
  }) = _LineItem;

  factory LineItem.fromApi(LineItemApi a) => LineItem(
    productKey: a.productKey,
    notes: a.notes,
    cost: parseMoney(a.cost),
    productCost: parseMoney(a.productCost),
    quantity: _parseQuantity(a.quantity) ?? Decimal.one,
    taxName1: a.taxName1,
    taxName2: a.taxName2,
    taxName3: a.taxName3,
    taxRate1: parseMoney(a.taxRate1),
    taxRate2: parseMoney(a.taxRate2),
    taxRate3: parseMoney(a.taxRate3),
    typeId: LineItemType.fromWire(a.typeId),
    customValue1: a.customValue1,
    customValue2: a.customValue2,
    customValue3: a.customValue3,
    customValue4: a.customValue4,
    discount: parseMoney(a.discount),
    taskId: (a.taskId ?? '').isEmpty ? null : a.taskId,
    expenseId: (a.expenseId ?? '').isEmpty ? null : a.expenseId,
    taxCategoryId: a.taxCategoryId,
    createdAt: a.createdAt,
  );
}

extension LineItemAccessors on LineItem {
  /// Convenience: `cost * quantity` (pre-discount, pre-tax).
  Decimal get gross => cost * quantity;
}

/// Empty line item — quantity defaults to 1, everything else zero/empty.
/// Used by the edit VM when the user taps "Add item".
LineItem emptyLineItem() => LineItem(
  productKey: '',
  notes: '',
  cost: Decimal.zero,
  productCost: Decimal.zero,
  quantity: Decimal.one,
  taxName1: '',
  taxName2: '',
  taxName3: '',
  taxRate1: Decimal.zero,
  taxRate2: Decimal.zero,
  taxRate3: Decimal.zero,
  typeId: LineItemType.standard,
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  discount: Decimal.zero,
  taskId: null,
  expenseId: null,
  taxCategoryId: '',
  createdAt: null,
);

/// Tolerant `Decimal` parser for the `quantity` wire field. Same shape as
/// `parseMoney` but returns null for unparseable/empty input so the domain
/// can substitute the `1` default rather than `0`.
Decimal? _parseQuantity(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return Decimal.parse(raw.toString());
  if (raw is String) {
    if (raw.isEmpty) return null;
    return Decimal.tryParse(raw);
  }
  return null;
}

/// Serialize back to the JSON shape the server expects. The repository
/// embeds the result inside the parent entity's `line_items` array.
extension LineItemPayload on LineItem {
  Map<String, dynamic> toApiJson() => <String, dynamic>{
    'product_key': productKey,
    'notes': notes,
    'cost': cost.toString(),
    'product_cost': productCost.toString(),
    'quantity': quantity.toString(),
    'tax_name1': taxName1,
    'tax_name2': taxName2,
    'tax_name3': taxName3,
    'tax_rate1': taxRate1.toString(),
    'tax_rate2': taxRate2.toString(),
    'tax_rate3': taxRate3.toString(),
    'type_id': typeId.wireId,
    'custom_value1': customValue1,
    'custom_value2': customValue2,
    'custom_value3': customValue3,
    'custom_value4': customValue4,
    'discount': discount.toString(),
    if (taskId != null) 'task_id': taskId,
    if (expenseId != null) 'expense_id': expenseId,
    'tax_id': taxCategoryId,
    if (createdAt != null) 'created_at': createdAt,
  };
}
