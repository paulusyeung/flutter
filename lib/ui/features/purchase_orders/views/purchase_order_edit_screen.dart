import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/purchase_orders/view_models/purchase_order_edit_view_model.dart';
import 'package:admin/ui/features/purchase_orders/widgets/edit/purchase_order_edit_layout.dart';
import 'package:admin/ui/features/purchase_orders/widgets/purchase_order_actions.dart';

class PurchaseOrderEditScreen extends StatelessWidget {
  const PurchaseOrderEditScreen({
    this.existingId,
    this.cloneFrom,
    this.prefillProductId,
    super.key,
  });

  final String? existingId;
  final PurchaseOrder? cloneFrom;

  /// Optional product id seed (`?product=<id>`). In create mode the VM
  /// resolves the product and appends one line item built from it. Drives
  /// the Product kebab → "New Purchase Order" flow. URL params survive
  /// cross-branch nav reliably, where `extra:` payloads are not.
  final String? prefillProductId;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<PurchaseOrder, PurchaseOrderEditViewModel>(
      existingId: existingId,
      entityTypeName: 'purchase_order',
      fetchExisting: (ctx, services, companyId, id) =>
          services.purchaseOrders.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        final vm = PurchaseOrderEditViewModel(
          repo: services.purchaseOrders,
          companyId: companyId,
          vendorRequiredMessage: ctx.tr('please_select_a_vendor'),
          existing: existing,
          cloneFrom: cloneFrom,
        );
        // Seed a line item from `?product=<id>` on first build (create
        // mode only). See InvoiceEditScreen for the rationale — URL params
        // are the reliable seed channel across cross-branch nav, and the
        // postFrame deferral ensures the scaffold's listeners are attached
        // before notifyListeners fires (otherwise LineItemTableDesktop's
        // cached `_rows` never picks up the seed).
        final productSeedId = prefillProductId;
        if (productSeedId != null &&
            productSeedId.isNotEmpty &&
            existing == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(
              services.products
                  .watch(companyId: companyId, id: productSeedId)
                  .first
                  .then((product) {
                    if (product == null) return;
                    vm.addLineItem(lineItemForProduct(product));
                  })
                  .catchError((Object _) {}),
            );
          });
        }
        return vm;
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_purchase_order') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_purchase_order')
          : (vm.draft.number.isNotEmpty
                ? '${ctx.tr('edit')} · #${vm.draft.number}'
                : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => PurchaseOrderEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (p) => p.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<PurchaseOrderAction>(
            leading: saveButton,
            items: filterForEditScreen(
              PurchaseOrderActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: PurchaseOrderActions.isLifecycle,
            ),
          ),
      saveParamFor: (a) =>
          PurchaseOrderActions.saveParamFor(a as PurchaseOrderAction),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return PurchaseOrderActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as PurchaseOrderAction,
        );
      },
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/purchase_orders/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
