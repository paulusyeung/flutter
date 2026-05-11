import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/custom_filter_sheet.dart';
import 'package:admin/ui/features/clients/widgets/state_filter_sheet.dart';

/// Mobile sort short-list for clients. Matches the old `SortDropdown`'s
/// curated five-option set so users don't see every backend-sortable
/// column on the small screen.
const List<SortOption> _clientSortOptions = <SortOption>[
  SortOption(id: ClientFieldIds.name, label: 'Name'),
  SortOption(id: ClientFieldIds.number, label: 'Number'),
  SortOption(id: ClientFieldIds.balance, label: 'Balance'),
  SortOption(id: ClientFieldIds.updatedAt, label: 'Updated'),
  SortOption(id: ClientFieldIds.createdAt, label: 'Created'),
];

/// Mobile bottom bar — small icon buttons that open modal sheets, mirroring
/// the old `admin-portal` `AppBottomBar` UX. Sits in the screen's own
/// `Scaffold.bottomNavigationBar`, above the shell's `NavigationBar`.
///
/// Each icon shows an `accent` dot when its filter is non-default so the
/// user knows the current state without re-opening the sheet.
class ClientFilterBottomBar extends StatelessWidget {
  const ClientFilterBottomBar({required this.vm, super.key});

  final ClientListViewModel vm;

  bool get _stateActive =>
      vm.states.length != 1 || !vm.states.contains(EntityState.active);
  bool get _sortActive =>
      vm.sortField != ClientFieldIds.name || !vm.sortAscending;
  bool _customActive(int n) => (vm.customFilters[n] ?? const {}).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Material(
      color: tokens.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: tokens.border)),
        ),
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BarButton(
              tooltip: 'Filter by status',
              icon: Icons.tune,
              active: _stateActive,
              onPressed: () => _openStateSheet(context),
            ),
            _BarButton(
              tooltip: 'Sort',
              icon: Icons.sort,
              active: _sortActive,
              onPressed: () => _openSortSheet(context),
            ),
            for (var n = 1; n <= 4; n++)
              _CustomBarButton(
                vm: vm,
                columnIndex: n,
                active: _customActive(n),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStateSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          StateFilterSheet(initial: vm.states, onApply: vm.setStates),
    );
  }

  Future<void> _openSortSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => EntitySortFilterSheet(
        initialField: vm.sortField,
        initialAscending: vm.sortAscending,
        options: _clientSortOptions,
        onApply: ({required field, required ascending}) =>
            vm.setSort(field: field, ascending: ascending),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: tokens.ink2),
          if (active)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tokens.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.surface, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mobile bottom-bar button for one custom-field column. Hidden when the
/// column has no values; opens a sheet listing distinct values when shown.
class _CustomBarButton extends StatelessWidget {
  const _CustomBarButton({
    required this.vm,
    required this.columnIndex,
    required this.active,
  });

  final ClientListViewModel vm;
  final int columnIndex;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: vm.watchCustomValueOptions(columnIndex),
      builder: (context, snapshot) {
        final options = snapshot.data ?? const <String>[];
        if (options.isEmpty) return const SizedBox.shrink();
        return _BarButton(
          tooltip: 'Custom $columnIndex',
          icon: _customIcon(columnIndex),
          active: active,
          onPressed: () => _open(context, options),
        );
      },
    );
  }

  IconData _customIcon(int n) => switch (n) {
    1 => Icons.filter_1,
    2 => Icons.filter_2,
    3 => Icons.filter_3,
    _ => Icons.filter_4,
  };

  Future<void> _open(BuildContext context, List<String> options) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => CustomFilterSheet(
        columnIndex: columnIndex,
        options: options,
        initial: vm.customFilters[columnIndex] ?? const {},
        onApply: (values) =>
            vm.setCustomFilter(columnIndex: columnIndex, values: values),
      ),
    );
  }
}
