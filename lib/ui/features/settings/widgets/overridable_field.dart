import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/features/settings/state/settings_level_controller.dart';

/// Generic wrapper that renders a form field with a "use override" checkbox
/// at group/client level. At company level the checkbox is hidden and the
/// child renders unwrapped — there's no "inheritance" concept when editing
/// the company's own defaults.
///
/// Behavior at group/client level:
///   * `isOverridden = false` → checkbox unchecked, child wrapped in
///     `IgnorePointer + Opacity` so the placeholder (inherited value) is
///     visible but the user can't edit until they opt in.
///   * `isOverridden = true` → checkbox checked, child fully interactive.
///   * Tapping the checkbox (or the label) flips state via [onOverrideToggle];
///     the caller is responsible for nulling the field on toggle-off and
///     seeding it with the cascaded value on toggle-on.
///
/// Mirrors React's `PropertyCheckbox`
/// (`react/src/components/PropertyCheckbox.tsx`).
class OverridableField extends StatelessWidget {
  const OverridableField({
    super.key,
    required this.label,
    required this.isOverridden,
    required this.onOverrideToggle,
    required this.child,
  });

  final String label;
  final bool isOverridden;
  final ValueChanged<bool> onOverrideToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final level = context.watch<SettingsLevelController>().level;
    if (level == SettingsLevel.company) {
      return child;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onOverrideToggle(!isOverridden),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isOverridden,
                      onChanged: (v) => onOverrideToggle(v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          IgnorePointer(
            ignoring: !isOverridden,
            // 0.65 keeps the disabled state readable on light + dark themes
            // (WCAG AA-clearing on most ink tokens) while still reading as
            // "inactive" at a glance.
            child: Opacity(opacity: isOverridden ? 1.0 : 0.65, child: child),
          ),
        ],
      ),
    );
  }
}
