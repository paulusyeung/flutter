import 'package:flutter/material.dart';

import 'package:admin/app/color_hex.dart';
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

// ─────────── Neutral ramps for the custom-palette editor ───────────
//
// The custom theme's structural tokens (page background, card surface, text,
// borders) need *neutral* quick-picks, not saturated brand hues — a user
// setting a "Background" wants near-white on the light side and near-black on
// the dark side, with a few greys, plus a couple of tints. These ramps are
// brightness-aware: `…Light` leads with the lightest, `…Dark` with the
// darkest, so the first swatch is the sensible default for that side. The hex
// field still allows any colour; these just make the grid usable.

/// Page-background / card-surface ramp — light side (off-white → mid grey,
/// then two faint tints).
const kLightSurfaceSwatches = <String>[
  '#FFFFFF',
  '#F6F4EF',
  '#ECEEF2',
  '#E5E5E4',
  '#D6CFBF',
  '#BFC7D3',
  '#9CA3AF',
  '#F4EEE6',
  '#E7EEF6',
];

/// Page-background / card-surface ramp — dark side (near-black → mid grey,
/// then two faint warm/cool tints).
const kDarkSurfaceSwatches = <String>[
  '#000000',
  '#15140F',
  '#0F1115',
  '#1F1E18',
  '#28261F',
  '#2E2B22',
  '#3A362B',
  '#1B2C40',
  '#161616',
];

/// Text / ink ramp — light side (near-black → light grey).
const kLightInkSwatches = <String>[
  '#1A1814',
  '#16171A',
  '#45454A',
  '#4A4540',
  '#7A7E85',
  '#857F73',
  '#B5AE9F',
];

/// Text / ink ramp — dark side (near-white → mid grey).
const kDarkInkSwatches = <String>[
  '#F6F4EF',
  '#FFFFFF',
  '#C8C2B5',
  '#ADB2BA',
  '#857F73',
  '#5A554B',
];

/// Border / divider ramp — light side (subtle → strong greys).
const kLightBorderSwatches = <String>[
  '#E8E3D8',
  '#E5E5E4',
  '#DDE2EA',
  '#D6CFBF',
  '#CECDCB',
  '#BFC7D3',
];

/// Border / divider ramp — dark side (subtle → strong dark greys).
const kDarkBorderSwatches = <String>[
  '#2E2B22',
  '#28261F',
  '#3A362B',
  '#1F232B',
  '#3A3A3A',
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
      spacing: InSpacing.md(context),
      runSpacing: InSpacing.md(context),
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
/// empty or malformed input. Thin alias over the foundational
/// [parseHexColor] so existing call sites keep the accent-flavoured name.
Color? parseAccentHex(String hex) => parseHexColor(hex);

/// Inverse of [parseAccentHex] — alias over [formatHexColor].
String formatAccentHex(Color color) => formatHexColor(color);
