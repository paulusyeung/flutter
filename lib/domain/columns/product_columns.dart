import 'package:admin/app/router.dart';
import 'package:admin/data/db/dao/product_dao.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';

typedef ProductColumn = ColumnDefinition<Product>;

const List<String> kDefaultProductColumns = <String>[
  ProductFieldIds.productKey,
  ProductFieldIds.price,
  ProductFieldIds.cost,
  ProductFieldIds.quantity,
  ProductFieldIds.updatedAt,
];

final List<ProductColumn> kAllProductColumns = <ProductColumn>[
  ProductColumn(
    id: ProductFieldIds.productKey,
    labelKey: 'product',
    cellBuilder: (p, ctx) => cellLink(
      ctx,
      p.productKey,
      bold: true,
      onTap: () => goEntityFull(ctx, '/products', p.id),
    ),
    valueBuilder: (p) => cellNonZeroString(p.productKey),
  ),
  ProductColumn(
    id: ProductFieldIds.price,
    labelKey: 'price',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (p, _) => cellMoney(p.price),
    valueBuilder: (p) => cellMoneyValue(p.price),
  ),
  ProductColumn(
    id: ProductFieldIds.cost,
    labelKey: 'cost',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (p, _) => cellMoney(p.cost),
    valueBuilder: (p) => cellMoneyValue(p.cost),
  ),
  ProductColumn(
    id: ProductFieldIds.quantity,
    labelKey: 'quantity',
    width: 100,
    align: ColumnAlign.end,
    cellBuilder: (p, _) => cellText(p.quantity.toString()),
    valueBuilder: (p) => p.quantity.toString(),
  ),
  ProductColumn(
    id: ProductFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 110,
    cellBuilder: (p, ctx) => cellDate(p.updatedAt, ctx),
    valueBuilder: (p) => p.updatedAt.toIso8601String(),
  ),
];

final Map<String, ProductColumn> productColumnsById = {
  for (final c in kAllProductColumns) c.id: c,
};
