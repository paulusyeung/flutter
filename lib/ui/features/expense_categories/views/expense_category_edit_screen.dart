import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/expense_categories/view_models/expense_category_edit_view_model.dart';
import 'package:admin/ui/features/expense_categories/widgets/expense_category_actions.dart';
import 'package:admin/ui/features/settings/widgets/accent_swatch_grid.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';

/// Edit + Create form for an Expense Category. Wrapped in
/// [SettingsFormShell] so the form respects the standard Settings max-width
/// + padding (the screen is reached from Settings → Advanced); the inner
/// [FormSection] carries the bordered-card chrome.
class ExpenseCategoryEditScreen extends StatelessWidget {
  const ExpenseCategoryEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;

  /// When non-null and [existingId] is null, the create form opens
  /// pre-filled with this category's fields (Clone action). Identity-bearing
  /// fields should already be stripped by the caller.
  final ExpenseCategory? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<
      ExpenseCategory,
      ExpenseCategoryEditViewModel
    >(
      existingId: existingId,
      entityTypeName: 'expense_category',
      fetchExisting: (ctx, services, companyId, id) =>
          services.expenseCategories.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) =>
          ExpenseCategoryEditViewModel(
            repo: services.expenseCategories,
            companyId: companyId,
            existing: existing,
            cloneFrom: cloneFrom,
            sync: services.sync,
            connectivity: services.connectivity,
          ),
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_expense_category') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_expense_category')
          : (vm.draft.name.isNotEmpty
                ? '${ctx.tr('edit')} · ${vm.draft.name}'
                : ctx.tr('edit')),
      // Block Save when name is empty — a nameless category would render as
      // its UUID in the picker.
      canSave: (vm) =>
          !vm.isSaving && vm.isDirty && vm.draft.name.trim().isNotEmpty,
      bodyBuilder: (ctx, vm) => SettingsFormShell(
        sections: [
          FormSection(
            title: ctx.tr('expense_category'),
            children: [
              SettingsTextField(
                initialValue: vm.draft.name,
                labelKey: 'name',
                onChanged: vm.setName,
                errorText: vm.fieldErrorFor('name'),
                externalSyncKey: vm.original?.id,
              ),
              _ColorField(vm: vm),
            ],
          ),
        ],
      ),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (c) => c.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<ExpenseCategoryAction>(
            leading: saveButton,
            items: filterForEditScreen(
              ExpenseCategoryActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: ExpenseCategoryActions.isLifecycle,
            ),
          ),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return ExpenseCategoryActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as ExpenseCategoryAction,
        );
      },
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/settings/expense_categories/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField({required this.vm});
  final ExpenseCategoryEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('color'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          AccentSwatchGrid(
            selected: vm.draft.color,
            onSelected: vm.setColor,
            palette: kStatusSwatches,
          ),
          SizedBox(height: InSpacing.md(context)),
        ],
      ),
    );
  }
}
