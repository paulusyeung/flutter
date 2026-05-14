import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/recurring_expenses/view_models/recurring_expense_list_view_model.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_filter_keys.dart';

/// Thin wrapper that wires [TokenSearchField] for the Recurring Expenses
/// list. Mirrors `ExpenseTokenSearchField`.
class RecurringExpenseTokenSearchField extends StatelessWidget {
  const RecurringExpenseTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final RecurringExpenseListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TokenSearchField(
      vm: vm,
      filterKeys: buildRecurringExpenseFilterKeys(),
      wide: wide,
      hintKey: 'search_recurring_expenses_or_filter_hint',
    );
  }
}
