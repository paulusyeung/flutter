import 'package:flutter/material.dart';

import 'package:admin/app/color_hex.dart';
import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/accent_swatch_grid.dart';

/// One editable colour row: a label (+ optional description), a 36px swatch of
/// the current colour, a "modified" marker when overridden, and a reset
/// affordance. Tapping the row expands an inline picker (quick swatches + a
/// `#RRGGBB` field).
///
/// The host screen (Custom Theme) persists every change immediately through
/// `ThemeController`, so there is intentionally no `FormSaveScope` / save bar
/// here — Enter on the hex field commits the colour and nothing else.
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
    this.description,
  });

  final String label;

  /// Optional one-line explanation of what this token affects.
  final String? description;

  /// The resolved colour shown in the swatch (override if set, else base).
  final Color color;

  /// Whether this token is currently overridden (drives the reset button +
  /// the "modified" marker).
  final bool isOverridden;

  /// Quick-pick swatches appropriate to the token + side.
  final List<String> palette;

  final ValueChanged<Color> onChanged;
  final VoidCallback onReset;

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  bool _expanded = false;
  String? _error;
  late final TextEditingController _hex;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _hex = TextEditingController(text: formatHexColor(widget.color));
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant ColorPickerField old) {
    super.didUpdateWidget(old);
    // Re-sync only when the user isn't actively typing here. The whole editor
    // is one ListenableBuilder, so committing any row rebuilds every row;
    // without the focus guard a half-typed hex in another row would be
    // clobbered.
    if (!_focus.hasFocus) {
      final next = formatHexColor(widget.color);
      if (_hex.text != next) {
        _hex.text = next;
        _error = null;
      }
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onHexChanged(String raw) {
    // Live validation while typing: surface an error rather than silently
    // discarding the input on blur. A valid value applies immediately.
    final parsed = parseHexColor(raw);
    if (parsed != null) {
      setState(() => _error = null);
      widget.onChanged(parsed);
    } else {
      setState(
        () => _error = raw.trim().isEmpty
            ? null
            : context.tr('invalid_hex_color'),
      );
    }
  }

  void _commitHex(String raw) {
    final c = parseHexColor(raw);
    if (c != null) {
      setState(() => _error = null);
      widget.onChanged(c);
    } else {
      // Revert to the current value on blur, but only after the inline error
      // has already told the user why.
      _hex.text = formatHexColor(widget.color);
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Flexible(child: Text(widget.label)),
              if (widget.isOverridden) ...[
                SizedBox(width: InSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.accentSoft,
                    borderRadius: BorderRadius.circular(InRadii.r1),
                  ),
                  child: Text(
                    context.tr('modified'),
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.accentInk,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            widget.description == null
                ? formatHexColor(widget.color)
                : '${widget.description} · ${formatHexColor(widget.color)}',
            style: textTheme.bodySmall?.copyWith(color: tokens.ink3),
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
              // Non-interactive: the whole row is the single expand target,
              // so the swatch doesn't read as "tap to select" the way the
              // accent grid's swatches do.
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(InRadii.r2),
                  border: Border.all(color: tokens.border),
                ),
              ),
              SizedBox(width: InSpacing.sm),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more),
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
                    final c = parseHexColor(hex);
                    if (c != null) {
                      _hex.text = hex;
                      setState(() => _error = null);
                      widget.onChanged(c);
                    }
                  },
                ),
                SizedBox(height: InSpacing.md(context)),
                TextField(
                  controller: _hex,
                  focusNode: _focus,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: context.tr('color'),
                    hintText: '#RRGGBB',
                    isDense: true,
                    errorText: _error,
                  ),
                  onChanged: _onHexChanged,
                  onSubmitted: _commitHex,
                  onTapOutside: (_) {
                    if (_focus.hasFocus) {
                      _commitHex(_hex.text);
                      _focus.unfocus();
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
