import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/features/expense_categories/widgets/expense_category_actions.dart';

/// Wraps `EntityDetailActionsRow` with the ExpenseCategory action set.
/// Used by the detail screen's AppBar title slot.
class ExpenseCategoryDetailActionsRow extends StatelessWidget {
  const ExpenseCategoryDetailActionsRow({super.key, required this.category});

  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value!.currentCompanyId;
    return EntityDetailActionsRow<ExpenseCategoryAction>(
      items: ExpenseCategoryActions.itemsFor(
        context,
        category,
        (action) => ExpenseCategoryActions.dispatch(
          context,
          services,
          companyId,
          category,
          action,
        ),
      ),
    );
  }
}
