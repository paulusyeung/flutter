import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme_controller.dart';
import 'package:admin/l10n/localization.dart';

// Shared `SegmentedButton` style — applied to every row so the three
// controls resolve to the same total width and share the rounded-rectangle
// shape used by the rest of the design system (matches FilledButton /
// OutlinedButton via `InRadii.r2`; M3's default `StadiumBorder` is a pill,
// which the v2 design system avoids).
//
// 80 px per segment comfortably fits the widest label ("Midnight") at
// default Inter Tight metrics; 40 px height matches M3's default for the
// control.
final ButtonStyle _kSegmentedStyle = SegmentedButton.styleFrom(
  minimumSize: const Size(80, 40),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(InRadii.r2),
  ),
);

/// Three stacked rows for the user's theme preferences:
///   • System / Light / Dark mode
///   • Light palette variant (Sand / Mist / Paper)
///   • Dark palette variant (Espresso / Midnight / Carbon)
///
/// Both variant rows are visible at all times — when `ThemeMode = System`,
/// the OS picks which variant is active, but the user still chooses both
/// preferences here so a brightness flip honors their selection.
class ThemeTile extends StatelessWidget {
  const ThemeTile({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            _ModeRow(controller: controller),
            _LightVariantRow(controller: controller),
            _DarkVariantRow(controller: controller),
          ],
        );
      },
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final mode = controller.themeMode;
    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined),
      title: Text(context.tr('theme')),
      subtitle: Text(_label(context, mode)),
      trailing: SegmentedButton<ThemeMode>(
        style: _kSegmentedStyle,
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: ThemeMode.system,
            label: Text(context.tr('auto')),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            label: Text(context.tr('light')),
          ),
          ButtonSegment(value: ThemeMode.dark, label: Text(context.tr('dark'))),
        ],
        selected: {mode},
        onSelectionChanged: (s) => controller.setThemeMode(s.first),
      ),
    );
  }

  static String _label(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.system => context.tr('match_system'),
    ThemeMode.light => context.tr('light'),
    ThemeMode.dark => context.tr('dark'),
  };
}

class _LightVariantRow extends StatelessWidget {
  const _LightVariantRow({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final variant = controller.lightVariant;
    return ListTile(
      leading: const Icon(Icons.light_mode_outlined),
      title: Text(context.tr('light_variant')),
      trailing: SegmentedButton<LightVariant>(
        style: _kSegmentedStyle,
        showSelectedIcon: false,
        segments: [
          for (final v in LightVariant.values)
            ButtonSegment(value: v, label: Text(context.tr(_labelKey(v)))),
        ],
        selected: {variant},
        onSelectionChanged: (s) => controller.setLightVariant(s.first),
      ),
    );
  }

  static String _labelKey(LightVariant v) => switch (v) {
    LightVariant.sand => 'variant_sand',
    LightVariant.mist => 'variant_mist',
    LightVariant.paper => 'variant_paper',
  };
}

class _DarkVariantRow extends StatelessWidget {
  const _DarkVariantRow({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final variant = controller.darkVariant;
    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: Text(context.tr('dark_variant')),
      trailing: SegmentedButton<DarkVariant>(
        style: _kSegmentedStyle,
        showSelectedIcon: false,
        segments: [
          for (final v in DarkVariant.values)
            ButtonSegment(value: v, label: Text(context.tr(_labelKey(v)))),
        ],
        selected: {variant},
        onSelectionChanged: (s) => controller.setDarkVariant(s.first),
      ),
    );
  }

  static String _labelKey(DarkVariant v) => switch (v) {
    DarkVariant.espresso => 'variant_espresso',
    DarkVariant.midnight => 'variant_midnight',
    DarkVariant.carbon => 'variant_carbon',
  };
}
