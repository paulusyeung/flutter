import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/recurring_invoice_dao.dart';
import 'package:admin/data/models/domain/recurring_invoice.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/recurring_invoices/view_models/recurring_invoice_list_view_model.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/recurring_invoice_actions.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/recurring_invoice_list_empty_state.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/recurring_invoice_list_tile.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/recurring_invoice_token_search_field.dart';

class RecurringInvoiceListScreen extends StatelessWidget {
  const RecurringInvoiceListScreen({
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
    return EntityListScreenScaffold<RecurringInvoice,
        RecurringInvoiceListViewModel>(
      titleKey: 'recurring_invoices',
      newRoute: '/recurring_invoices/new',
      newLabelKey: 'new_recurring_invoice',
      emptyIcon: Icons.event_repeat_outlined,
      emptyTitleKey: 'no_recurring_invoices_yet',
      wantsFormatter: true,
      embedded: embedded,
      buildVm: (services, companyId) => RecurringInvoiceListViewModel(
        repo: services.recurringInvoices,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
        clientId: clientId,
      ),
      sortOptions: (context) => [
        SortOption(
          id: RecurringInvoiceFieldIds.number,
          label: context.tr('number'),
        ),
        SortOption(
          id: RecurringInvoiceFieldIds.amount,
          label: context.tr('amount'),
        ),
        SortOption(
          id: RecurringInvoiceFieldIds.clientId,
          label: context.tr('client'),
        ),
        SortOption(
          id: RecurringInvoiceFieldIds.status,
          label: context.tr('status'),
        ),
        SortOption(
          id: RecurringInvoiceFieldIds.nextSendDate,
          label: context.tr('next_send_date'),
        ),
        SortOption(
          id: RecurringInvoiceFieldIds.frequencyId,
          label: context.tr('frequency'),
        ),
        SortOption(
          id: RecurringInvoiceFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          RecurringInvoiceTokenSearchField(vm: vm, wide: wide),
      emptyStateBuilder: (context, vm) =>
          RecurringInvoiceListEmptyState(vm: vm),
      tileBuilder: (context, vm, ri, index, options) {
        final isUrlSelected = options.selectedId == ri.id;
        return RecurringInvoiceListTile(
          recurringInvoice: ri,
          columns: options.wide ? vm.columns : const [],
          wide: options.wide,
          isLast: options.isLast,
          selecting: options.selecting,
          selected: vm.isSelected(ri.id) || isUrlSelected,
          urlSelected: isUrlSelected,
          onTap: options.selecting
              ? () => vm.toggleSelected(ri.id)
              : isUrlSelected
              ? () => MasterDetailNavScope.requestClose(
                  context,
                  basePath: '/recurring_invoices',
                )
              : () => goEntityRecord(context, vm.entityType, ri.id),
          onLongPress: () => vm.toggleSelected(ri.id),
          onSelectTap: () => vm.toggleSelected(ri.id),
          onAction: options.selecting
              ? null
              : (action) => RecurringInvoiceActions.dispatch(
                    context,
                    context.read<Services>(),
                    vm.companyId,
                    ri,
                    action,
                  ),
        );
      },
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_recurring_invoice',
          pluralSuccessKey: 'archived_recurring_invoices',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_recurring_invoice',
          pluralSuccessKey: 'restored_recurring_invoices',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }
}
