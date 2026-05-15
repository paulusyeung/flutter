import 'package:flutter/material.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/recurring_invoices/view_models/recurring_invoice_list_view_model.dart';

class RecurringInvoiceListEmptyState extends StatelessWidget {
  const RecurringInvoiceListEmptyState({super.key, required this.vm});

  final RecurringInvoiceListViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.hasActiveFilters) {
      return EmptyState(
        icon: Icons.event_repeat_outlined,
        title: context.tr('no_recurring_invoices_yet'),
        subtitle:
            context.tr('create_your_first_recurring_invoice_placeholder'),
      );
    }
    final onlyArchived = vm.states.length == 1 &&
        vm.states.contains(EntityState.archived) &&
        vm.customFilters.isEmpty &&
        vm.extraFilters.isEmpty &&
        vm.search.isEmpty;
    final onlyDeleted = vm.states.length == 1 &&
        vm.states.contains(EntityState.deleted) &&
        vm.customFilters.isEmpty &&
        vm.extraFilters.isEmpty &&
        vm.search.isEmpty;
    if (onlyArchived) {
      return EmptyState(
        icon: Icons.archive_outlined,
        title: context.tr('no_archived_recurring_invoices'),
      );
    }
    if (onlyDeleted) {
      return EmptyState(
        icon: Icons.delete_outline,
        title: context.tr('no_deleted_recurring_invoices'),
      );
    }
    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: context.tr('no_recurring_invoices_match_filters'),
      action: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
        onPressed: vm.clearAllFilters,
        icon: const Icon(Icons.close),
        label: Text(context.tr('clear_filters')),
      ),
    );
  }
}
