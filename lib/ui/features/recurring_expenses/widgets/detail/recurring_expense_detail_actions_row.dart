import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_actions.dart';

/// Thin wrapper that ties [EntityDetailActionsRow] to the recurring
/// expense action enum.
class RecurringExpenseDetailActionsRow extends StatelessWidget {
  const RecurringExpenseDetailActionsRow({
    super.key,
    required this.recurringExpense,
    required this.onAction,
  });

  final RecurringExpense recurringExpense;
  final void Function(RecurringExpenseAction) onAction;

  @override
  Widget build(BuildContext context) {
    return EntityDetailActionsRow<RecurringExpenseAction>(
      items: RecurringExpenseActions.itemsFor(
        context,
        recurringExpense,
        onAction,
      ),
    );
  }
}
