import 'package:flutter/material.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';

/// Picks the empty-state copy + CTA based on what the user is looking at.
/// Truly-empty (defaults applied) shows the "create your first client"
/// nudge; a non-default filter that yields zero rows offers a "Clear
/// filters" escape hatch; archived/deleted-only filters get their own
/// non-CTA copy so the user doesn't think the app is broken.
class ClientListEmptyState extends StatelessWidget {
  const ClientListEmptyState({super.key, required this.vm});

  final ClientListViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.hasActiveFilters) {
      return EmptyState(
        icon: Icons.people_outline,
        title: context.tr('no_clients_yet'),
        subtitle: context.tr('create_your_first_client_placeholder'),
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
        title: context.tr('no_archived_clients'),
      );
    }
    if (onlyDeleted) {
      return EmptyState(
        icon: Icons.delete_outline,
        title: context.tr('no_deleted_clients'),
      );
    }
    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: context.tr('no_clients_match_filters'),
      action: OutlinedButton.icon(
        onPressed: vm.clearAllFilters,
        icon: const Icon(Icons.close),
        label: Text(context.tr('clear_filters')),
      ),
    );
  }
}
