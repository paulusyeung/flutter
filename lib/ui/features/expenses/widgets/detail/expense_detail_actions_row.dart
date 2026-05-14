import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/features/expenses/widgets/expense_actions.dart';

/// Thin wrapper that ties [EntityDetailActionsRow] to the Expense action
/// enum so the detail screen can keep its body free of action-set wiring.
class ExpenseDetailActionsRow extends StatelessWidget {
  const ExpenseDetailActionsRow({
    super.key,
    required this.expense,
    required this.onAction,
  });

  final Expense expense;
  final void Function(ExpenseAction) onAction;

  @override
  Widget build(BuildContext context) {
    return EntityDetailActionsRow<ExpenseAction>(
      items: ExpenseActions.itemsFor(context, expense, onAction),
    );
  }
}
