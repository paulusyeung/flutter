import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/domain/document.dart';
import 'package:admin/data/models/value/money.dart';

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
    maxQuantity: _parseNum(a.maxQuantity),
    productImage: a.productImage,
    inStockQuantity: _parseNum(a.inStockQuantity),
    stockNotification: a.stockNotification,
    stockNotificationThreshold: _parseNum(a.stockNotificationThreshold),
    taxName1: a.taxName1,
    taxRate1: _parseRate(a.taxRate1),
    taxName2: a.taxName2,
    taxRate2: _parseRate(a.taxRate2),
    taxName3: a.taxName3,
    taxRate3: _parseRate(a.taxRate3),
    taxId: a.taxId,
    customValue1: a.customValue1,
    customValue2: a.customValue2,
    customValue3: a.customValue3,
    customValue4: a.customValue4,
    updatedAt: _seconds(a.updatedAt),
    createdAt: _seconds(a.createdAt),
    archivedAt: a.archivedAt > 0 ? _seconds(a.archivedAt) : null,
    isDeleted: a.isDeleted,
    // `a.documents` is nullable so the API DTO can distinguish JSON-omitted
    // from JSON-empty; the domain model is non-nullable, so fall back here.
    documents: (a.documents ?? const <DocumentApi>[])
        .map(Document.fromApi)
        .toList(growable: false),
  );
}

Decimal _parseRate(num n) => Decimal.parse(n.toString());
Decimal _parseNum(num n) => Decimal.parse(n.toString());
DateTime _seconds(int s) =>
    DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);

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
      'custom_value1': customValue1,
      'custom_value2': customValue2,
      'custom_value3': customValue3,
      'custom_value4': customValue4,
    };
    return json;
  }
}
