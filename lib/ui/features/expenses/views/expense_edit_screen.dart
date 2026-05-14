import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_layout.dart';

/// Edit + Create form for an Expense.
///
/// Layout is delegated to [ExpenseEditLayout], which mirrors the v2 two-column
/// pattern: main column (Identity / Amount / Payment) + 360 px sidebar
/// (Notes / Invoicing / collapsibles) on widths ≥1100 px, single column
/// otherwise. The three densest sections (Currency conversion, Banking,
/// Custom fields) start collapsed per the UX spec § Progressive disclosure.
class ExpenseEditScreen extends StatelessWidget {
  const ExpenseEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;

  /// When non-null and [existingId] is null, the create form opens
  /// pre-filled with this expense's fields. Identity-bearing fields (id,
  /// number, timestamps, invoice link, payment metadata) should already
  /// be stripped by the caller.
  final Expense? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Expense, ExpenseEditViewModel>(
      existingId: existingId,
      entityTypeName: 'expense',
      fetchExisting: (ctx, services, companyId, id) =>
          services.expenses.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        return ExpenseEditViewModel(
          repo: services.expenses,
          companyId: companyId,
          existing: existing,
          cloneFrom: cloneFrom,
        );
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_expense') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_expense')
          : (vm.draft.number.isNotEmpty
              ? '${ctx.tr('edit')} · #${vm.draft.number}'
              : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => ExpenseEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (e) => e.id,
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/expenses/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
