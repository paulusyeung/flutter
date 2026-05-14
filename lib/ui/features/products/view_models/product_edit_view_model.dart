import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/repositories/product_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

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

  // `setStr` / `setDec` / `setBool` live on the base; each setter just
  // names the `copyWith` projection. Compresses ~50 lines of duplicate
  // `updateDraft(draft.copyWith(...))` boilerplate.
  void setProductKey(String v) =>
      setStr((d, v) => d.copyWith(productKey: v), v);
  void setNotes(String v) => setStr((d, v) => d.copyWith(notes: v), v);
  void setPrice(String s) => setDec((d, v) => d.copyWith(price: v), s);
  void setCost(String s) => setDec((d, v) => d.copyWith(cost: v), s);
  void setQuantity(String s) => setDec((d, v) => d.copyWith(quantity: v), s);
  void setMaxQuantity(String s) =>
      setDec((d, v) => d.copyWith(maxQuantity: v), s);
  void setProductImage(String v) =>
      setStr((d, v) => d.copyWith(productImage: v), v);
  void setInStockQuantity(String s) =>
      setDec((d, v) => d.copyWith(inStockQuantity: v), s);
  void setStockNotification(bool v) =>
      setBool((d, v) => d.copyWith(stockNotification: v), v);
  void setStockNotificationThreshold(String s) =>
      setDec((d, v) => d.copyWith(stockNotificationThreshold: v), s);
  void setTaxId(String v) => setStr((d, v) => d.copyWith(taxId: v), v);
  void setTaxName1(String v) => setStr((d, v) => d.copyWith(taxName1: v), v);
  void setTaxRate1(String s) => setDec((d, v) => d.copyWith(taxRate1: v), s);
  void setTaxName2(String v) => setStr((d, v) => d.copyWith(taxName2: v), v);
  void setTaxRate2(String s) => setDec((d, v) => d.copyWith(taxRate2: v), s);
  void setTaxName3(String v) => setStr((d, v) => d.copyWith(taxName3: v), v);
  void setTaxRate3(String s) => setDec((d, v) => d.copyWith(taxRate3: v), s);
  void setCustomValue1(String v) =>
      setStr((d, v) => d.copyWith(customValue1: v), v);
  void setCustomValue2(String v) =>
      setStr((d, v) => d.copyWith(customValue2: v), v);
  void setCustomValue3(String v) =>
      setStr((d, v) => d.copyWith(customValue3: v), v);
  void setCustomValue4(String v) =>
      setStr((d, v) => d.copyWith(customValue4: v), v);
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
