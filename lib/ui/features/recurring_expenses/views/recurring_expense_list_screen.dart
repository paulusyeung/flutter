import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/recurring_expense_dao.dart';
import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_column_headers.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/features/recurring_expenses/view_models/recurring_expense_list_view_model.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_actions.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_list_empty_state.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_list_tile.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_status_chip_strip.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_token_search_field.dart';

/// Recurring expenses list screen. Mirrors `ExpenseListScreen` plus a
/// 5-chip status filter strip rendered above the search field (narrow)
/// and the column header row (wide). Chip counts come from the repo's
/// per-status DAO stream so the badge reads true to the filter SQL.
class RecurringExpenseListScreen extends StatelessWidget {
  const RecurringExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<
      RecurringExpense,
      RecurringExpenseListViewModel
    >(
      titleKey: 'recurring_expenses',
      newRoute: '/recurring_expenses/new',
      newLabelKey: 'new_recurring_expense',
      emptyIcon: Icons.event_repeat_outlined,
      emptyTitleKey: 'no_recurring_expenses_yet',
      wantsFormatter: true,
      buildVm: (services, companyId) => RecurringExpenseListViewModel(
        repo: services.recurringExpenses,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
      ),
      sortOptions: (context) => [
        SortOption(
          id: RecurringExpenseFieldIds.nextSendDate,
          label: context.tr('next_send_date'),
        ),
        SortOption(
          id: RecurringExpenseFieldIds.date,
          label: context.tr('date'),
        ),
        SortOption(
          id: RecurringExpenseFieldIds.number,
          label: context.tr('number'),
        ),
        SortOption(
          id: RecurringExpenseFieldIds.amount,
          label: context.tr('amount'),
        ),
        SortOption(
          id: RecurringExpenseFieldIds.vendorId,
          label: context.tr('vendor'),
        ),
        SortOption(
          id: RecurringExpenseFieldIds.clientId,
          label: context.tr('client'),
        ),
        SortOption(
          id: RecurringExpenseFieldIds.categoryId,
          label: context.tr('category'),
        ),
        SortOption(
          id: RecurringExpenseFieldIds.frequency,
          label: context.tr('frequency'),
        ),
        SortOption(
          id: RecurringExpenseFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      // Stack the chip strip on top of the search field so both narrow
      // and wide modes get it. Wide mode also surfaces the strip above
      // column headers via [wideColumnHeadersBuilder].
      searchFieldBuilder: (context, vm, wide) {
        final search = RecurringExpenseTokenSearchField(vm: vm, wide: wide);
        if (wide) {
          // Wide-mode chips render above the column headers — keep the
          // search field tight in the app bar.
          return search;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            search,
            RecurringExpenseStatusChipStrip(vm: vm),
          ],
        );
      },
      wideColumnHeadersBuilder: (context, vm) {
        final tokens = context.inTheme;
        return Container(
          decoration: BoxDecoration(
            border: BorderDirectional(
              bottom: BorderSide(color: tokens.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              RecurringExpenseStatusChipStrip(vm: vm),
              EntityListColumnHeaders<RecurringExpense>(vm: vm),
            ],
          ),
        );
      },
      emptyStateBuilder: (context, vm) =>
          RecurringExpenseListEmptyState(vm: vm),
      tileBuilder: (context, vm, recurringExpense, index, options) =>
          RecurringExpenseListTile(
            recurringExpense: recurringExpense,
            columns: options.wide ? vm.columns : const [],
            wide: options.wide,
            isLast: options.isLast,
            selecting: options.selecting,
            selected: vm.isSelected(recurringExpense.id),
            onTap: options.selecting
                ? () => vm.toggleSelected(recurringExpense.id)
                : () => context.go('/recurring_expenses/${recurringExpense.id}'),
            onLongPress: () => vm.toggleSelected(recurringExpense.id),
            onSelectTap: () => vm.toggleSelected(recurringExpense.id),
            onAction: options.selecting
                ? null
                : (action) => RecurringExpenseActions.dispatch(
                      context,
                      context.read<Services>(),
                      vm.companyId,
                      recurringExpense,
                      action,
                    ),
          ),
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'start',
          icon: Icons.play_arrow_outlined,
          tooltipKey: 'start',
          singleSuccessKey: 'started_recurring_expense',
          pluralSuccessKey: 'started_recurring_expenses',
          nothingKey: 'nothing_to_start',
        ),
        EntityListBulkAction(
          actionId: 'stop',
          icon: Icons.stop_outlined,
          tooltipKey: 'stop',
          singleSuccessKey: 'stopped_recurring_expense',
          pluralSuccessKey: 'stopped_recurring_expenses',
          nothingKey: 'nothing_to_stop',
        ),
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_recurring_expense',
          pluralSuccessKey: 'archived_recurring_expenses',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_recurring_expense',
          pluralSuccessKey: 'restored_recurring_expenses',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }
}
