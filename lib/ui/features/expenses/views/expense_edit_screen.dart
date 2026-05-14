import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_amount_tax_section.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_banking_section.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_currency_conversion_section.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_custom_fields_section.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_identity_section.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_invoicing_section.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_notes_section.dart';
import 'package:admin/ui/features/expenses/widgets/edit/expense_edit_payment_section.dart';

/// Edit + Create form for an Expense.
///
/// Sections are laid out top-to-bottom; the three densest ones (Currency
/// conversion, Banking, Custom fields) start collapsed per the UX spec §
/// Progressive disclosure. Identity, Amount/Tax, Payment, Invoicing, and
/// Notes start visible.
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
      bodyBuilder: (ctx, vm) => _ExpenseEditBody(vm: vm),
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

class _ExpenseEditBody extends StatelessWidget {
  const _ExpenseEditBody({required this.vm});
  final ExpenseEditViewModel vm;

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
              ExpenseEditIdentitySection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              ExpenseEditAmountTaxSection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              ExpenseEditPaymentSection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              ExpenseEditInvoicingSection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              ExpenseEditNotesSection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              _CollapsibleFormSection(
                title: context.tr('currency_conversion'),
                initiallyExpanded:
                    vm.draft.invoiceCurrencyId.isNotEmpty &&
                        vm.draft.invoiceCurrencyId != vm.draft.currencyId,
                child: ExpenseEditCurrencyConversionSection(vm: vm),
              ),
              SizedBox(height: InSpacing.md(context)),
              _CollapsibleFormSection(
                title: context.tr('banking'),
                initiallyExpanded: vm.draft.bankId.isNotEmpty ||
                    vm.draft.transactionId.isNotEmpty,
                child: ExpenseEditBankingSection(vm: vm),
              ),
              SizedBox(height: InSpacing.md(context)),
              _CollapsibleFormSection(
                title: context.tr('custom_fields'),
                initiallyExpanded: vm.draft.customValue1.isNotEmpty ||
                    vm.draft.customValue2.isNotEmpty ||
                    vm.draft.customValue3.isNotEmpty ||
                    vm.draft.customValue4.isNotEmpty,
                child: ExpenseEditCustomFieldsSection(vm: vm),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Small collapsible card. Wraps the children in a [DashboardCardShell]
/// header that toggles a chevron; when expanded, the body renders inside
/// the same card's interior padding. Kept inline (rather than promoting to
/// a shared widget) because the only consumer today is the expense edit
/// form — promote when a second screen needs the same shape.
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
