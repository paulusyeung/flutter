import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/payment_dao.dart';
import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/payments/view_models/payment_edit_view_model.dart';
import 'package:admin/ui/features/payments/view_models/payment_list_view_model.dart';
import 'package:admin/ui/features/payments/widgets/payment_actions.dart';
import 'package:admin/ui/features/payments/widgets/payment_list_empty_state.dart';
import 'package:admin/ui/features/payments/widgets/payment_list_tile.dart';
import 'package:admin/ui/features/payments/widgets/payment_token_search_field.dart';

/// Payments list screen.
class PaymentListScreen extends StatelessWidget {
  const PaymentListScreen({
    super.key,
    this.clientId,
    this.embedded = false,
  });

  /// When set, the list is filtered to one client.
  final String? clientId;

  /// True when this list lives inside another screen's body.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final cid = clientId;
    return EntityListScreenScaffold<Payment, PaymentListViewModel>(
      titleKey: 'payments',
      newRoute: '/payments/new',
      newLabelKey: 'new_payment',
      embeddedNewOverride: cid == null
          ? null
          : (ctx) => ctx.go(
                '/payments/new',
                extra: emptyPayment().copyWith(clientId: cid),
              ),
      emptyIcon: Icons.payments_outlined,
      emptyTitleKey: 'no_payments_yet',
      wantsFormatter: true,
      embedded: embedded,
      buildVm: (services, companyId) => PaymentListViewModel(
        repo: services.payments,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
        clientId: clientId,
      ),
      sortOptions: (context) => [
        SortOption(id: PaymentFieldIds.date, label: context.tr('date')),
        SortOption(id: PaymentFieldIds.number, label: context.tr('number')),
        SortOption(id: PaymentFieldIds.amount, label: context.tr('amount')),
        SortOption(id: PaymentFieldIds.applied, label: context.tr('applied')),
        SortOption(id: PaymentFieldIds.refunded, label: context.tr('refunded')),
        SortOption(id: PaymentFieldIds.clientId, label: context.tr('client')),
        SortOption(id: PaymentFieldIds.typeId, label: context.tr('type')),
        SortOption(
          id: PaymentFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          PaymentTokenSearchField(vm: vm, wide: wide),
      emptyStateBuilder: (context, vm) => PaymentListEmptyState(vm: vm),
      tileBuilder: (context, vm, payment, index, options) {
        final isUrlSelected = options.selectedId == payment.id;
        return PaymentListTile(
          payment: payment,
          columns: options.wide ? vm.columns : const [],
          wide: options.wide,
          isLast: options.isLast,
          selecting: options.selecting,
          selected: vm.isSelected(payment.id) || isUrlSelected,
          urlSelected: isUrlSelected,
          onTap: options.selecting
              ? () => vm.toggleSelected(payment.id)
              : isUrlSelected
              ? () => MasterDetailNavScope.requestClose(
                  context,
                  basePath: '/payments',
                )
              : () => goEntityRecord(context, vm.entityType, payment.id),
          onLongPress: () => vm.toggleSelected(payment.id),
          onSelectTap: () => vm.toggleSelected(payment.id),
          onAction: options.selecting
              ? null
              : (action) => PaymentActions.dispatch(
                    context,
                    context.read<Services>(),
                    vm.companyId,
                    payment,
                    action,
                  ),
        );
      },
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_payment',
          pluralSuccessKey: 'archived_payments',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_payment',
          pluralSuccessKey: 'restored_payments',
          nothingKey: 'nothing_to_restore',
        ),
        EntityListBulkAction(
          actionId: 'delete',
          icon: Icons.delete_outline,
          tooltipKey: 'delete',
          singleSuccessKey: 'deleted_payment',
          pluralSuccessKey: 'deleted_payments',
          nothingKey: 'nothing_to_delete',
        ),
      ],
    );
  }
}
