import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/detail_info_row.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/utils/formatting.dart';

/// Detail-card stack for a single [Product]. Mirrors
/// `ClientDetailCardsGrid` — the screen body composes this under the
/// shared `EntityDetailHeader`, so the only product-specific layout
/// concern lives here.
///
/// Today the stack is a single "Details" card; add cards (related
/// invoices, image gallery, custom fields, …) as the feature grows by
/// returning a `Column` of `DashboardCardShell`s.
class ProductDetailCards extends StatelessWidget {
  const ProductDetailCards({super.key, required this.product, this.formatter});

  final Product product;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final priceFmt = NumberFormat.decimalPattern()
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    return DashboardCardShell(
      title: context.tr('details'),
      child: DetailRowStack(
        children: [
          DetailInfoRow(
            label: context.tr('product'),
            value: product.productKey.isEmpty ? '—' : product.productKey,
          ),
          DetailInfoRow(
            label: context.tr('price'),
            value: priceFmt.format(product.price.toDouble()),
            monospace: true,
          ),
          DetailInfoRow(
            label: context.tr('cost'),
            value: priceFmt.format(product.cost.toDouble()),
            monospace: true,
          ),
          DetailInfoRow(
            label: context.tr('quantity'),
            value: product.quantity.toString(),
            monospace: true,
          ),
          if (product.notes.isNotEmpty)
            DetailInfoRow(label: context.tr('notes'), value: product.notes),
        ],
      ),
    );
  }
}
