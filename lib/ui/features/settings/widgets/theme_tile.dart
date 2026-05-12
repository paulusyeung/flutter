import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme_controller.dart';
import 'package:admin/l10n/localization.dart';

// Width of the SizedBox we wrap every segment label in. Pins each segment's
// intrinsic width to the same value across all three rows so the pills line
// up regardless of label content. 80 comfortably fits "Midnight" / "Espresso"
// at Inter Tight 14px with headroom for localization; longer labels
// ellipsize rather than stretching the segment.
const double _kSegmentLabelWidth = 80;

Widget _segmentLabel(BuildContext context, String key) {
  return SizedBox(
    width: _kSegmentLabelWidth,
    child: Center(
      child: Text(
        context.tr(key),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

/// Stacked rows for the user's theme preferences. The mode row (System /
/// Light / Dark) is always present; the variant rows are conditionally
/// shown so the user only sees palette choices relevant to the current
/// mode:
///   • ThemeMode.light → only the Light palette row.
///   • ThemeMode.dark  → only the Dark palette row.
///   • ThemeMode.system → both rows (the OS picks brightness, so the user
///     needs to be able to set the palette for either side).
class ThemeTile extends StatelessWidget {
  const ThemeTile({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final mode = controller.themeMode;
        final showLight = mode == ThemeMode.light || mode == ThemeMode.system;
        final showDark = mode == ThemeMode.dark || mode == ThemeMode.system;
        return Column(
          children: [
            _ModeRow(controller: controller),
            if (showLight) _LightVariantRow(controller: controller),
            if (showDark) _DarkVariantRow(controller: controller),
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
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: ThemeMode.system,
            label: _segmentLabel(context, 'auto'),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            label: _segmentLabel(context, 'light'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: _segmentLabel(context, 'dark'),
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
        showSelectedIcon: false,
        segments: [
          for (final v in LightVariant.values)
            ButtonSegment(
              value: v,
              label: _segmentLabel(context, _labelKey(v)),
            ),
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
        showSelectedIcon: false,
        segments: [
          for (final v in DarkVariant.values)
            ButtonSegment(
              value: v,
              label: _segmentLabel(context, _labelKey(v)),
            ),
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
