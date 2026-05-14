import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';

/// Action set surfaced for a product. Mirrors `ClientAction` — only the
/// edit / archive / restore branches are wired today; the rest render
/// disabled with a "coming soon" tooltip so the legacy admin-portal action
/// set stays visible and grep-able. Consumed by both the detail-screen
/// header and the list-row popup.
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

/// Single source of truth for what product actions exist and what they
/// do. List-row popup and detail header both consume this — mirrors
/// admin-portal's `entity.getActions(...)` pattern.
class ProductActions {
  ProductActions._();

  static List<EntityActionItem<ProductAction>> itemsFor(
    BuildContext context,
    Product product,
    void Function(ProductAction) onTap,
  ) {
    final canArchive = product.archivedAt == null && !product.isDeleted;
    final canRestore = product.archivedAt != null || product.isDeleted;

    return [
      EntityActionItem(
        kind: ProductAction.edit,
        icon: Icons.edit_outlined,
        label: context.tr('edit'),
        enabled: true,
        isPrimary: true,
        onTap: () => onTap(ProductAction.edit),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.clone,
        icon: Icons.copy_outlined,
        label: context.tr('clone_product'),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.cloneToInvoice,
        icon: Icons.receipt_long_outlined,
        label: context.tr('clone_to_invoice'),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.cloneToQuote,
        icon: Icons.request_quote_outlined,
        label: context.tr('clone_to_quote'),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.newInvoice,
        icon: Icons.add,
        label: context.tr('new_invoice'),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.newQuote,
        icon: Icons.add,
        label: context.tr('new_quote'),
      ),
      if (canArchive)
        EntityActionItem(
          kind: ProductAction.archive,
          icon: Icons.archive_outlined,
          label: context.tr('archive'),
          enabled: true,
          onTap: () => onTap(ProductAction.archive),
        ),
      if (canRestore)
        EntityActionItem(
          kind: ProductAction.restore,
          icon: Icons.unarchive_outlined,
          label: context.tr('restore'),
          enabled: true,
          onTap: () => onTap(ProductAction.restore),
        ),
      EntityActionItem.disabled(
        kind: ProductAction.delete,
        icon: Icons.delete_outline,
        label: context.tr('delete'),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.purge,
        icon: Icons.delete_forever_outlined,
        label: context.tr('purge'),
      ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    Product product,
    ProductAction action,
  ) async {
    switch (action) {
      case ProductAction.edit:
        context.go('/products/${product.id}/edit');
      case ProductAction.archive:
        await runMutationWithNotify(
          context,
          () => services.products.archive(companyId: companyId, id: product.id),
          successMsg: context.tr('archived_product'),
        );
      case ProductAction.restore:
        await runMutationWithNotify(
          context,
          () => services.products.restore(companyId: companyId, id: product.id),
          successMsg: context.tr('restored_product'),
        );
      case ProductAction.clone:
      case ProductAction.cloneToInvoice:
      case ProductAction.cloneToQuote:
      case ProductAction.newInvoice:
      case ProductAction.newQuote:
      case ProductAction.delete:
      case ProductAction.purge:
        break;
    }
  }
}
