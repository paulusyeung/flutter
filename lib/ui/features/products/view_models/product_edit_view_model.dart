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
  }) : super(initialDraft: existing ?? _emptyProduct(), original: existing);

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
