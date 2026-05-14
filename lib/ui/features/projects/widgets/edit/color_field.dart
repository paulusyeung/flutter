import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';

/// Hex color input with a live 24×24 swatch preview to the left. Tapping the
/// swatch opens a 12-preset palette dialog so users don't have to type a
/// hex code. Empty input clears the swatch (transparent).
///
/// Presets come from the legacy admin-portal `color_picker.dart` palette,
/// reduced to one representative per hue. Matching what users already saw
/// in the old app keeps muscle memory intact.
class ColorField extends StatefulWidget {
  const ColorField({super.key, required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<ColorField> {
  late String _value = widget.initial;

  static const List<String> _presets = <String>[
    '#F44336', // red
    '#E91E63', // pink
    '#9C27B0', // purple
    '#673AB7', // deep purple
    '#3F51B5', // indigo
    '#2196F3', // blue
    '#00BCD4', // cyan
    '#009688', // teal
    '#4CAF50', // green
    '#FF9800', // orange
    '#795548', // brown
    '#607D8B', // blue grey
  ];

  Future<void> _pickFromPresets() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('color')),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final hex in _presets)
                _PresetSwatch(hex: hex, onTap: () => Navigator.pop(ctx, hex)),
              _PresetSwatch(
                hex: '',
                clear: true,
                onTap: () => Navigator.pop(ctx, ''),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
    if (picked != null) {
      setState(() => _value = picked);
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(_value);
    // Wrap the swatch in an `IntrinsicHeight` row aligned center so the
    // swatch grows to the field's height automatically — no magic-pixel
    // padding to drift when `EntityEditField` tweaks its content padding.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: _pickFromPresets,
            borderRadius: BorderRadius.circular(InRadii.r1),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color ?? Colors.transparent,
                borderRadius: BorderRadius.circular(InRadii.r1),
                border: Border.all(color: context.inTheme.border),
              ),
              child: color == null
                  ? Icon(
                      Icons.colorize_outlined,
                      size: 14,
                      color: context.inTheme.ink3,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: InSpacing.sm),
          Expanded(
            child: EntityEditField(
              label: context.tr('color'),
              initial: widget.initial,
              onChanged: (v) {
                setState(() => _value = v);
                widget.onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({required this.hex, this.clear = false, this.onTap});
  final String hex;
  final bool clear;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(hex);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(InRadii.r1),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          borderRadius: BorderRadius.circular(InRadii.r1),
          border: Border.all(color: context.inTheme.border),
        ),
        child: clear
            ? Icon(Icons.close, size: 16, color: context.inTheme.ink3)
            : null,
      ),
    );
  }
}

Color? _parseHex(String hex) {
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length != 6) return null;
  final v = int.tryParse(s, radix: 16);
  if (v == null) return null;
  return Color(0xFF000000 | v);
}
