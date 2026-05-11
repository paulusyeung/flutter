import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/entity_state.dart';

/// Desktop multi-select dropdown for the active/archived/deleted filter.
///
/// Mirrors the old admin-portal `ListFilter` dropdown: the trigger shows the
/// current selection comma-joined (e.g. "Active, Archived") or "All" when
/// the set is empty. Each `CheckboxListTile` in the menu applies its
/// change immediately by calling [onToggle].
class StateFilterDropdown extends StatelessWidget {
  const StateFilterDropdown({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<EntityState> selected;
  final void Function(EntityState state) onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;

    final label = selected.isEmpty
        ? 'All'
        : [
            for (final s in EntityState.values)
              if (selected.contains(s)) s.label,
          ].join(', ');

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
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        ),
      ),
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in EntityState.values)
                CheckboxListTile(
                  value: selected.contains(s),
                  title: Text(s.label),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (_) => onToggle(s),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
