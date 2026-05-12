import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Round 32×32 checkbox used in entity-list selection mode in place of the
/// avatar, and as the hover-reveal target in the leading slot on desktop.
/// The underlying row's onTap (wired by the screen) toggles selection, so
/// this widget is **display only** — it doesn't need its own onChanged.
class SelectionCheckbox extends StatelessWidget {
  const SelectionCheckbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? tokens.accent : tokens.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: checked ? tokens.accent : tokens.borderStrong,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : null,
    );
  }
}
