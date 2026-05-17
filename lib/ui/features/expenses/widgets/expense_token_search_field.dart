import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
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
    final services = context.read<Services>();
    return StreamBuilder<Map<String, String>>(
      stream: services.clients
          .watchActiveNames(companyId: vm.companyId)
          .map((rows) => {
                for (final r in rows)
                  if (r.name.isNotEmpty) r.id: r.name,
              }),
      builder: (context, snap) {
        final names = snap.data ?? const <String, String>{};
        return TokenSearchField(
          vm: vm,
          filterKeys: buildExpenseFilterKeys(
            clients: services.clients,
            categories: services.expenseCategories,
            companyId: vm.companyId,
            nameForClientId: (id) => names[id],
          ),
          wide: wide,
          hintKey: 'search_expenses_or_filter_hint',
        );
      },
    );
  }
}
