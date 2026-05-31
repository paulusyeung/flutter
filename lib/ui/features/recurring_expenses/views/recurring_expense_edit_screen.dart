import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/recurring_expenses/view_models/recurring_expense_edit_view_model.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/edit/recurring_expense_edit_layout.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_actions.dart';

/// Edit + Create form for a Recurring Expense.
///
/// Layout is delegated to [RecurringExpenseEditLayout], which mirrors the
/// v2 two-column pattern: main column (Schedule / Identity / Amount/Tax) +
/// 360 px sidebar (Notes / Invoicing / collapsibles) on widths ≥1100 px,
/// single column otherwise. Schedule sits first — it's the field set that
/// distinguishes this entity from a plain expense.
class RecurringExpenseEditScreen extends StatelessWidget {
  const RecurringExpenseEditScreen({
    this.existingId,
    this.cloneFrom,
    super.key,
  });

  final String? existingId;
  final RecurringExpense? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<
      RecurringExpense,
      RecurringExpenseEditViewModel
    >(
      existingId: existingId,
      entityTypeName: 'recurring_expense',
      fetchExisting: (ctx, services, companyId, id) =>
          services.recurringExpenses.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        return RecurringExpenseEditViewModel(
          repo: services.recurringExpenses,
          companyId: companyId,
          existing: existing,
          cloneFrom: cloneFrom,
          sync: services.sync,
          connectivity: services.connectivity,
        );
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_recurring_expense') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_recurring_expense')
          : (vm.draft.number.isNotEmpty
                ? '${ctx.tr('edit')} · #${vm.draft.number}'
                : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => RecurringExpenseEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (e) => e.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<RecurringExpenseAction>(
            leading: saveButton,
            items: filterForEditScreen(
              RecurringExpenseActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: RecurringExpenseActions.isLifecycle,
            ),
          ),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return RecurringExpenseActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as RecurringExpenseAction,
        );
      },
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/recurring_expenses/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
