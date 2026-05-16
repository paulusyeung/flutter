import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme_controller.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/accent_swatch_grid.dart';
import 'package:admin/ui/features/settings/widgets/color_picker_field.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Editor for the user's custom light + dark palettes. Pushed from the
/// "Custom palette" summary tile on User Details → Preferences. A top
/// Light/Dark toggle lets the user edit (and *see*, via the preview card)
/// the side that isn't the current OS brightness. Each change persists
/// immediately through [ThemeController] (device-local), so there is no
/// save bar.
class CustomThemeScreen extends StatefulWidget {
  const CustomThemeScreen({super.key, required this.controller});

  final ThemeController controller;

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  Brightness _side = Brightness.light;

  static const _rows = <(CustomToken, String, List<String>)>[
    (CustomToken.background, 'background', kAccentSwatches),
    (CustomToken.surface, 'surface', kAccentSwatches),
    (CustomToken.ink, 'text_color', kAccentSwatches),
    (CustomToken.accent, 'accent', kAccentSwatches),
    (CustomToken.border, 'border', kAccentSwatches),
    (CustomToken.statusPaid, 'paid', kStatusSwatches),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('custom_theme'))),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final ct = widget.controller.customTheme;
          final isDark = _side == Brightness.dark;
          final resolved = isDark ? ct.resolveDark() : ct.resolveLight();
          final base = isDark ? ct.darkBase.tokens : ct.lightBase.tokens;
          final accent =
              (isDark ? ct.darkAccent : ct.lightAccent) ?? base.accent;
          final overrides = ct.overridesFor(_side);

          Color colorFor(CustomToken t) => switch (t) {
            CustomToken.background => resolved.bg,
            CustomToken.surface => resolved.surface,
            CustomToken.ink => resolved.ink,
            CustomToken.accent => accent,
            CustomToken.border => resolved.border,
            CustomToken.statusPaid => resolved.paid,
          };

          return SettingsFormShell(
            sections: [
              FormSection(
                title: context.tr('custom_theme'),
                children: [
                  SegmentedButton<Brightness>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: Brightness.light,
                        label: Text(context.tr('light')),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: Brightness.dark,
                        label: Text(context.tr('dark')),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {_side},
                    onSelectionChanged: (s) =>
                        setState(() => _side = s.first),
                  ),
                  SizedBox(height: InSpacing.lg(context)),
                  _BasePresetPicker(
                    side: _side,
                    controller: widget.controller,
                  ),
                  SizedBox(height: InSpacing.lg(context)),
                  _PreviewCard(tokens: resolved, accent: accent),
                ],
              ),
              FormSection(
                title: context.tr('colors'),
                spacing: 0,
                children: [
                  for (final (token, labelKey, palette) in _rows)
                    ColorPickerField(
                      label: context.tr(labelKey),
                      color: colorFor(token),
                      isOverridden: overrides.containsKey(token),
                      palette: palette,
                      onChanged: (c) => widget.controller.setCustomOverride(
                        _side,
                        token,
                        c,
                      ),
                      onReset: () =>
                          widget.controller.clearCustomOverride(_side, token),
                    ),
                  if (overrides.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(context.tr('reset')),
                        onPressed: () =>
                            widget.controller.clearCustomSide(_side),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BasePresetPicker extends StatelessWidget {
  const _BasePresetPicker({required this.side, required this.controller});

  final Brightness side;
  final ThemeController controller;

  static String _lightKey(LightVariant v) => switch (v) {
    LightVariant.sand => 'variant_sand',
    LightVariant.mist => 'variant_mist',
    LightVariant.paper => 'variant_paper',
    LightVariant.custom => 'custom',
  };

  static String _darkKey(DarkVariant v) => switch (v) {
    DarkVariant.espresso => 'variant_espresso',
    DarkVariant.midnight => 'variant_midnight',
    DarkVariant.carbon => 'variant_carbon',
    DarkVariant.custom => 'custom',
  };

  @override
  Widget build(BuildContext context) {
    final ct = controller.customTheme;
    final Widget picker = side == Brightness.dark
        ? SegmentedButton<DarkVariant>(
            showSelectedIcon: false,
            segments: [
              for (final v in kDarkPresets)
                ButtonSegment(value: v, label: Text(context.tr(_darkKey(v)))),
            ],
            selected: {ct.darkBase},
            onSelectionChanged: (s) => controller.setCustomDarkBase(s.first),
          )
        : SegmentedButton<LightVariant>(
            showSelectedIcon: false,
            segments: [
              for (final v in kLightPresets)
                ButtonSegment(value: v, label: Text(context.tr(_lightKey(v)))),
            ],
            selected: {ct.lightBase},
            onSelectionChanged: (s) => controller.setCustomLightBase(s.first),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('base'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: InSpacing.md(context)),
        SizedBox(width: double.infinity, child: picker),
      ],
    );
  }
}

/// A bounded sample of the palette being edited — painted with the resolved
/// custom [InTheme] regardless of the OS brightness, so editing the
/// off-brightness side is sighted. Mirrors the TaskStatuses preview idea.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.tokens, required this.accent});

  final InTheme tokens;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border.all(color: tokens.borderStrong),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(InSpacing.lg(context)),
            decoration: BoxDecoration(
              color: tokens.surface,
              border: Border.all(color: tokens.border),
              borderRadius: BorderRadius.circular(InRadii.r2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('preview'),
                  style: TextStyle(
                    color: tokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: InSpacing.sm),
                Text(
                  'Aa Bb Cc 123',
                  style: TextStyle(color: tokens.ink2),
                ),
                SizedBox(height: InSpacing.md(context)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(InRadii.r2),
                      ),
                      child: Text(
                        context.tr('accent'),
                        style: TextStyle(color: onAccent),
                      ),
                    ),
                    SizedBox(width: InSpacing.md(context)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.paidSoft,
                        borderRadius: BorderRadius.circular(InRadii.r2),
                      ),
                      child: Text(
                        context.tr('paid'),
                        style: TextStyle(color: tokens.paid),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
