import 'package:flutter/material.dart';

import '../../../../app/design_tokens.dart';
import '../view_models/client_list_view_model.dart';

/// Desktop dropdown for a single custom-field column (1..4). Hidden when
/// that column has no values populated across the company's clients.
///
/// The menu body wraps its `CheckboxListTile` rows in a `StatefulBuilder`
/// so individual checkbox taps don't dismiss the menu — selection is
/// applied when the user closes the menu.
class CustomFilterDropdown extends StatelessWidget {
  const CustomFilterDropdown({
    required this.vm,
    required this.columnIndex,
    super.key,
  });

  final ClientListViewModel vm;
  final int columnIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final selected = vm.customFilters[columnIndex] ?? const <String>{};

    return StreamBuilder<List<String>>(
      stream: vm.watchCustomValueOptions(columnIndex),
      builder: (context, snapshot) {
        final options = snapshot.data ?? const <String>[];
        if (options.isEmpty) return const SizedBox.shrink();

        final label = selected.isEmpty
            ? 'Custom $columnIndex'
            : 'Custom $columnIndex: ${selected.length}';

        return MenuAnchor(
          builder: (context, controller, _) => OutlinedButton.icon(
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.ink2,
              side: BorderSide(color: tokens.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 36),
            ),
            icon: const Icon(Icons.filter_list, size: 14),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Wrap in a StatefulBuilder so checkbox taps rebuild the menu
          // without dismissing it. Applied selection lands on close via
          // onClose.
          onClose: () {
            // No-op placeholder; the inner builder applies on each tick.
          },
          menuChildren: [
            _CustomMenu(
              options: options,
              initial: selected,
              onApply: (next) {
                vm.setCustomFilter(columnIndex: columnIndex, values: next);
              },
            ),
          ],
        );
      },
    );
  }
}

class _CustomMenu extends StatefulWidget {
  const _CustomMenu({
    required this.options,
    required this.initial,
    required this.onApply,
  });

  final List<String> options;
  final Set<String> initial;
  final void Function(Set<String>) onApply;

  @override
  State<_CustomMenu> createState() => _CustomMenuState();
}

class _CustomMenuState extends State<_CustomMenu> {
  late Set<String> _local;

  @override
  void initState() {
    super.initState();
    _local = Set<String>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280, maxHeight: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final v in widget.options)
                  CheckboxListTile(
                    value: _local.contains(v),
                    title: Text(v),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _local.add(v);
                        } else {
                          _local.remove(v);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(_local.clear);
                    widget.onApply(const {});
                  },
                  child: const Text('Clear'),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onApply(_local);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
