import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/products/widgets/tax_category_dialog.dart';

/// Action set surfaced for a product. Mirrors `ClientAction`. The
/// new-document branches seed a draft with this product as a line item;
/// `setTaxCategory` opens a fixed-catalog picker and saves via the normal
/// update outbox. Consumed by both the detail-screen header and the
/// list-row popup.
enum ProductAction {
  edit,
  newGroup,
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

  /// Actions the old admin-portal hid on a brand-new (unsaved) record.
  /// Fed to `filterForEditScreen` so the create screen drops clone /
  /// archive / restore / delete.
  static bool isLifecycle(ProductAction action) {
    switch (action) {
      case ProductAction.clone:
      case ProductAction.archive:
      case ProductAction.restore:
      case ProductAction.delete:
        return true;
      default:
        return false;
    }
  }

  static List<EntityActionItem<ProductAction>> itemsFor(
    BuildContext context,
    Product product,
    void Function(ProductAction) onTap,
  ) {
    final canArchive = product.archivedAt == null && !product.isDeleted;
    final canRestore = product.archivedAt != null || product.isDeleted;
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final notTmp = !product.id.startsWith('tmp_');
    // Purge is admin/owner-only — mirrors the Client gate so the action
    // only renders when the user could plausibly run it.

    return [
      editActionItem(
        context: context,
        kind: ProductAction.edit,
        onTap: () => onTap(ProductAction.edit),
      ),
      // The "New X" items collapse into one fly-out submenu (like Client)
      // so they stop burying the rest of the actions menu.
      if ((me?.moduleEnabled(EntityType.invoice) ?? false) ||
          (me?.moduleEnabled(EntityType.quote) ?? false) ||
          (me?.moduleEnabled(EntityType.purchaseOrder) ?? false))
        newGroupActionItem(
          context: context,
          kind: ProductAction.newGroup,
          children: [
            if (me?.moduleEnabled(EntityType.invoice) ?? false)
              EntityActionItem(
                kind: ProductAction.newInvoice,
                icon: Icons.receipt_long_outlined,
                label: context.tr('new_invoice'),
                enabled: notTmp,
                onTap: () => onTap(ProductAction.newInvoice),
              ),
            if (me?.moduleEnabled(EntityType.quote) ?? false)
              EntityActionItem(
                kind: ProductAction.newQuote,
                icon: Icons.request_quote_outlined,
                label: context.tr('new_quote'),
                enabled: notTmp,
                onTap: () => onTap(ProductAction.newQuote),
              ),
            if (me?.moduleEnabled(EntityType.purchaseOrder) ?? false)
              EntityActionItem(
                kind: ProductAction.newPurchaseOrder,
                icon: Icons.shopping_cart_outlined,
                label: context.tr('new_purchase_order'),
                enabled: notTmp,
                onTap: () => onTap(ProductAction.newPurchaseOrder),
              ),
          ],
        ),
      EntityActionItem(
        kind: ProductAction.setTaxCategory,
        icon: Icons.percent,
        label: context.tr('set_tax_category'),
        enabled: notTmp,
        onTap: () => onTap(ProductAction.setTaxCategory),
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
      case ProductAction.newGroup:
        break; // Submenu parent — never dispatched; children carry the action.
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
        if (product.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        // Encode the product id as a URL query param rather than passing a
        // pre-built Invoice draft via `extra:`. URL params survive every
        // hop go_router makes (cross-StatefulShellRoute-branch nav,
        // serialization round-trips, State persistence in IndexedStack)
        // — `extra:` does not, reliably. Mirrors the `?project=<id>`
        // pattern in `entity_modules.dart`; the destination edit screen
        // watches the product from the repo and seeds a line item after
        // the VM is built.
        GoRouter.of(context).go(
          '/invoices/new?view=full&product=${Uri.encodeQueryComponent(product.id)}',
        );
      case ProductAction.newQuote:
        if (product.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        GoRouter.of(context).go(
          '/quotes/new?view=full&product=${Uri.encodeQueryComponent(product.id)}',
        );
      case ProductAction.newPurchaseOrder:
        if (product.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        GoRouter.of(context).go(
          '/purchase_orders/new?view=full&product=${Uri.encodeQueryComponent(product.id)}',
        );
      case ProductAction.setTaxCategory:
        if (product.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        final categoryId = await showTaxCategoryDialog(
          context,
          current: product.taxCategoryId,
        );
        if (categoryId == null || !context.mounted) return;
        if (categoryId == product.taxCategoryId) return;
        await services.products.save(
          companyId: companyId,
          product: product.copyWith(taxCategoryId: categoryId),
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('updated_product'));
    }
  }
}
