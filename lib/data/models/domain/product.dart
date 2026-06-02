import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/domain/document.dart';
import 'package:admin/data/models/value/money.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'product.freezed.dart';

/// Clean domain model the UI consumes. `Product.fromApi(...)` walks the
/// raw [ProductApi] DTO. The `isDirty` flag is local-only — `fromApi`
/// defaults it to `false`, and `ProductRepository._fromRow` overlays the
/// Drift row's value so unsaved edits survive app restart.
@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String productKey,
    required String notes,
    required Decimal cost,
    required Decimal price,
    required Decimal quantity,
    required Decimal maxQuantity,
    required String productImage,
    required Decimal inStockQuantity,
    required bool stockNotification,
    required Decimal stockNotificationThreshold,
    required String taxName1,
    required Decimal taxRate1,
    required String taxName2,
    required Decimal taxRate2,
    required String taxName3,
    required Decimal taxRate3,
    required String taxId,
    required String taxCategoryId,
    required String customValue1,
    required String customValue2,
    required String customValue3,
    required String customValue4,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    required bool isDeleted,
    @Default(<Document>[]) List<Document> documents,
    @Default(false) bool isDirty,
  }) = _Product;

  factory Product.fromApi(ProductApi a) => Product(
    id: a.id,
    productKey: a.productKey,
    notes: a.notes,
    cost: parseMoney(a.cost),
    price: parseMoney(a.price),
    quantity: parseMoney(a.quantity),
    maxQuantity: numToDecimal(a.maxQuantity),
    productImage: a.productImage,
    inStockQuantity: numToDecimal(a.inStockQuantity),
    stockNotification: a.stockNotification,
    stockNotificationThreshold: numToDecimal(a.stockNotificationThreshold),
    taxName1: a.taxName1,
    taxRate1: numToDecimal(a.taxRate1),
    taxName2: a.taxName2,
    taxRate2: numToDecimal(a.taxRate2),
    taxName3: a.taxName3,
    taxRate3: numToDecimal(a.taxRate3),
    taxId: a.taxId,
    taxCategoryId: a.taxCategoryId,
    customValue1: a.customValue1,
    customValue2: a.customValue2,
    customValue3: a.customValue3,
    customValue4: a.customValue4,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
    isDeleted: a.isDeleted,
    documents: mapDocuments(a.documents),
  );
}

/// Convenience: a fresh blank [Product] carrying just a `productKey`.
/// Used by the line-item table's autocomplete "Create '`<query>`'" tile
/// when the user types a key that doesn't match any existing product.
/// Defaults all numeric fields to zero and timestamps to "now"; the
/// repository's `create` path swaps the empty `id` for a `tmp_<uuid>`.
Product emptyProductWithKey(String productKey) {
  final now = DateTime.now().toUtc();
  return Product(
    id: '',
    productKey: productKey,
    notes: '',
    cost: Decimal.zero,
    price: Decimal.zero,
    quantity: Decimal.zero,
    maxQuantity: Decimal.zero,
    productImage: '',
    inStockQuantity: Decimal.zero,
    stockNotification: false,
    stockNotificationThreshold: Decimal.zero,
    taxName1: '',
    taxRate1: Decimal.zero,
    taxName2: '',
    taxRate2: Decimal.zero,
    taxName3: '',
    taxRate3: Decimal.zero,
    taxId: '',
    taxCategoryId: '',
    customValue1: '',
    customValue2: '',
    customValue3: '',
    customValue4: '',
    updatedAt: now,
    createdAt: now,
    archivedAt: null,
    isDeleted: false,
  );
}

/// Serialize the in-memory product back to the JSON shape the server
/// expects. `preserveTempId` lets callers (the local Drift cache) keep
/// the temp id; outbound `POST /products` payloads drop it so the server
/// can assign the real one.
extension ProductPayload on Product {
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    final json = <String, dynamic>{
      if (preserveTempId || !id.startsWith('tmp_')) 'id': id,
      'product_key': productKey,
      'notes': notes,
      'cost': cost.toString(),
      'price': price.toString(),
      'quantity': quantity.toString(),
      // NOTE: these stay `.toDouble()` (not `.toString()` like cost/price/
      // quantity above). ProductApi types tax_rate*/max_quantity/
      // in_stock_quantity/stock_notification_threshold as `num` (cost/price/
      // quantity are the permissive `Object`), so its generated `fromJson`
      // hard-casts `as num` — and the repo round-trips this payload back
      // through `ProductApi.fromJson` in `_fromRow`. Emitting strings here
      // throws "String is not a subtype of num?" on read. Aligning with the
      // other entities would mean retyping those DTO fields to `Object`, not a
      // one-liner here.
      'max_quantity': maxQuantity.toDouble(),
      'product_image': productImage,
      'in_stock_quantity': inStockQuantity.toDouble(),
      'stock_notification': stockNotification,
      'stock_notification_threshold': stockNotificationThreshold.toDouble(),
      'tax_name1': taxName1,
      'tax_rate1': taxRate1.toDouble(),
      'tax_name2': taxName2,
      'tax_rate2': taxRate2.toDouble(),
      'tax_name3': taxName3,
      'tax_rate3': taxRate3.toDouble(),
      'tax_id': taxId,
      'tax_category_id': taxCategoryId,
      'custom_value1': customValue1,
      'custom_value2': customValue2,
      'custom_value3': customValue3,
      'custom_value4': customValue4,
    };
    return json;
  }
}
