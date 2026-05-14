import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/gateways/view_models/company_gateway_list_view_model.dart';

/// Picks the empty-state copy + CTA based on what the user is looking at.
/// Mirrors `ProjectListEmptyState`.
class CompanyGatewayListEmptyState extends StatelessWidget {
  const CompanyGatewayListEmptyState({super.key, required this.vm});

  final CompanyGatewayListViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.hasActiveFilters) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: context.tr('no_company_gateways_yet'),
        subtitle: context.tr('create_your_first_company_gateway_placeholder'),
        action: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => context.go('/settings/company_gateways/new'),
          icon: const Icon(Icons.add),
          label: Text(context.tr('add_gateway')),
        ),
      );
    }
    final onlyArchived =
        vm.states.length == 1 &&
        vm.states.contains(EntityState.archived) &&
        vm.customFilters.isEmpty &&
        vm.extraFilters.isEmpty &&
        vm.search.isEmpty;
    final onlyDeleted =
        vm.states.length == 1 &&
        vm.states.contains(EntityState.deleted) &&
        vm.customFilters.isEmpty &&
        vm.extraFilters.isEmpty &&
        vm.search.isEmpty;
    if (onlyArchived) {
      return EmptyState(
        icon: Icons.archive_outlined,
        title: context.tr('no_archived_company_gateways'),
      );
    }
    if (onlyDeleted) {
      return EmptyState(
        icon: Icons.delete_outline,
        title: context.tr('no_deleted_company_gateways'),
      );
    }
    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: context.tr('no_company_gateways_match_filters'),
      action: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
        onPressed: vm.clearAllFilters,
        icon: const Icon(Icons.close),
        label: Text(context.tr('clear_filters')),
      ),
    );
  }
}
