import 'package:flutter/material.dart';

import '../../../../domain/columns/client_columns.dart';

/// Bottom-sheet body for picking + reordering columns in the client list.
///
/// Behaviour:
///   * Top section is the **selected** columns in user order — drag handle
///     reorders, checkbox unticks (moves the column to the lower section).
///   * Bottom section is the **available** columns in registry order — tick
///     to add them to the selected list (appended at the end).
///   * "Reset to defaults" reverts to [kDefaultClientColumns].
///   * Apply happens on Done — closing without Done discards.
class ColumnPickerSheet extends StatefulWidget {
  const ColumnPickerSheet({
    required this.initial,
    required this.onApply,
    required this.onReset,
    super.key,
  });

  final List<String> initial;
  final ValueChanged<List<String>> onApply;
  final VoidCallback onReset;

  @override
  State<ColumnPickerSheet> createState() => _ColumnPickerSheetState();
}

class _ColumnPickerSheetState extends State<ColumnPickerSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    // Keep only ids the registry recognises so the user doesn't see opaque
    // entries (unknown ids still round-trip in storage; they're invisible
    // in the picker).
    _selected = [
      for (final id in widget.initial)
        if (clientColumnsById.containsKey(id)) id,
    ];
  }

  List<String> get _available => [
    for (final c in kAllClientColumns)
      if (!_selected.contains(c.id)) c.id,
  ];

  String _labelFor(String id) => clientColumnsById[id]?.label ?? id;

  @override
  Widget build(BuildContext context) {
    final available = _available;
    // Cap the picker height so a large `Available` section doesn't push the
    // footer buttons off-screen on shorter viewports.
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          ListTile(
            title: Text(
              'Columns',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: const Text('Drag to reorder. Toggle to show or hide.'),
          ),
          const Divider(height: 1),
          Flexible(
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                SliverToBoxAdapter(
                  child: _SectionLabel(text: 'Selected (${_selected.length})'),
                ),
                SliverReorderableList(
                  itemCount: _selected.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, i) {
                    final id = _selected[i];
                    return _SelectedRow(
                      key: ValueKey('sel-$id'),
                      index: i,
                      id: id,
                      label: _labelFor(id),
                      onToggle: () => _toggleOff(id),
                    );
                  },
                ),
                if (available.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: Divider(height: 1)),
                  const SliverToBoxAdapter(
                    child: _SectionLabel(text: 'Available'),
                  ),
                  SliverList.builder(
                    itemCount: available.length,
                    itemBuilder: (context, i) {
                      final id = available[i];
                      return CheckboxListTile(
                        key: ValueKey('avail-$id'),
                        value: false,
                        title: Text(_labelFor(id)),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (_) => _toggleOn(id),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    widget.onReset();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset to defaults'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  // Override the app theme's `Size.fromHeight(44)` — which is
                  // `Size(double.infinity, 44)` and makes the button want full
                  // row width. In a Row that hands non-flex children unbounded
                  // `maxWidth`, that infinite-width preference asserts.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  onPressed: () {
                    widget.onApply(List<String>.unmodifiable(_selected));
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final item = _selected.removeAt(oldIndex);
      _selected.insert(adjusted, item);
    });
  }

  void _toggleOff(String id) {
    setState(() => _selected.remove(id));
  }

  void _toggleOn(String id) {
    setState(() => _selected.add(id));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}

class _SelectedRow extends StatelessWidget {
  const _SelectedRow({
    required this.index,
    required this.id,
    required this.label,
    required this.onToggle,
    super.key,
  });

  final int index;
  final String id;
  final String label;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: true,
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (_) => onToggle(),
      secondary: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle),
      ),
    );
  }
}
