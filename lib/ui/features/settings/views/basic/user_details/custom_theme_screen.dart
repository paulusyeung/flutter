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

/// (token, label key, description key) — palette is resolved per side so the
/// structural tokens get a usable neutral ramp instead of brand hues.
const _kRows = <(CustomToken, String, String)>[
  (CustomToken.background, 'background', 'custom_token_background'),
  (CustomToken.surface, 'surface', 'custom_token_surface'),
  (CustomToken.ink, 'text_color', 'custom_token_text'),
  (CustomToken.accent, 'accent', 'custom_token_accent'),
  (CustomToken.border, 'border', 'custom_token_border'),
  (CustomToken.statusPaid, 'paid', 'custom_token_paid'),
];

List<String> _paletteFor(CustomToken token, Brightness side) {
  final dark = side == Brightness.dark;
  return switch (token) {
    CustomToken.background ||
    CustomToken.surface => dark ? kDarkSurfaceSwatches : kLightSurfaceSwatches,
    CustomToken.ink => dark ? kDarkInkSwatches : kLightInkSwatches,
    CustomToken.border => dark ? kDarkBorderSwatches : kLightBorderSwatches,
    CustomToken.accent => kAccentSwatches,
    CustomToken.statusPaid => kStatusSwatches,
  };
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  Brightness _side = Brightness.light;

  Future<void> _confirmResetSide() async {
    final isDark = _side == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ctx.tr(isDark ? 'reset_dark_palette' : 'reset_light_palette'),
        ),
        content: Text(ctx.tr('reset_custom_side_confirm')),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          SizedBox(width: InSpacing.md(context)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('reset')),
          ),
        ],
      ),
    );
    if (ok == true) await widget.controller.clearCustomSide(_side);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _side == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('custom_theme'))),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final ct = widget.controller.customTheme;
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
                title: context.tr('preview'),
                children: [
                  Text(
                    context.tr('custom_editing_side_caption'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.inTheme.ink3,
                    ),
                  ),
                  SizedBox(height: InSpacing.md(context)),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<Brightness>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: Brightness.light,
                          label: Text(
                            context.tr('light'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          icon: const Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: Brightness.dark,
                          label: Text(
                            context.tr('dark'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          icon: const Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {_side},
                      onSelectionChanged: (s) =>
                          setState(() => _side = s.first),
                    ),
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
                title: context.tr(isDark ? 'dark_colors' : 'light_colors'),
                spacing: 0,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: InSpacing.md(context)),
                    child: Text(
                      context.tr('custom_colors_intro'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.inTheme.ink3,
                      ),
                    ),
                  ),
                  for (final (token, labelKey, descKey) in _kRows)
                    ColorPickerField(
                      label: context.tr(labelKey),
                      description: context.tr(descKey),
                      color: colorFor(token),
                      isOverridden: overrides.containsKey(token),
                      palette: _paletteFor(token, _side),
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
                        label: Text(
                          context.tr(
                            isDark
                                ? 'reset_dark_palette'
                                : 'reset_light_palette',
                          ),
                        ),
                        onPressed: _confirmResetSide,
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

  Widget _label(BuildContext context, String key) => Text(
    context.tr(key),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  @override
  Widget build(BuildContext context) {
    final ct = controller.customTheme;
    final Widget picker = side == Brightness.dark
        ? SegmentedButton<DarkVariant>(
            showSelectedIcon: false,
            segments: [
              for (final v in kDarkPresets)
                ButtonSegment(value: v, label: _label(context, _darkKey(v))),
            ],
            selected: {ct.darkBase},
            onSelectionChanged: (s) => controller.setCustomDarkBase(s.first),
          )
        : SegmentedButton<LightVariant>(
            showSelectedIcon: false,
            segments: [
              for (final v in kLightPresets)
                ButtonSegment(value: v, label: _label(context, _lightKey(v))),
            ],
            selected: {ct.lightBase},
            onSelectionChanged: (s) => controller.setCustomLightBase(s.first),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('base'), style: Theme.of(context).textTheme.labelLarge),
        SizedBox(height: InSpacing.md(context)),
        SizedBox(width: double.infinity, child: picker),
      ],
    );
  }
}

/// A bounded sample of the palette being edited — painted with the resolved
/// custom [InTheme] regardless of the OS brightness, so editing the
/// off-brightness side is sighted. Exercises every editable token: a rail
/// strip, a card with a faux list row, an accent button and a paid pill.
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border.all(color: tokens.borderStrong),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar rail strip.
          Container(
            width: 12,
            color: tokens.rail,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(InSpacing.lg(context)),
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
                  SizedBox(height: InSpacing.md(context)),
                  // Faux list row on a card surface.
                  Container(
                    padding: EdgeInsets.all(InSpacing.lg(context)),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      border: Border.all(color: tokens.border),
                      borderRadius: BorderRadius.circular(InRadii.r2),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: accent,
                          child: Text(
                            'IN',
                            style: TextStyle(color: onAccent, fontSize: 12),
                          ),
                        ),
                        SizedBox(width: InSpacing.md(context)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Acme Inc.',
                                style: TextStyle(color: tokens.ink),
                              ),
                              Text(
                                'invoice #1042',
                                style: TextStyle(
                                  color: tokens.ink3,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.paidSoft,
                            borderRadius: BorderRadius.circular(InRadii.r1),
                          ),
                          child: Text(
                            context.tr('paid'),
                            style: TextStyle(
                              color: tokens.paid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: InSpacing.md(context)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(InRadii.r2),
                      ),
                      child: Text(
                        context.tr('accent'),
                        style: TextStyle(
                          color: onAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
