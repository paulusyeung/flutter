import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/purchase_orders/view_models/purchase_order_edit_view_model.dart';
import 'package:admin/ui/features/purchase_orders/widgets/edit/purchase_order_edit_layout.dart';

class PurchaseOrderEditScreen extends StatelessWidget {
  const PurchaseOrderEditScreen({
    this.existingId,
    this.cloneFrom,
    super.key,
  });

  final String? existingId;
  final PurchaseOrder? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<PurchaseOrder, PurchaseOrderEditViewModel>(
      existingId: existingId,
      entityTypeName: 'purchase_order',
      fetchExisting: (ctx, services, companyId, id) =>
          services.purchaseOrders.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        return PurchaseOrderEditViewModel(
          repo: services.purchaseOrders,
          companyId: companyId,
          existing: existing,
          cloneFrom: cloneFrom,
        );
      },
      titleWhileLoading: (ctx) => existingId == null
          ? ctx.tr('new_purchase_order')
          : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_purchase_order')
          : (vm.draft.number.isNotEmpty
              ? '${ctx.tr('edit')} · #${vm.draft.number}'
              : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => PurchaseOrderEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (p) => p.id,
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
