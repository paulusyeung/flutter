import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';
import 'package:admin/utils/formatting.dart';

/// Drives the Product edit + create screen. Optimistic — `save()` lands
/// the draft in Drift via the repo, returns the saved entity, and the
/// outbox handles the server round-trip.
class ProductEditViewModel extends GenericEditViewModel<Product> {
  ProductEditViewModel({
    required this.repo,
    required this.companyId,
    Product? existing,
    Product? cloneFrom,
  }) : super(
         initialDraft: cloneFrom ?? existing ?? _emptyProduct(),
         original: existing,
       );

  final ProductRepository repo;
  final String companyId;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.productKey.isNotEmpty ||
        d.notes.isNotEmpty ||
        d.price != Decimal.zero ||
        d.cost != Decimal.zero;
  }

  @override
  Future<Product> performSave() async {
    if (isCreate) {
      return await repo.create(companyId: companyId, draft: draft);
    }
    await repo.save(companyId: companyId, product: draft);
    return draft;
  }

  void resetToEmpty() => reset(emptyDraft: _emptyProduct());

  void setProductKey(String v) => updateDraft(draft.copyWith(productKey: v));
  void setNotes(String v) => updateDraft(draft.copyWith(notes: v));
  void setPrice(String input) =>
      updateDraft(draft.copyWith(price: parseDecimal(input) ?? Decimal.zero));
  void setCost(String input) =>
      updateDraft(draft.copyWith(cost: parseDecimal(input) ?? Decimal.zero));
  void setQuantity(String input) => updateDraft(
    draft.copyWith(quantity: parseDecimal(input) ?? Decimal.zero),
  );
  void setMaxQuantity(String input) => updateDraft(
    draft.copyWith(maxQuantity: parseDecimal(input) ?? Decimal.zero),
  );
  void setProductImage(String v) =>
      updateDraft(draft.copyWith(productImage: v));
  void setInStockQuantity(String input) => updateDraft(
    draft.copyWith(inStockQuantity: parseDecimal(input) ?? Decimal.zero),
  );
  void setStockNotification(bool v) =>
      updateDraft(draft.copyWith(stockNotification: v));
  void setStockNotificationThreshold(String input) => updateDraft(
    draft.copyWith(
      stockNotificationThreshold: parseDecimal(input) ?? Decimal.zero,
    ),
  );
  void setTaxId(String v) => updateDraft(draft.copyWith(taxId: v));
  void setTaxName1(String v) => updateDraft(draft.copyWith(taxName1: v));
  void setTaxRate1(String input) => updateDraft(
    draft.copyWith(taxRate1: parseDecimal(input) ?? Decimal.zero),
  );
  void setTaxName2(String v) => updateDraft(draft.copyWith(taxName2: v));
  void setTaxRate2(String input) => updateDraft(
    draft.copyWith(taxRate2: parseDecimal(input) ?? Decimal.zero),
  );
  void setTaxName3(String v) => updateDraft(draft.copyWith(taxName3: v));
  void setTaxRate3(String input) => updateDraft(
    draft.copyWith(taxRate3: parseDecimal(input) ?? Decimal.zero),
  );
  void setCustomValue1(String v) =>
      updateDraft(draft.copyWith(customValue1: v));
  void setCustomValue2(String v) =>
      updateDraft(draft.copyWith(customValue2: v));
  void setCustomValue3(String v) =>
      updateDraft(draft.copyWith(customValue3: v));
  void setCustomValue4(String v) =>
      updateDraft(draft.copyWith(customValue4: v));
}

Product _emptyProduct() => Product(
  id: '',
  productKey: '',
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
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
);
