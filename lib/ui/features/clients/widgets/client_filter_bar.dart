import 'package:flutter/material.dart';

import '../../../../app/design_tokens.dart';
import '../view_models/client_list_view_model.dart';
import 'column_picker_sheet.dart';
import 'custom_filter_dropdown.dart';
import 'state_filter_pills.dart';

/// Desktop filter bar — sits between the AppBar search and the list.
///
/// Layout: pill chips on the left (state), custom-field dropdowns on the
/// right, columns picker at the trailing edge. Sort is driven by clicking
/// the column headers above the list rather than a pill in this bar.
/// `border` bottom divider visually separates the bar from the list so
/// the three stacked control rows (title / search / filters) remain legible.
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
          StateFilterPills(selected: vm.states, onToggle: vm.toggleState),
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
      builder: (_) => ColumnPickerSheet(
        initial: vm.columnIds,
        onApply: vm.setColumns,
        onReset: vm.resetColumns,
      ),
    );
  }
}
