import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/db/dao/product_dao.dart';
import 'package:admin/data/models/domain/product.dart';
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
    cellBuilder: (p, _) => _text(p.productKey, bold: true),
    valueBuilder: (p) => _nz(p.productKey),
  ),
  ProductColumn(
    id: ProductFieldIds.price,
    labelKey: 'price',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (p, ctx) => _money(p.price),
    valueBuilder: (p) => _moneyValue(p.price),
  ),
  ProductColumn(
    id: ProductFieldIds.cost,
    labelKey: 'cost',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (p, ctx) => _money(p.cost),
    valueBuilder: (p) => _moneyValue(p.cost),
  ),
  ProductColumn(
    id: ProductFieldIds.quantity,
    labelKey: 'quantity',
    width: 100,
    align: ColumnAlign.end,
    cellBuilder: (p, ctx) => _text(p.quantity.toString()),
    valueBuilder: (p) => p.quantity.toString(),
  ),
  ProductColumn(
    id: ProductFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 110,
    cellBuilder: (p, ctx) {
      final formatter = DateFormat.yMMMd(
        Localizations.localeOf(ctx).toString(),
      );
      return _text(formatter.format(p.updatedAt.toLocal()));
    },
    valueBuilder: (p) => p.updatedAt.toIso8601String(),
  ),
];

final Map<String, ProductColumn> productColumnsById = {
  for (final c in kAllProductColumns) c.id: c,
};

String? _nz(String s) => s.isEmpty ? null : s;

String? _moneyValue(Decimal v) => v == Decimal.zero ? null : v.toString();

Widget _text(String value, {bool bold = false}) {
  if (value.isEmpty) return _empty();
  return _CellText(value: value, bold: bold);
}

Widget _empty() => const _CellText(value: '—', muted: true);

Widget _money(Decimal value) {
  final isZero = value == Decimal.zero;
  final formatter = NumberFormat.decimalPattern()
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;
  return _MoneyText(
    text: isZero ? '—' : formatter.format(value.toDouble()),
    isZero: isZero,
  );
}

class _CellText extends StatelessWidget {
  const _CellText({required this.value, this.bold = false, this.muted = false});
  final String value;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: muted ? tokens.ink4 : tokens.ink,
      ),
    );
  }
}

class _MoneyText extends StatelessWidget {
  const _MoneyText({required this.text, required this.isZero});
  final String text;
  final bool isZero;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 1.2,
        color: isZero ? tokens.ink3 : tokens.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
