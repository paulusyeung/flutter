import 'package:flutter/material.dart';

import '../../../../app/design_tokens.dart';
import '../../../../domain/entity_state.dart';

/// Pill-chip row for the entity-state filter — mirrors
/// `docs/design/v2/screens.jsx` lines 323-347. Active chips render in
/// `ink`/white; inactive in `surface`/`ink2` with a `border` outline.
///
/// Visual padding matches the mockup (6 × 12), but each chip is wrapped in
/// a 48-dp `InkWell` so the actual touch target satisfies Material's
/// minimum.
class StateFilterPills extends StatelessWidget {
  const StateFilterPills({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<EntityState> selected;
  final void Function(EntityState state) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in EntityState.values)
          _Pill(
            label: s.label,
            selected: selected.contains(s),
            onTap: () => onToggle(s),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final background = selected ? tokens.ink : tokens.surface;
    final foreground = selected ? Colors.white : tokens.ink2;
    final borderColor = selected ? tokens.ink : tokens.border;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
