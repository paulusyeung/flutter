import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/recurring_expense_filters.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/recurring_expenses/view_models/recurring_expense_list_view_model.dart';

/// Horizontal chip strip rendering the 5 status filter chips
/// (Draft / Active / Paused / Completed / Pending) plus an "All" leading
/// chip. Each chip carries a count from the repository's per-status DAO
/// stream so users can scan the cadence health at a glance.
///
/// Per the UX spec — "List page chips show counts." The DAO computes them
/// cheaply via the same WHERE fragments the filter uses, so each chip
/// owns a tiny StreamBuilder.
class RecurringExpenseStatusChipStrip extends StatelessWidget {
  const RecurringExpenseStatusChipStrip({super.key, required this.vm});

  final RecurringExpenseListViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: InSpacing.md(context),
            vertical: InSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final chip in kRecurringExpenseStatusChips) ...[
                _StatusChip(vm: vm, chip: chip),
                SizedBox(width: InSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.vm, required this.chip});

  final RecurringExpenseListViewModel vm;
  final RecurringExpenseStatusChip chip;

  @override
  Widget build(BuildContext context) {
    final isSelected = vm.recurringStatus == chip.id;
    return StreamBuilder<int>(
      stream: vm.repo.watchCountForStatus(
        companyId: vm.companyId,
        recurringStatus: chip.id,
      ),
      builder: (context, snapshot) {
        final count = snapshot.data;
        final label = count == null
            ? context.tr(chip.labelKey)
            : '${context.tr(chip.labelKey)} ($count)';
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => vm.setRecurringStatus(chip.id),
        );
      },
    );
  }
}
