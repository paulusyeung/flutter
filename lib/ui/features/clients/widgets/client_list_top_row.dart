import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_column_picker_sheet.dart';
import 'package:admin/ui/core/list/state_filter_dropdown.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/custom_filter_dropdown.dart';

/// The wide-mode page header: title, search, filter controls, columns
/// picker, and a primary "New client" action — all in one row. Rendered
/// inside the AppBar's `title` slot at `toolbarHeight: 64`. Narrow widths
/// keep the old stack (title + search-in-`bottom` + active-filters strip).
class ClientListTopRow extends StatelessWidget {
  const ClientListTopRow({required this.vm, super.key});

  final ClientListViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          context.tr('clients'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 16),
        // Expanded keeps the search field flexible; the ConstrainedBox caps
        // it on very wide screens so the trailing controls don't drift to
        // the far edge.
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: context.tr('search_clients'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 12,
                  ),
                ),
                onChanged: vm.setSearch,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        StateFilterDropdown(selected: vm.states, onToggle: vm.toggleState),
        // Each CustomFilterDropdown self-hides when its column isn't
        // configured, so unused slots collapse to zero width.
        for (var i = 1; i <= 4; i++) ...[
          const SizedBox(width: 8),
          CustomFilterDropdown(vm: vm, columnIndex: i),
        ],
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _openColumnsPicker(context),
          icon: const Icon(Icons.view_column_outlined, size: 18),
          label: Text(context.tr('columns')),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () => context.go('/clients/new'),
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.tr('new_client')),
        ),
      ],
    );
  }

  void _openColumnsPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EntityColumnPickerSheet(
        initial: vm.columnIds,
        allColumns: vm.allColumns,
        onApply: vm.setColumns,
        onReset: vm.resetColumns,
      ),
    );
  }
}
