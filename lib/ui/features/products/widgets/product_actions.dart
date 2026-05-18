import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_edit_view_model.dart';
import 'package:admin/ui/features/products/widgets/tax_category_dialog.dart';
import 'package:admin/ui/features/purchase_orders/view_models/purchase_order_edit_view_model.dart';
import 'package:admin/ui/features/quotes/view_models/quote_edit_view_model.dart';

/// Action set surfaced for a product. Mirrors `ClientAction`. The
/// new-document branches seed a draft with this product as a line item;
/// `setTaxCategory` opens a fixed-catalog picker and saves via the normal
/// update outbox. Consumed by both the detail-screen header and the
/// list-row popup.
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
        context.go(
          '/invoices/new',
          extra: emptyInvoice().copyWith(lineItems: [_lineItemFor(product)]),
        );
      case ProductAction.newQuote:
        if (product.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/quotes/new',
          extra: emptyQuote().copyWith(lineItems: [_lineItemFor(product)]),
        );
      case ProductAction.newPurchaseOrder:
        if (product.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/purchase_orders/new',
          extra: emptyPurchaseOrder().copyWith(
            lineItems: [_lineItemFor(product)],
          ),
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

/// Seed a billing line item from a product — the same shape the edit form
/// produces when a user picks a product from the line-item product picker.
/// `cost` carries the sale `price` (what the customer is billed).
LineItem _lineItemFor(Product product) => emptyLineItem().copyWith(
  productKey: product.productKey,
  notes: product.notes,
  cost: product.price,
  taxName1: product.taxName1,
  taxRate1: product.taxRate1,
  taxName2: product.taxName2,
  taxRate2: product.taxRate2,
  taxName3: product.taxName3,
  taxRate3: product.taxRate3,
);
