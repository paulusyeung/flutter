import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/invoice_dao.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_list_view_model.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_actions.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_list_empty_state.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_list_tile.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_token_search_field.dart';

/// Invoices list screen — pure config + per-entity widgets. Mirrors
/// `ExpenseListScreen`; the screen-level chrome lives in
/// `EntityListScreenScaffold`. M2 adds the status-filter chip strip via
/// the scaffold's `extraAppBarActions` slot; M3 adds the sticky-totals
/// footer.
class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<Invoice, InvoiceListViewModel>(
      titleKey: 'invoices',
      newRoute: '/invoices/new',
      newLabelKey: 'new_invoice',
      emptyIcon: Icons.receipt_long_outlined,
      emptyTitleKey: 'no_invoices_yet',
      wantsFormatter: true,
      buildVm: (services, companyId) => InvoiceListViewModel(
        repo: services.invoices,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
      ),
      sortOptions: (context) => [
        SortOption(id: InvoiceFieldIds.number, label: context.tr('number')),
        SortOption(id: InvoiceFieldIds.date, label: context.tr('invoice_date')),
        SortOption(id: InvoiceFieldIds.dueDate, label: context.tr('due_date')),
        SortOption(id: InvoiceFieldIds.amount, label: context.tr('amount')),
        SortOption(id: InvoiceFieldIds.balance, label: context.tr('balance')),
        SortOption(id: InvoiceFieldIds.clientId, label: context.tr('client')),
        SortOption(id: InvoiceFieldIds.status, label: context.tr('status')),
        SortOption(
          id: InvoiceFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          InvoiceTokenSearchField(vm: vm, wide: wide),
      emptyStateBuilder: (context, vm) => InvoiceListEmptyState(vm: vm),
      tileBuilder: (context, vm, invoice, index, options) {
        final isUrlSelected = options.selectedId == invoice.id;
        return InvoiceListTile(
          invoice: invoice,
          columns: options.wide ? vm.columns : const [],
          wide: options.wide,
          isLast: options.isLast,
          selecting: options.selecting,
          selected: vm.isSelected(invoice.id) || isUrlSelected,
          urlSelected: isUrlSelected,
          onTap: options.selecting
              ? () => vm.toggleSelected(invoice.id)
              : isUrlSelected
              ? () => context.go('/invoices')
              : () => context.go('/invoices/${invoice.id}'),
          onLongPress: () => vm.toggleSelected(invoice.id),
          onSelectTap: () => vm.toggleSelected(invoice.id),
          onAction: options.selecting
              ? null
              : (action) => InvoiceActions.dispatch(
                    context,
                    context.read<Services>(),
                    vm.companyId,
                    invoice,
                    action,
                  ),
        );
      },
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_invoice',
          pluralSuccessKey: 'archived_invoices',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_invoice',
          pluralSuccessKey: 'restored_invoices',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }
}
