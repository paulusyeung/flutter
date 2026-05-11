import 'package:flutter/material.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';

/// Bottom-sheet body for the entity-state filter on mobile.
///
/// Mirrors the old `admin-portal` `AppBottomBar` UX — three checkbox rows
/// the user toggles freely; the change is applied to the VM when the sheet
/// closes (either by tapping outside, Done, or dragging the sheet down).
class StateFilterSheet extends StatefulWidget {
  const StateFilterSheet({
    required this.initial,
    required this.onApply,
    super.key,
  });

  final Set<EntityState> initial;
  final void Function(Set<EntityState>) onApply;

  @override
  State<StateFilterSheet> createState() => _StateFilterSheetState();
}

class _StateFilterSheetState extends State<StateFilterSheet> {
  late Set<EntityState> _local;

  @override
  void initState() {
    super.initState();
    _local = Set<EntityState>.from(widget.initial);
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
              context.tr('status'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: TextButton(
              onPressed: () {
                setState(() => _local = {EntityState.active});
              },
              child: Text(context.tr('reset')),
            ),
          ),
          const Divider(height: 1),
          for (final s in EntityState.values)
            CheckboxListTile(
              value: _local.contains(s),
              title: Text(context.tr(s.labelKey)),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _local.add(s);
                  } else {
                    _local.remove(s);
                  }
                });
              },
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () {
                    widget.onApply(_local);
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
