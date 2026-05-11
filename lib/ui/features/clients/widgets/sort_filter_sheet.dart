import 'package:flutter/material.dart';

import '../../../../domain/columns/client_columns.dart';

/// Bottom-sheet body for the sort filter on mobile.
///
/// Single-select radio list for the field, plus an ascending/descending
/// switch. Applies on Done — closing without tapping Done discards.
///
/// Mobile keeps a curated short list of fields here (matches the old
/// dropdown). Desktop bypasses this sheet entirely — its column headers
/// drive sort directly and can sort by any visible column.
class SortFilterSheet extends StatefulWidget {
  const SortFilterSheet({
    required this.initialField,
    required this.initialAscending,
    required this.onApply,
    super.key,
  });

  final String initialField;
  final bool initialAscending;
  final void Function({required String field, required bool ascending}) onApply;

  /// Quick-pick fields on mobile. Same set the old `SortDropdown` exposed.
  static const List<({String id, String label})> _options = [
    (id: ClientFieldIds.name, label: 'Name'),
    (id: ClientFieldIds.number, label: 'Number'),
    (id: ClientFieldIds.balance, label: 'Balance'),
    (id: ClientFieldIds.updatedAt, label: 'Updated'),
    (id: ClientFieldIds.createdAt, label: 'Created'),
  ];

  @override
  State<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<SortFilterSheet> {
  late String _field;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    // If the persisted sort field isn't in the mobile shortlist (user picked
    // a desktop-only column then opened the sheet on mobile), preselect the
    // first option so the radio has a valid value — Done re-applies it.
    final ids = SortFilterSheet._options.map((o) => o.id).toSet();
    _field = ids.contains(widget.initialField)
        ? widget.initialField
        : SortFilterSheet._options.first.id;
    _ascending = widget.initialAscending;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Sort',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          RadioGroup<String>(
            groupValue: _field,
            onChanged: (v) => setState(() => _field = v!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final opt in SortFilterSheet._options)
                  RadioListTile<String>(
                    value: opt.id,
                    title: Text(opt.label),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: _ascending,
            title: const Text('Ascending'),
            onChanged: (v) => setState(() => _ascending = v),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () {
                    widget.onApply(field: _field, ascending: _ascending);
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
}
