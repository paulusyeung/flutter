import 'package:flutter/material.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/payments/view_models/payment_list_view_model.dart';

class PaymentListEmptyState extends StatelessWidget {
  const PaymentListEmptyState({super.key, required this.vm});

  final PaymentListViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.hasActiveFilters && !vm.hasUnappliedFundsOnly) {
      return EmptyState(
        icon: Icons.payments_outlined,
        title: context.tr('no_payments_yet'),
      );
    }
    final onlyArchived =
        vm.states.length == 1 &&
        vm.states.contains(EntityState.archived) &&
        vm.customFilters.isEmpty &&
        vm.extraFilters.isEmpty &&
        vm.search.isEmpty &&
        !vm.hasUnappliedFundsOnly;
    final onlyDeleted =
        vm.states.length == 1 &&
        vm.states.contains(EntityState.deleted) &&
        vm.customFilters.isEmpty &&
        vm.extraFilters.isEmpty &&
        vm.search.isEmpty &&
        !vm.hasUnappliedFundsOnly;
    if (onlyArchived) {
      return EmptyState(
        icon: Icons.archive_outlined,
        title: context.tr('no_archived_payments'),
      );
    }
    if (onlyDeleted) {
      return EmptyState(
        icon: Icons.delete_outline,
        title: context.tr('no_deleted_payments'),
      );
    }
    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: context.tr('no_payments_match_filters'),
      action: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
        onPressed: () {
          vm.clearAllFilters();
          vm.hasUnappliedFundsOnly = false;
        },
        icon: const Icon(Icons.close),
        label: Text(context.tr('clear_filters')),
      ),
    );
  }
}
