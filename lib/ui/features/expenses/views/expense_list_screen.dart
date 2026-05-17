import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/expense_dao.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/expenses/view_models/expense_list_view_model.dart';
import 'package:admin/ui/features/expenses/widgets/expense_actions.dart';
import 'package:admin/ui/features/expenses/widgets/expense_list_empty_state.dart';
import 'package:admin/ui/features/expenses/widgets/expense_list_tile.dart';
import 'package:admin/ui/features/expenses/widgets/expense_token_search_field.dart';

/// Expenses list screen — pure config + per-entity widgets. Mirrors
/// `ProjectListScreen`; the screen-level chrome lives in
/// `EntityListScreenScaffold`.
class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({
    super.key,
    this.clientId,
    this.vendorId,
    this.embedded = false,
  });

  /// When set, the list is filtered to one client.
  final String? clientId;

  /// When set, the list is filtered to one vendor.
  final String? vendorId;

  /// True when this list lives inside another screen's body.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<Expense, ExpenseListViewModel>(
      titleKey: 'expenses',
      newRoute: '/expenses/new',
      newLabelKey: 'new_expense',
      emptyIcon: Icons.account_balance_wallet_outlined,
      emptyTitleKey: 'no_expenses_yet',
      wantsFormatter: true,
      embedded: embedded,
      buildVm: (services, companyId) => ExpenseListViewModel(
        repo: services.expenses,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
        clientId: clientId,
        vendorId: vendorId,
      ),
      sortOptions: (context) => [
        SortOption(id: ExpenseFieldIds.date, label: context.tr('date')),
        SortOption(id: ExpenseFieldIds.number, label: context.tr('number')),
        SortOption(id: ExpenseFieldIds.amount, label: context.tr('amount')),
        SortOption(id: ExpenseFieldIds.vendorId, label: context.tr('vendor')),
        SortOption(id: ExpenseFieldIds.clientId, label: context.tr('client')),
        SortOption(
          id: ExpenseFieldIds.categoryId,
          label: context.tr('category'),
        ),
        SortOption(
          id: ExpenseFieldIds.paymentDate,
          label: context.tr('payment_date'),
        ),
        SortOption(
          id: ExpenseFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          ExpenseTokenSearchField(vm: vm, wide: wide),
      emptyStateBuilder: (context, vm) => ExpenseListEmptyState(vm: vm),
      tileBuilder: (context, vm, expense, index, options) {
        final isUrlSelected = options.selectedId == expense.id;
        return ExpenseListTile(
          expense: expense,
          columns: options.wide ? vm.columns : const [],
          wide: options.wide,
          isLast: options.isLast,
          selecting: options.selecting,
          selected: vm.isSelected(expense.id) || isUrlSelected,
          urlSelected: isUrlSelected,
          onTap: options.selecting
              ? () => vm.toggleSelected(expense.id)
              : isUrlSelected
              ? () => MasterDetailNavScope.requestClose(
                  context,
                  basePath: '/expenses',
                )
              : () => goEntityRecord(context, vm.entityType, expense.id),
          onLongPress: () => vm.toggleSelected(expense.id),
          onSelectTap: () => vm.toggleSelected(expense.id),
          onAction: options.selecting
              ? null
              : (action) => ExpenseActions.dispatch(
                    context,
                    context.read<Services>(),
                    vm.companyId,
                    expense,
                    action,
                  ),
        );
      },
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_expense',
          pluralSuccessKey: 'archived_expenses',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_expense',
          pluralSuccessKey: 'restored_expenses',
          nothingKey: 'nothing_to_restore',
        ),
        EntityListBulkAction(
          actionId: 'delete',
          icon: Icons.delete_outline,
          tooltipKey: 'delete',
          singleSuccessKey: 'deleted_expense',
          pluralSuccessKey: 'deleted_expenses',
          nothingKey: 'nothing_to_delete',
        ),
      ],
    );
  }
}
