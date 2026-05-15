import 'package:flutter/material.dart';

/// Settings toggle: `SwitchListTile` with a help-text subtitle and optional
/// disabled-with-tooltip state. The canonical switch widget for any settings
/// screen with `company.*` boolean toggles — Expense Settings, Task Settings,
/// Product Settings, and any new top-level toggle screens.
///
/// Callers pass resolved strings (not localization keys) so the static
/// `search_catalog_consistency_test` regex finds each `context.tr('...')`
/// reference at the call site.
///
/// When [enabled] is `false`, the switch renders with `value: false` (so the
/// gated child reads as "off" regardless of the backing draft value) and
/// `onChanged: null` (so taps are inert). If [disabledTooltip] is non-null,
/// the tile is wrapped in a `Tooltip` so the user can see why it's off.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.label,
    required this.help,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.disabledTooltip,
  });

  final String label;
  final String help;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final tile = SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(help),
      value: enabled ? value : false,
      onChanged: enabled ? onChanged : null,
    );
    if (enabled || disabledTooltip == null) return tile;
    return Tooltip(message: disabledTooltip!, child: tile);
  }
}
