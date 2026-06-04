import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme_controller.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/segmented_setting_row.dart';

/// The brightness the app is actually rendering: explicit Light/Dark, or the
/// OS brightness under Auto. Drives which side the Palette row + the
/// Customize section edit ("edit what you see").
Brightness activeBrightness(BuildContext context, ThemeMode mode) =>
    switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };

String lightVariantKey(LightVariant v) => switch (v) {
  LightVariant.sand => 'variant_sand',
  LightVariant.mist => 'variant_mist',
  LightVariant.paper => 'variant_paper',
};

String darkVariantKey(DarkVariant v) => switch (v) {
  DarkVariant.espresso => 'variant_espresso',
  DarkVariant.midnight => 'variant_midnight',
  DarkVariant.carbon => 'variant_carbon',
};

/// Two rows: the theme mode (Auto / Light / Dark) and the palette preset for
/// the brightness currently in effect. Colour customization lives in the
/// separate "Customize colors" section on Preferences.
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
            _PaletteRow(controller: controller),
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
    return SegmentedSettingRow(
      leading: const Icon(Icons.brightness_6_outlined),
      title: context.tr('theme'),
      subtitle: _label(context, mode),
      control: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: ThemeMode.system,
            label: segmentLabel(context, 'auto'),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            label: segmentLabel(context, 'light'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: segmentLabel(context, 'dark'),
          ),
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

/// The palette preset for the brightness in effect. Same shape as [_ModeRow]
/// (leading icon, title, subtitle, a `SegmentedButton`) so the two controls
/// line up.
class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final dark =
        activeBrightness(context, controller.themeMode) == Brightness.dark;
    final Widget picker;
    final String currentKey;
    if (dark) {
      currentKey = darkVariantKey(controller.darkVariant);
      picker = SegmentedButton<DarkVariant>(
        showSelectedIcon: false,
        segments: [
          for (final v in DarkVariant.values)
            ButtonSegment(
              value: v,
              label: segmentLabel(context, darkVariantKey(v)),
            ),
        ],
        selected: {controller.darkVariant},
        onSelectionChanged: (s) => controller.setDarkVariant(s.first),
      );
    } else {
      currentKey = lightVariantKey(controller.lightVariant);
      picker = SegmentedButton<LightVariant>(
        showSelectedIcon: false,
        segments: [
          for (final v in LightVariant.values)
            ButtonSegment(
              value: v,
              label: segmentLabel(context, lightVariantKey(v)),
            ),
        ],
        selected: {controller.lightVariant},
        onSelectionChanged: (s) => controller.setLightVariant(s.first),
      );
    }
    return SegmentedSettingRow(
      leading: Icon(
        dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
      ),
      title: context.tr('palette'),
      subtitle: context.tr(currentKey),
      control: picker,
    );
  }
}
