import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';

/// One short-list option in [EntitySortFilterSheet].
@immutable
class SortOption {
  const SortOption({required this.id, required this.label});
  final String id;
  final String label;
}

/// Bottom-sheet body for the sort filter on mobile. Generic across entity
/// types — each entity declares its own curated short list of sort fields
/// via [options].
///
/// Single-select radio list for the field, plus an ascending/descending
/// switch. Applies on Done — closing without tapping Done discards.
///
/// Mobile keeps a curated short list of fields here (matches the old
/// dropdown). Desktop bypasses this sheet entirely — its column headers
/// drive sort directly and can sort by any visible column.
class EntitySortFilterSheet extends StatefulWidget {
  const EntitySortFilterSheet({
    required this.initialField,
    required this.initialAscending,
    required this.options,
    required this.onApply,
    super.key,
  });

  final String initialField;
  final bool initialAscending;
  final List<SortOption> options;
  final void Function({required String field, required bool ascending}) onApply;

  @override
  State<EntitySortFilterSheet> createState() => _EntitySortFilterSheetState();
}

class _EntitySortFilterSheetState extends State<EntitySortFilterSheet> {
  late String _field;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    // If the persisted sort field isn't in the mobile shortlist (user picked
    // a desktop-only column then opened the sheet on mobile), preselect the
    // first option so the radio has a valid value — Done re-applies it.
    final ids = widget.options.map((o) => o.id).toSet();
    _field = ids.contains(widget.initialField)
        ? widget.initialField
        : widget.options.first.id;
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
              context.tr('sort'),
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
                for (final opt in widget.options)
                  RadioListTile<String>(value: opt.id, title: Text(opt.label)),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: _ascending,
            title: Text(context.tr('ascending')),
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
                  child: Text(context.tr('done')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
