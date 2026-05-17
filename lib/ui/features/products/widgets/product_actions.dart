import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Action set surfaced for a product. Mirrors `ClientAction` — only the
/// edit / archive / restore branches are wired today; the rest render
/// disabled with a "coming soon" tooltip so the legacy admin-portal action
/// set stays visible and grep-able. Consumed by both the detail-screen
/// header and the list-row popup.
enum ProductAction {
  edit,
  newInvoice,
  newQuote,
  newPurchaseOrder,
  setTaxCategory,
  clone,
  archive,
  restore,
  delete,
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
    // Purge is admin/owner-only — mirrors the Client gate so the action
    // only renders when the user could plausibly run it.

    return [
      editActionItem(
        context: context,
        kind: ProductAction.edit,
        onTap: () => onTap(ProductAction.edit),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.newInvoice,
        icon: Icons.receipt_long_outlined,
        label: context.tr('new_invoice'),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.newQuote,
        icon: Icons.request_quote_outlined,
        label: context.tr('new_quote'),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.newPurchaseOrder,
        icon: Icons.shopping_cart_outlined,
        label: context.tr('new_purchase_order'),
      ),
      EntityActionItem.disabled(
        kind: ProductAction.setTaxCategory,
        icon: Icons.percent,
        label: context.tr('set_tax_category'),
      ),
      EntityActionItem(
        kind: ProductAction.clone,
        icon: Icons.copy_outlined,
        label: context.tr('clone_product'),
        enabled: true,
        onTap: () => onTap(ProductAction.clone),
      ),
      ?archiveActionItem(
        context: context,
        kind: ProductAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(ProductAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: ProductAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(ProductAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: ProductAction.delete,
        canDelete: !product.isDeleted,
        onTap: () => onTap(ProductAction.delete),
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
        goEntityEdit(context, '/products', product.id);
      case ProductAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'product',
          op: () =>
              services.products.archive(companyId: companyId, id: product.id),
        );
      case ProductAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'product',
          op: () =>
              services.products.restore(companyId: companyId, id: product.id),
        );
      case ProductAction.clone:
        // Strip identity-bearing fields so the create form opens with a
        // truly new draft seeded from the source product. The scaffold
        // calls `repo.create(...)` on save because `existingId == null`.
        final draft = product.copyWith(
          id: '',
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        context.go('/products/new', extra: draft);
      case ProductAction.delete:
        if (product.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.delete(
          context: context,
          wireName: 'product',
          op: () =>
              services.products.delete(companyId: companyId, id: product.id),
        );
      case ProductAction.newInvoice:
      case ProductAction.newQuote:
      case ProductAction.newPurchaseOrder:
      case ProductAction.setTaxCategory:
        break;
    }
  }
}
