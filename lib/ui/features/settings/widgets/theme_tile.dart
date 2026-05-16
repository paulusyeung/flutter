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

String _lightVariantKey(LightVariant v) => switch (v) {
  LightVariant.sand => 'variant_sand',
  LightVariant.mist => 'variant_mist',
  LightVariant.paper => 'variant_paper',
  LightVariant.custom => 'custom',
};

String _darkVariantKey(DarkVariant v) => switch (v) {
  DarkVariant.espresso => 'variant_espresso',
  DarkVariant.midnight => 'variant_midnight',
  DarkVariant.carbon => 'variant_carbon',
  DarkVariant.custom => 'custom',
};

void _openCustomEditor(BuildContext context, ThemeController controller) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CustomThemeScreen(controller: controller),
    ),
  );
}

/// Switch a variant and, if it's a first switch to Custom with nothing set,
/// open the editor. The navigation is deferred to **after** the frame:
/// `setLightVariant`/`setDarkVariant` notify synchronously, which rebuilds
/// `ThemeTile` (and the GoRouter shell) — pushing a route in that same pass
/// reparents the router's Navigator and throws (duplicate GlobalKey / wrong
/// build scope). The override check reads in-memory state, so no `await`.
void _selectVariantAndMaybeEdit({
  required BuildContext context,
  required ThemeController controller,
  required bool isCustom,
  required bool hasNoOverrides,
  required VoidCallback apply,
}) {
  apply();
  if (isCustom && hasNoOverrides) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) _openCustomEditor(context, controller);
    });
  }
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
            if (anyCustom && mode == ThemeMode.system)
              Padding(
                padding: EdgeInsets.only(top: InSpacing.sm),
                child: Text(
                  context.tr('auto_uses_both_palettes'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.inTheme.ink3,
                  ),
                ),
              ),
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
            ButtonSegment(
              value: v,
              label: Text(
                context.tr(_lightVariantKey(v)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        selected: {controller.lightVariant},
        onSelectionChanged: (s) {
          final v = s.first;
          _selectVariantAndMaybeEdit(
            context: context,
            controller: controller,
            isCustom: v == LightVariant.custom,
            hasNoOverrides: controller.customTheme.lightOverrides.isEmpty,
            apply: () => controller.setLightVariant(v),
          );
        },
      ),
    );
  }
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
            ButtonSegment(
              value: v,
              label: Text(
                context.tr(_darkVariantKey(v)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        selected: {controller.darkVariant},
        onSelectionChanged: (s) {
          final v = s.first;
          _selectVariantAndMaybeEdit(
            context: context,
            controller: controller,
            isCustom: v == DarkVariant.custom,
            hasNoOverrides: controller.customTheme.darkOverrides.isEmpty,
            apply: () => controller.setDarkVariant(v),
          );
        },
      ),
    );
  }
}

class _CustomSummaryTile extends StatelessWidget {
  const _CustomSummaryTile({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final ct = controller.customTheme;

    String sidePhrase(String sideKey, int count, String baseLabelKey) {
      if (count == 0) {
        return '${context.tr(sideKey)}: '
            '${context.tr('using_base_preset')
                .replaceFirst('{preset}', context.tr(baseLabelKey))}';
      }
      return '${context.tr(sideKey)}: '
          '${context.tr('colors_customized')
              .replaceFirst('{count}', '$count')}';
    }

    final parts = <String>[];
    if (controller.lightVariant == LightVariant.custom) {
      parts.add(
        sidePhrase(
          'light',
          ct.lightOverrides.length,
          _lightVariantKey(ct.lightBase),
        ),
      );
    }
    if (controller.darkVariant == DarkVariant.custom) {
      parts.add(
        sidePhrase(
          'dark',
          ct.darkOverrides.length,
          _darkVariantKey(ct.darkBase),
        ),
      );
    }
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(context.tr('custom_theme')),
      subtitle: Text(parts.join('\n')),
      isThreeLine: parts.length > 1,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CustomThemeScreen(controller: controller),
        ),
      ),
    );
  }
}
