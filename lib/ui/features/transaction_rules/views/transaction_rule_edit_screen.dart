import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/transaction_rule.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_edit_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';
import 'package:admin/ui/features/transaction_rules/view_models/transaction_rule_edit_view_model.dart';
import 'package:admin/ui/features/transaction_rules/widgets/rule_criterion_editor_sheet.dart';

/// `/settings/bank_accounts/transaction_rules/new` and `/.../:id`.
class TransactionRuleEditScreen extends StatelessWidget {
  const TransactionRuleEditScreen({this.existingId, super.key});

  final String? existingId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.transactionRules;

    return SettingsEntityEditScaffold<
      TransactionRule,
      TransactionRuleEditViewModel
    >(
      existingId: existingId,
      backRoute: '/settings/bank_accounts/transaction_rules',
      createTitleKey: 'new_transaction_rule',
      editTitleKey: 'edit_transaction_rule',
      wireName: 'transaction_rule',
      watchById: (id) => repo.watch(companyId: companyId, id: id),
      refreshAll: () => repo.refreshAll(companyId: companyId),
      onArchive: (id) => repo.archive(companyId: companyId, id: id),
      onRestore: (id) => repo.restore(companyId: companyId, id: id),
      onDelete: (id) => repo.delete(companyId: companyId, id: id),
      vmFactory: ({existing}) => TransactionRuleEditViewModel(
        repo: repo,
        companyId: companyId,
        existing: existing,
      ),
      isArchivedOf: (r) => r.archivedAt != null,
      isDeletedOf: (r) => r.isDeleted,
      canSave: (vm) =>
          !vm.isSaving && vm.isDirty && vm.draft.name.trim().isNotEmpty,
      bodyBuilder: (context, vm) => [
        FormSection(
          title: context.tr('transaction_rule'),
          children: [
            SettingsTextField(
              initialValue: vm.draft.name,
              labelKey: 'name',
              onChanged: vm.setName,
              errorText: vm.fieldErrorFor('name'),
              textInputAction: TextInputAction.next,
              externalSyncKey: vm.original?.id,
            ),
            const SizedBox(height: 8),
            _AppliesToSelector(vm: vm),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('match_all_rules')),
              subtitle: Text(context.tr('match_all_rules_help')),
              value: vm.draft.matchesOnAll,
              onChanged: vm.setMatchesOnAll,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('auto_convert')),
              subtitle: Text(
                vm.draft.isCredit
                    ? context.tr('auto_convert_credit_help')
                    : context.tr('auto_convert_help'),
              ),
              value: vm.draft.autoConvert,
              onChanged: vm.setAutoConvert,
            ),
          ],
        ),
        FormSection(
          title: context.tr('rules'),
          children: [_CriteriaList(vm: vm)],
        ),
      ],
    );
  }
}

class _AppliesToSelector extends StatelessWidget {
  const _AppliesToSelector({required this.vm});
  final TransactionRuleEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${context.tr('applies_to')}:',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: kTransactionRuleAppliesDebit,
                label: Text(context.tr('withdrawal')),
              ),
              ButtonSegment(
                value: kTransactionRuleAppliesCredit,
                label: Text(context.tr('deposit')),
              ),
            ],
            selected: {vm.draft.appliesTo},
            onSelectionChanged: (set) =>
                set.isEmpty ? null : vm.setAppliesTo(set.first),
          ),
        ),
      ],
    );
  }
}

class _CriteriaList extends StatelessWidget {
  const _CriteriaList({required this.vm});
  final TransactionRuleEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final isCredit = vm.draft.isCredit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.draft.rules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              context.tr('no_rules'),
              style: TextStyle(color: tokens.ink2),
            ),
          )
        else
          for (var i = 0; i < vm.draft.rules.length; i++)
            _CriterionRow(
              key: ValueKey('crit-$i'),
              criterion: vm.draft.rules[i],
              isCredit: isCredit,
              onEdit: () async {
                final updated = await showRuleCriterionSheet(
                  context: context,
                  initial: vm.draft.rules[i],
                  isCredit: isCredit,
                );
                if (updated != null) vm.updateCriterion(i, updated);
              },
              onRemove: () => vm.removeCriterion(i),
            ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final added = await showRuleCriterionSheet(
                context: context,
                initial: const RuleCriterion(),
                isCredit: isCredit,
              );
              if (added != null) vm.addCriterion(added);
            },
            icon: const Icon(Icons.add),
            label: Text(context.tr('add_rule')),
          ),
        ),
      ],
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({
    super.key,
    required this.criterion,
    required this.isCredit,
    required this.onEdit,
    required this.onRemove,
  });

  final RuleCriterion criterion;
  final bool isCredit;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final searchKeyLabel = criterion.searchKey.isEmpty
        ? context.tr('field')
        : labelForSearchKey(criterion.searchKey);
    final operatorLabel = criterion.operator.isEmpty
        ? context.tr('operator')
        : labelForOperator(criterion.operator);
    final valueLabel =
        criterion.operator == kRuleOperatorIsEmpty || criterion.value.isEmpty
            ? '—'
            : criterion.value;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('$searchKeyLabel  $operatorLabel  $valueLabel'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: context.tr('edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
              tooltip: context.tr('remove'),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
