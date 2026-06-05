import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/ui/features/products/widgets/product_actions.dart';

void main() {
  test('cloneDraftFor strips id, lifecycle, and document references but keeps '
      'the real product data', () {
    final source = Product.fromApi(
      const ProductApi(
        id: 'prod_1',
        productKey: 'Widget',
        price: '10',
        isDeleted: true,
        archivedAt: 1700000000,
        // Document ids belong to the source product — a clone must not carry
        // them (an offline delete from the clone would hit the original file).
        documents: [DocumentApi(id: 'd1', name: 'a.pdf')],
        updatedAt: 1700000000,
      ),
    );
    expect(source.documents, hasLength(1)); // sanity: source has a doc

    final clone = ProductActions.cloneDraftFor(source);

    // Identity + lifecycle stripped so the create scaffold mints a new row.
    expect(clone.id, isEmpty);
    expect(clone.documents, isEmpty);
    expect(clone.isDeleted, isFalse);
    expect(clone.archivedAt, isNull);
    expect(clone.isDirty, isFalse);
    // Real product data is preserved into the new draft.
    expect(clone.productKey, 'Widget');
    expect(clone.price.toString(), '10');
  });
}
