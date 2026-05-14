import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
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
/// Cards:
///  * **Details** — always shown. productKey, price, cost, quantity, plus
///    max_quantity (if > 0) and product_image (if non-empty), notes.
///  * **Inventory** — shown when `company.settings.track_inventory` is on,
///    or any inventory field is non-zero.
///  * **Taxes** — shown when `company.settings.enabled_item_tax_rates ≥ 1`,
///    or any tax slot / tax category is set on the product.
class ProductDetailCards extends StatelessWidget {
  const ProductDetailCards({
    super.key,
    required this.product,
    required this.companyId,
    this.formatter,
  });

  final Product product;
  final String companyId;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(companyId),
      builder: (context, snap) {
        final company = snap.data;
        final settings = company?.settings;
        final tracksInventory = settings?.trackInventory ?? false;
        final enabledTaxSlots = company?.enabledItemTaxRates ?? 0;

        final hasInventory =
            tracksInventory ||
            product.inStockQuantity != Decimal.zero ||
            product.stockNotification ||
            product.stockNotificationThreshold != Decimal.zero;
        final hasTaxes =
            enabledTaxSlots >= 1 ||
            product.taxId.isNotEmpty ||
            product.taxName1.isNotEmpty ||
            product.taxRate1 != Decimal.zero ||
            product.taxName2.isNotEmpty ||
            product.taxRate2 != Decimal.zero ||
            product.taxName3.isNotEmpty ||
            product.taxRate3 != Decimal.zero;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailsCard(product: product),
            if (hasInventory) ...[
              SizedBox(height: InSpacing.md(context)),
              _InventoryCard(product: product),
            ],
            if (hasTaxes) ...[
              SizedBox(height: InSpacing.md(context)),
              _TaxesCard(product: product, enabledSlots: enabledTaxSlots),
            ],
          ],
        );
      },
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.product});
  final Product product;

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
          if (product.maxQuantity != Decimal.zero)
            DetailInfoRow(
              label: context.tr('max_quantity'),
              value: product.maxQuantity.toString(),
              monospace: true,
            ),
          if (product.productImage.isNotEmpty)
            DetailInfoRow(
              label: context.tr('product_image'),
              value: product.productImage,
            ),
          if (product.notes.isNotEmpty)
            DetailInfoRow(label: context.tr('notes'), value: product.notes),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      title: context.tr('inventory'),
      child: DetailRowStack(
        children: [
          DetailInfoRow(
            label: context.tr('in_stock_quantity'),
            value: product.inStockQuantity.toString(),
            monospace: true,
          ),
          DetailInfoRow(
            label: context.tr('stock_notifications'),
            value: context.tr(product.stockNotification ? 'yes' : 'no'),
          ),
          if (product.stockNotificationThreshold != Decimal.zero)
            DetailInfoRow(
              label: context.tr('notification_threshold'),
              value: product.stockNotificationThreshold.toString(),
              monospace: true,
            ),
        ],
      ),
    );
  }
}

class _TaxesCard extends StatelessWidget {
  const _TaxesCard({required this.product, required this.enabledSlots});
  final Product product;
  final int enabledSlots;

  static const _categoryLabelKeys = {
    '1': 'physical_goods',
    '2': 'services',
    '3': 'digital_products',
    '4': 'shipping',
    '5': 'tax_exempt',
    '6': 'reduced_tax',
  };

  String _formatTaxRow(BuildContext context, String name, Decimal rate) {
    if (name.isEmpty && rate == Decimal.zero) return '—';
    final label = name.isEmpty ? context.tr('tax') : name;
    return '$label @ $rate%';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (product.taxId.isNotEmpty) {
      final key = _categoryLabelKeys[product.taxId];
      rows.add(
        DetailInfoRow(
          label: context.tr('tax_category'),
          value: key == null ? product.taxId : context.tr(key),
        ),
      );
    }
    if ((enabledSlots >= 1 ||
            product.taxName1.isNotEmpty ||
            product.taxRate1 != Decimal.zero) &&
        !(product.taxName1.isEmpty && product.taxRate1 == Decimal.zero)) {
      rows.add(
        DetailInfoRow(
          label: '${context.tr('tax')} 1',
          value: _formatTaxRow(context, product.taxName1, product.taxRate1),
        ),
      );
    }
    if ((enabledSlots >= 2 ||
            product.taxName2.isNotEmpty ||
            product.taxRate2 != Decimal.zero) &&
        !(product.taxName2.isEmpty && product.taxRate2 == Decimal.zero)) {
      rows.add(
        DetailInfoRow(
          label: '${context.tr('tax')} 2',
          value: _formatTaxRow(context, product.taxName2, product.taxRate2),
        ),
      );
    }
    if ((enabledSlots >= 3 ||
            product.taxName3.isNotEmpty ||
            product.taxRate3 != Decimal.zero) &&
        !(product.taxName3.isEmpty && product.taxRate3 == Decimal.zero)) {
      rows.add(
        DetailInfoRow(
          label: '${context.tr('tax')} 3',
          value: _formatTaxRow(context, product.taxName3, product.taxRate3),
        ),
      );
    }
    return DashboardCardShell(
      title: context.tr('taxes'),
      child: DetailRowStack(children: rows),
    );
  }
}
