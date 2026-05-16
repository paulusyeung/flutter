import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/purchase_order_dao.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/purchase_orders/view_models/purchase_order_list_view_model.dart';
import 'package:admin/ui/features/purchase_orders/widgets/purchase_order_actions.dart';
import 'package:admin/ui/features/purchase_orders/widgets/purchase_order_list_empty_state.dart';
import 'package:admin/ui/features/purchase_orders/widgets/purchase_order_list_tile.dart';
import 'package:admin/ui/features/purchase_orders/widgets/purchase_order_token_search_field.dart';

class PurchaseOrderListScreen extends StatelessWidget {
  const PurchaseOrderListScreen({
    super.key,
    this.vendorId,
    this.embedded = false,
  });

  /// When set, the list is filtered to one vendor.
  final String? vendorId;

  /// True when this list lives inside another screen's body.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<PurchaseOrder, PurchaseOrderListViewModel>(
      titleKey: 'purchase_orders',
      newRoute: '/purchase_orders/new',
      newLabelKey: 'new_purchase_order',
      emptyIcon: Icons.shopping_bag_outlined,
      emptyTitleKey: 'no_purchase_orders_yet',
      wantsFormatter: true,
      embedded: embedded,
      buildVm: (services, companyId) => PurchaseOrderListViewModel(
        repo: services.purchaseOrders,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
        vendorId: vendorId,
      ),
      sortOptions: (context) => [
        SortOption(
          id: PurchaseOrderFieldIds.number,
          label: context.tr('number'),
        ),
        SortOption(id: PurchaseOrderFieldIds.date, label: context.tr('date')),
        SortOption(
          id: PurchaseOrderFieldIds.dueDate,
          label: context.tr('due_date'),
        ),
        SortOption(
          id: PurchaseOrderFieldIds.amount,
          label: context.tr('amount'),
        ),
        SortOption(
          id: PurchaseOrderFieldIds.vendorId,
          label: context.tr('vendor'),
        ),
        SortOption(
          id: PurchaseOrderFieldIds.status,
          label: context.tr('status'),
        ),
        SortOption(
          id: PurchaseOrderFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          PurchaseOrderTokenSearchField(vm: vm, wide: wide),
      emptyStateBuilder: (context, vm) => PurchaseOrderListEmptyState(vm: vm),
      tileBuilder: (context, vm, po, index, options) {
        final isUrlSelected = options.selectedId == po.id;
        return PurchaseOrderListTile(
          purchaseOrder: po,
          columns: options.wide ? vm.columns : const [],
          wide: options.wide,
          isLast: options.isLast,
          selecting: options.selecting,
          selected: vm.isSelected(po.id) || isUrlSelected,
          urlSelected: isUrlSelected,
          onTap: options.selecting
              ? () => vm.toggleSelected(po.id)
              : isUrlSelected
              ? () => MasterDetailNavScope.requestClose(
                  context,
                  basePath: '/purchase_orders',
                )
              : () => goEntityRecord(context, vm.entityType, po.id),
          onLongPress: () => vm.toggleSelected(po.id),
          onSelectTap: () => vm.toggleSelected(po.id),
          onAction: options.selecting
              ? null
              : (action) => PurchaseOrderActions.dispatch(
                    context,
                    context.read<Services>(),
                    vm.companyId,
                    po,
                    action,
                  ),
        );
      },
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_purchase_order',
          pluralSuccessKey: 'archived_purchase_orders',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_purchase_order',
          pluralSuccessKey: 'restored_purchase_orders',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }
}
