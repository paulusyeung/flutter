import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/recurring_expenses/view_models/recurring_expense_edit_view_model.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/edit/recurring_expense_edit_amount_tax_section.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/edit/recurring_expense_edit_currency_conversion_section.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/edit/recurring_expense_edit_custom_fields_section.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/edit/recurring_expense_edit_identity_section.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/edit/recurring_expense_edit_invoicing_section.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/edit/recurring_expense_edit_notes_section.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/edit/recurring_expense_edit_schedule_section.dart';

/// Edit + Create form for a Recurring Expense.
///
/// Sections render top-to-bottom; the densest ones (Currency conversion,
/// Custom fields) start collapsed. The Schedule section always sits at
/// the top — it's the field set that distinguishes this entity from a
/// plain expense.
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
        );
      },
      titleWhileLoading: (ctx) => existingId == null
          ? ctx.tr('new_recurring_expense')
          : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_recurring_expense')
          : (vm.draft.number.isNotEmpty
              ? '${ctx.tr('edit')} · #${vm.draft.number}'
              : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => _RecurringExpenseEditBody(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (e) => e.id,
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

class _RecurringExpenseEditBody extends StatelessWidget {
  const _RecurringExpenseEditBody({required this.vm});
  final RecurringExpenseEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecurringExpenseEditScheduleSection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              RecurringExpenseEditIdentitySection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              RecurringExpenseEditAmountTaxSection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              RecurringExpenseEditInvoicingSection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              RecurringExpenseEditNotesSection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              _CollapsibleFormSection(
                title: context.tr('currency_conversion'),
                initiallyExpanded:
                    vm.draft.invoiceCurrencyId.isNotEmpty &&
                        vm.draft.invoiceCurrencyId != vm.draft.currencyId,
                child: RecurringExpenseEditCurrencyConversionSection(vm: vm),
              ),
              SizedBox(height: InSpacing.md(context)),
              _CollapsibleFormSection(
                title: context.tr('custom_fields'),
                initiallyExpanded: vm.draft.customValue1.isNotEmpty ||
                    vm.draft.customValue2.isNotEmpty ||
                    vm.draft.customValue3.isNotEmpty ||
                    vm.draft.customValue4.isNotEmpty,
                child: RecurringExpenseEditCustomFieldsSection(vm: vm),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Inline collapsible card — copied from `ExpenseEditScreen` rather than
/// promoted to a shared widget since the second consumer (this screen) is
/// the only one. Promote once a third shows up.
class _CollapsibleFormSection extends StatefulWidget {
  const _CollapsibleFormSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_CollapsibleFormSection> createState() =>
      _CollapsibleFormSectionState();
}

class _CollapsibleFormSectionState extends State<_CollapsibleFormSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      title: widget.title,
      trailing: IconButton(
        tooltip: _expanded
            ? context.tr('collapse')
            : context.tr('expand'),
        icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
        onPressed: () => setState(() => _expanded = !_expanded),
      ),
      child: AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: widget.child,
        crossFadeState: _expanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 150),
      ),
    );
  }
}
