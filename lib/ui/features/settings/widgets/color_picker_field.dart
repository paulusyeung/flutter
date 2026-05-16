import 'package:flutter/material.dart';

import 'package:admin/app/color_hex.dart';
import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/accent_swatch_grid.dart';

/// One editable colour row: a label, a 36px swatch of the current colour, and
/// a reset affordance. Tapping the swatch expands an inline picker (quick
/// swatches + a `#RRGGBB` field) — inline, not a modal, to match how every
/// other colour picker in the app behaves (Preferences accent, TaskStatuses).
///
/// Stateless w.r.t. the value: the parent owns the colour and feeds [color];
/// edits are emitted through [onChanged] / [onReset].
class ColorPickerField extends StatefulWidget {
  const ColorPickerField({
    super.key,
    required this.label,
    required this.color,
    required this.isOverridden,
    required this.palette,
    required this.onChanged,
    required this.onReset,
  });

  final String label;

  /// The resolved colour shown in the swatch (override if set, else base).
  final Color color;

  /// Whether this token is currently overridden (enables the reset button).
  final bool isOverridden;

  /// Quick-pick swatches appropriate to the token (accent / status / neutral).
  final List<String> palette;

  final ValueChanged<Color> onChanged;
  final VoidCallback onReset;

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  bool _expanded = false;
  late final TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    _hex = TextEditingController(text: formatHexColor(widget.color));
  }

  @override
  void didUpdateWidget(covariant ColorPickerField old) {
    super.didUpdateWidget(old);
    // Keep the field in sync when the colour changes from elsewhere (a quick
    // swatch tap, a reset) while the editor isn't focused on the text box.
    final next = formatHexColor(widget.color);
    if (next != formatHexColor(_parse(_hex.text) ?? widget.color)) {
      _hex.text = next;
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  Color? _parse(String s) => parseHexColor(s);

  void _commitHex(String raw) {
    final c = _parse(raw);
    if (c != null) {
      widget.onChanged(c);
    } else {
      // Silent revert to the current value — no red-border noise.
      _hex.text = formatHexColor(widget.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(widget.label),
          subtitle: Text(
            formatHexColor(widget.color),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.ink3),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isOverridden)
                IconButton(
                  tooltip: context.tr('reset'),
                  icon: const Icon(Icons.refresh),
                  onPressed: widget.onReset,
                ),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(InRadii.r2),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(InRadii.r2),
                    border: Border.all(
                      color: _expanded ? tokens.ink : tokens.border,
                      width: _expanded ? 2 : 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          Container(
            margin: EdgeInsets.only(bottom: InSpacing.md(context)),
            padding: EdgeInsets.all(InSpacing.lg(context)),
            decoration: BoxDecoration(
              border: Border.all(color: tokens.border),
              borderRadius: BorderRadius.circular(InRadii.r3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccentSwatchGrid(
                  selected: formatHexColor(widget.color),
                  palette: widget.palette,
                  onSelected: (hex) {
                    final c = _parse(hex);
                    if (c != null) widget.onChanged(c);
                  },
                ),
                SizedBox(height: InSpacing.md(context)),
                TextField(
                  controller: _hex,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: context.tr('color'),
                    hintText: '#RRGGBB',
                    isDense: true,
                  ),
                  onSubmitted: _commitHex,
                  onEditingComplete: () => _commitHex(_hex.text),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
