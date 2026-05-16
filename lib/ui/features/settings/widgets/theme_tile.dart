import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme_controller.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/custom_theme_screen.dart';

// Width of the SizedBox we wrap every mode-row segment label in. Pins each
// segment's intrinsic width so the three mode pills line up. 80 comfortably
// fits the mode labels at Inter Tight 14px; longer labels ellipsize rather
// than stretching the segment. The variant rows no longer use this — they
// render a full-width segmented button (4 segments incl. Custom) on their
// own row so they fit on mobile without clipping.
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

/// Stacked rows for the user's theme preferences:
///   • Mode (System / Light / Dark) — always present.
///   • Light palette — shown for Light / System; Sand / Mist / Paper / Custom.
///   • Dark palette  — shown for Dark / System; Espresso / Midnight / Carbon /
///     Custom.
///   • A "Custom palette" summary tile — shown when either side is Custom;
///     opens the editor sub-screen.
/// Under System the OS picks brightness, so a custom-light palette by day and
/// a custom-dark palette by night switch automatically.
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
        final anyCustom =
            controller.lightVariant == LightVariant.custom ||
            controller.darkVariant == DarkVariant.custom;
        return Column(
          children: [
            _ModeRow(controller: controller),
            if (showLight) _LightVariantRow(controller: controller),
            if (showDark) _DarkVariantRow(controller: controller),
            if (anyCustom) _CustomSummaryTile(controller: controller),
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

/// A label above a full-width segmented button. Used by both variant rows so
/// 4 segments (incl. Custom) fit any width without the fixed-width clipping
/// the trailing-segment layout would cause on mobile.
class _FullWidthVariantRow extends StatelessWidget {
  const _FullWidthVariantRow({
    required this.icon,
    required this.labelKey,
    required this.child,
  });

  final IconData icon;
  final String labelKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.md(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              SizedBox(width: InSpacing.md(context)),
              Text(context.tr(labelKey)),
            ],
          ),
          SizedBox(height: InSpacing.md(context)),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _LightVariantRow extends StatelessWidget {
  const _LightVariantRow({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return _FullWidthVariantRow(
      icon: Icons.light_mode_outlined,
      labelKey: 'light_variant',
      child: SegmentedButton<LightVariant>(
        showSelectedIcon: false,
        segments: [
          for (final v in LightVariant.values)
            ButtonSegment(value: v, label: Text(context.tr(_labelKey(v)))),
        ],
        selected: {controller.lightVariant},
        onSelectionChanged: (s) => controller.setLightVariant(s.first),
      ),
    );
  }

  static String _labelKey(LightVariant v) => switch (v) {
    LightVariant.sand => 'variant_sand',
    LightVariant.mist => 'variant_mist',
    LightVariant.paper => 'variant_paper',
    LightVariant.custom => 'custom',
  };
}

class _DarkVariantRow extends StatelessWidget {
  const _DarkVariantRow({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return _FullWidthVariantRow(
      icon: Icons.dark_mode_outlined,
      labelKey: 'dark_variant',
      child: SegmentedButton<DarkVariant>(
        showSelectedIcon: false,
        segments: [
          for (final v in DarkVariant.values)
            ButtonSegment(value: v, label: Text(context.tr(_labelKey(v)))),
        ],
        selected: {controller.darkVariant},
        onSelectionChanged: (s) => controller.setDarkVariant(s.first),
      ),
    );
  }

  static String _labelKey(DarkVariant v) => switch (v) {
    DarkVariant.espresso => 'variant_espresso',
    DarkVariant.midnight => 'variant_midnight',
    DarkVariant.carbon => 'variant_carbon',
    DarkVariant.custom => 'custom',
  };
}

class _CustomSummaryTile extends StatelessWidget {
  const _CustomSummaryTile({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final ct = controller.customTheme;
    final parts = <String>[];
    if (controller.lightVariant == LightVariant.custom) {
      parts.add('${context.tr('light')} · ${ct.lightOverrides.length}');
    }
    if (controller.darkVariant == DarkVariant.custom) {
      parts.add('${context.tr('dark')} · ${ct.darkOverrides.length}');
    }
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(context.tr('custom_theme')),
      subtitle: Text(parts.join('     ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CustomThemeScreen(controller: controller),
        ),
      ),
    );
  }
}
