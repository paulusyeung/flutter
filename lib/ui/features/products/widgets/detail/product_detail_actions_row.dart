import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';

/// Action set surfaced for a product. Mirrors `ClientAction` — only the
/// edit / archive / restore branches are wired today; the rest render
/// disabled with a "coming soon" tooltip so the legacy admin-portal action
/// set stays visible and grep-able.
enum ProductAction {
  edit,
  clone,
  cloneToInvoice,
  cloneToQuote,
  newInvoice,
  newQuote,
  archive,
  restore,
  delete,
  purge,
}

/// Builds the per-product item list and delegates layout/overflow/tooltips
/// to the shared [EntityDetailActionsRow].
class ProductDetailActionsRow extends StatelessWidget {
  const ProductDetailActionsRow({
    super.key,
    required this.product,
    required this.onAction,
  });

  final Product product;
  final void Function(ProductAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return EntityDetailActionsRow<ProductAction>(items: _items(context));
  }

  List<EntityActionItem<ProductAction>> _items(BuildContext context) {
    final canArchive = product.archivedAt == null && !product.isDeleted;
    final canRestore = product.archivedAt != null || product.isDeleted;

    EntityActionItem<ProductAction> disabled(
      ProductAction kind,
      IconData icon,
      String labelKey,
    ) => EntityActionItem(
      kind: kind,
      icon: icon,
      label: context.tr(labelKey),
      enabled: false,
    );

    return [
      EntityActionItem(
        kind: ProductAction.edit,
        icon: Icons.edit_outlined,
        label: context.tr('edit'),
        enabled: true,
        isPrimary: true,
        onTap: () => onAction(ProductAction.edit),
      ),
      disabled(ProductAction.clone, Icons.copy_outlined, 'clone_product'),
      disabled(
        ProductAction.cloneToInvoice,
        Icons.receipt_long_outlined,
        'clone_to_invoice',
      ),
      disabled(
        ProductAction.cloneToQuote,
        Icons.request_quote_outlined,
        'clone_to_quote',
      ),
      disabled(ProductAction.newInvoice, Icons.add, 'new_invoice'),
      disabled(ProductAction.newQuote, Icons.add, 'new_quote'),
      if (canArchive)
        EntityActionItem(
          kind: ProductAction.archive,
          icon: Icons.archive_outlined,
          label: context.tr('archive'),
          enabled: true,
          onTap: () => onAction(ProductAction.archive),
        ),
      if (canRestore)
        EntityActionItem(
          kind: ProductAction.restore,
          icon: Icons.unarchive_outlined,
          label: context.tr('restore'),
          enabled: true,
          onTap: () => onAction(ProductAction.restore),
        ),
      disabled(ProductAction.delete, Icons.delete_outline, 'delete'),
      disabled(ProductAction.purge, Icons.delete_forever_outlined, 'purge'),
    ];
  }
}
