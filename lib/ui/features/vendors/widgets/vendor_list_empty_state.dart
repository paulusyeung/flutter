import 'package:flutter/material.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/vendors/view_models/vendor_list_view_model.dart';

/// Picks the empty-state copy + CTA based on what the user is looking at.
/// Mirror of `ClientListEmptyState`: truly-empty shows the "create your
/// first vendor" nudge; a non-default filter that yields zero rows offers
/// a "Clear filters" escape hatch; archived/deleted-only filters get their
/// own non-CTA copy so the user doesn't think the app is broken.
class VendorListEmptyState extends StatelessWidget {
  const VendorListEmptyState({super.key, required this.vm});

  final VendorListViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.hasActiveFilters) {
      return EmptyState(
        icon: Icons.store_outlined,
        title: context.tr('no_vendors'),
        subtitle: context.tr('create_your_first_vendor_placeholder'),
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
        title: context.tr('no_archived_vendors'),
      );
    }
    if (onlyDeleted) {
      return EmptyState(
        icon: Icons.delete_outline,
        title: context.tr('no_deleted_vendors'),
      );
    }
    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: context.tr('no_vendors_match_filters'),
      action: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
        onPressed: vm.clearAllFilters,
        icon: const Icon(Icons.close),
        label: Text(context.tr('clear_filters')),
      ),
    );
  }
}
