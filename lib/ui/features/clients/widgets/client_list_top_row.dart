import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_column_picker_sheet.dart';
import 'package:admin/ui/core/list/state_filter_dropdown.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/custom_filter_dropdown.dart';

/// The wide-mode page header: primary action, search, filter controls,
/// columns picker — all in one row. Rendered inside the AppBar's
/// `flexibleSpace` slot (NOT `title`, whose intrinsic-width layout pass
/// is incompatible with `Expanded`). Narrow widths keep the old stack
/// (title + search-in-`bottom` + active-filters strip).
class ClientListTopRow extends StatelessWidget {
  const ClientListTopRow({required this.vm, super.key});

  final ClientListViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Primary action leads the row. The `style:` override only fixes
        // a layout bug — without an explicit `minimumSize`, Flutter's
        // flex-first-pass sizing (which hands inflexible children
        // unbounded width before dividing the remainder among Expanded
        // siblings) collapses the button's internal width range to the
        // invalid `BoxConstraints(w=Infinity, …)`. Setting a finite
        // minimum lets `_RenderInputPadding` size correctly.
        FilledButton.icon(
          onPressed: () => context.go('/clients/new'),
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.tr('new_client')),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
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
        // Mirrors `StateFilterDropdown`'s pill-chip styling so the two
        // sit as one button family. If a third pill button shows up,
        // extract into a shared widget then.
        OutlinedButton.icon(
          onPressed: () => _openColumnsPicker(context),
          icon: const Icon(Icons.view_column_outlined, size: 14),
          label: Text(
            context.tr('columns'),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.ink2,
            side: BorderSide(color: tokens.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 36),
          ),
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
