import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/list/entity_column_picker_sheet.dart';
import 'package:admin/ui/core/list/state_filter_dropdown.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/custom_filter_dropdown.dart';

/// Desktop filter bar — sits between the AppBar search and the list.
///
/// Layout: state multi-select dropdown on the left, custom-field dropdowns
/// after it, columns picker at the trailing edge. Sort is driven by
/// clicking the column headers above the list rather than a control in
/// this bar. The `border` bottom divider visually separates the bar from
/// the list so the three stacked control rows (title / search / filters)
/// remain legible.
class ClientFilterBar extends StatelessWidget {
  const ClientFilterBar({required this.vm, super.key});

  final ClientListViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StateFilterDropdown(selected: vm.states, onToggle: vm.toggleState),
          for (var i = 1; i <= 4; i++)
            CustomFilterDropdown(vm: vm, columnIndex: i),
          _ColumnsButton(vm: vm),
        ],
      ),
    );
  }
}

class _ColumnsButton extends StatelessWidget {
  const _ColumnsButton({required this.vm});
  final ClientListViewModel vm;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.view_column_outlined, size: 18),
      label: const Text('Columns'),
    );
  }

  void _open(BuildContext context) {
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
