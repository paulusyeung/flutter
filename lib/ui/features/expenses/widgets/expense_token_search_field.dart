import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/expenses/view_models/expense_list_view_model.dart';
import 'package:admin/ui/features/expenses/widgets/expense_filter_keys.dart';

/// Thin wrapper that wires [TokenSearchField] for the expenses list.
class ExpenseTokenSearchField extends StatelessWidget {
  const ExpenseTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final ExpenseListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TokenSearchField(
      vm: vm,
      filterKeys: buildExpenseFilterKeys(),
      wide: wide,
      hintKey: 'search_expenses_or_filter_hint',
    );
  }
}
