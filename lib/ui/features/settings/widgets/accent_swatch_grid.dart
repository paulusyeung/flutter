import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Default accent palette. Hex values are stored as `#RRGGBB` on
/// `company_user.settings.accent_color` — same wire format admin-portal and
/// React use, so a value chosen here round-trips through both. The first
/// entry is the admin-portal default (`kDefaultAccentColor`) so users get
/// the familiar blue when "reset" applies.
const kAccentSwatches = <String>[
  '#2F7DC3',
  '#1F2937',
  '#298AAB',
  '#16A34A',
  '#0EA5E9',
  '#6366F1',
  '#A855F7',
  '#EC4899',
  '#EF4444',
  '#F97316',
  '#F59E0B',
  '#84CC16',
  '#14B8A6',
];

/// Palette for TaskStatus colors. Leading grey is the default for newly
/// created statuses — communicates "set me up" without staking out a
/// workflow meaning the way blue / green / red would. The remaining
/// colors are tuned for kanban legibility (high contrast against the
/// white card surface).
const kStatusSwatches = <String>[
  '#9CA3AF', // neutral grey — default for new statuses
  '#0EA5E9', // sky blue
  '#16A34A', // emerald — "Done"-ish
  '#F59E0B', // amber — "In Progress"-ish
  '#EF4444', // red — "Blocked"-ish
  '#A855F7', // purple
  '#EC4899', // pink
  '#14B8A6', // teal
  '#6366F1', // indigo
  '#1F2937', // slate
];

/// Grid of selectable accent-colour chips. Lives outside any feature folder
/// so Preferences can compose it (settings > user_details > preferences)
/// without dragging the screen-level chrome along.
class AccentSwatchGrid extends StatelessWidget {
  const AccentSwatchGrid({
    required this.selected,
    required this.onSelected,
    this.palette = kAccentSwatches,
    super.key,
  });

  /// `#RRGGBB` of the currently-selected swatch, or empty for none.
  final String selected;

  /// Called with the chosen swatch's `#RRGGBB` hex.
  final ValueChanged<String> onSelected;

  /// Source list of swatches. Defaults to [kAccentSwatches] (the user-
  /// accent palette). TaskStatuses passes [kStatusSwatches] for a
  /// kanban-tuned set led by neutral grey.
  final List<String> palette;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: InSpacing.md,
      runSpacing: InSpacing.md,
      children: [
        for (final hex in palette)
          _Swatch(
            hex: hex,
            isSelected: hex.toLowerCase() == selected.toLowerCase(),
            onTap: () => onSelected(hex),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.isSelected,
    required this.onTap,
  });

  final String hex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final color = parseAccentHex(hex) ?? tokens.accent;
    return Tooltip(
      message: hex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InRadii.r2),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(InRadii.r2),
            border: Border.all(
              color: isSelected ? tokens.ink : tokens.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 18,
                  color:
                      ThemeData.estimateBrightnessForColor(color) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                )
              : null,
        ),
      ),
    );
  }
}

/// Parse `#RRGGBB` / `#AARRGGBB` (case-insensitive). Returns `null` for an
/// empty or malformed input. Shared with [AccentColorController] so the
/// picker preview and the runtime theme stay aligned on input handling.
Color? parseAccentHex(String hex) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final raw = int.tryParse(cleaned, radix: 16);
  if (raw == null) return null;
  return Color(cleaned.length == 6 ? 0xFF000000 | raw : raw);
}
