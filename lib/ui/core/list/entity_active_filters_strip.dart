import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';

/// Compact horizontal row of removable chips showing every non-default
/// filter currently applied. Hidden entirely when no filters are active.
/// Generic across entity types — reads filter state and the column label
/// map from a [GenericListViewModel].
///
/// Gives users a memory anchor when they scroll past the filter controls
/// and a fast escape hatch from a heavy filter set.
class EntityActiveFiltersStrip<T> extends StatelessWidget {
  const EntityActiveFiltersStrip({required this.vm, super.key});

  final GenericListViewModel<T> vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.hasActiveFilters) return const SizedBox.shrink();
    final tokens = context.inTheme;
    final chips = <Widget>[];

    // State chips — only render for non-default selections.
    final isDefaultStates =
        vm.states.length == 1 && vm.states.contains(EntityState.active);
    if (!isDefaultStates) {
      for (final s in vm.states) {
        chips.add(
          _RemovableChip(
            label: s.label,
            onRemove: () {
              // Removing a state chip toggles it off; if it would leave the
              // set empty, the VM snaps back to {active} (which would then
              // render no chip — the strip collapses).
              vm.toggleState(s);
            },
          ),
        );
      }
    }

    // Custom-field chips. One per (column, value) so the user can remove
    // values individually.
    for (final entry in vm.customFilters.entries) {
      for (final value in entry.value) {
        chips.add(
          _RemovableChip(
            label: 'Custom${entry.key}: $value',
            onRemove: () {
              final next = Set<String>.from(entry.value)..remove(value);
              vm.setCustomFilter(columnIndex: entry.key, values: next);
            },
          ),
        );
      }
    }

    // Sort — only when non-default.
    final isDefaultSort =
        vm.sortField == vm.defaultSortField && vm.sortAscending;
    if (!isDefaultSort) {
      final label = vm.columnLabelById(vm.sortField);
      chips.add(
        _RemovableChip(
          label: 'Sort: $label ${vm.sortAscending ? '↑' : '↓'}',
          onRemove: () =>
              vm.setSort(field: vm.defaultSortField, ascending: true),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...chips,
          TextButton(
            onPressed: vm.clearAllFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
              foregroundColor: tokens.ink2,
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: tokens.ink3),
            ),
          ),
        ],
      ),
    );
  }
}
