import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/_shared.dart'
    show parseCssColor;

/// Shared property-panel widgets. Ports React's
/// `components/properties/PropertyInputs.tsx` patterns into a thin set of
/// `Stateless`/`Stateful` widgets so the per-block editors stay terse.
///
/// Conventions:
/// - `value` is whatever the underlying `block.properties[key]` shape is
///   (typically `String?` — '24px', '#000000', 'left'). Empty / null
///   means "use the renderer default."
/// - `onChanged` receives the new value, or `null` when the user clears
///   the control. Callers should `mergePxOrOmit`-style remove the key
///   from the properties map when `null` to keep the wire payload lean.

/// Thin uppercase section divider with a centered label. Matches React's
/// `<SectionDivider label="…" />`.
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key, required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.md(context)),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: tokens.border)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: InSpacing.sm),
            child: Text(
              context.tr(labelKey).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: tokens.ink3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(height: 1, color: tokens.border)),
        ],
      ),
    );
  }
}

/// L/C/R `SegmentedButton` shared by Text / Image / QR / Info /
/// InvoiceDetails / Total editors.
class AlignmentInput extends StatelessWidget {
  const AlignmentInput({
    super.key,
    required this.labelKey,
    required this.value,
    required this.onChanged,
  });

  final String labelKey;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = (value == null || value!.isEmpty) ? 'left' : value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(labelKey),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        SizedBox(height: InSpacing.sm),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'left',
              icon: const Icon(Icons.format_align_left, size: 18),
              label: Text(context.tr('left')),
            ),
            ButtonSegment(
              value: 'center',
              icon: const Icon(Icons.format_align_center, size: 18),
              label: Text(context.tr('center')),
            ),
            ButtonSegment(
              value: 'right',
              icon: const Icon(Icons.format_align_right, size: 18),
              label: Text(context.tr('right')),
            ),
          ],
          selected: {v},
          onSelectionChanged: (s) => onChanged(s.first),
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

/// Bold + Italic toggle pair, sharing a row. React combines these into one
/// `FontStyleInput` because they're always rendered together.
class FontStyleInput extends StatelessWidget {
  const FontStyleInput({
    super.key,
    required this.fontWeight,
    required this.fontStyle,
    required this.onFontWeightChanged,
    required this.onFontStyleChanged,
  });

  final String? fontWeight;
  final String? fontStyle;
  final ValueChanged<String> onFontWeightChanged;
  final ValueChanged<String> onFontStyleChanged;

  @override
  Widget build(BuildContext context) {
    final isBold = fontWeight == 'bold' || fontWeight == '700';
    final isItalic = fontStyle == 'italic';
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(Icons.format_bold,
                color: isBold ? context.inTheme.accent : null),
            label: Text(context.tr('bold')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 40),
              backgroundColor:
                  isBold ? context.inTheme.accentSoft : null,
            ),
            onPressed: () =>
                onFontWeightChanged(isBold ? 'normal' : 'bold'),
          ),
        ),
        SizedBox(width: InSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(Icons.format_italic,
                color: isItalic ? context.inTheme.accent : null),
            label: Text(context.tr('italic')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 40),
              backgroundColor:
                  isItalic ? context.inTheme.accentSoft : null,
            ),
            onPressed: () =>
                onFontStyleChanged(isItalic ? 'normal' : 'italic'),
          ),
        ),
      ],
    );
  }
}

/// Hex color field with a colored swatch leading icon. Tap the swatch to
/// reset to the fallback. Empty input emits `''` — callers translate to
/// null via the property-mutator pattern.
class ColorInput extends StatefulWidget {
  const ColorInput({
    super.key,
    required this.labelKey,
    required this.value,
    required this.onChanged,
    this.defaultValue,
  });

  final String labelKey;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? defaultValue;

  @override
  State<ColorInput> createState() => _ColorInputState();
}

class _ColorInputState extends State<ColorInput> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(covariant ColorInput old) {
    super.didUpdateWidget(old);
    if ((widget.value ?? '') != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effective = (widget.value?.isNotEmpty ?? false)
        ? widget.value!
        : (widget.defaultValue ?? '#000000');
    final swatch = parseCssColor(effective);
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.tr(widget.labelKey),
        hintText: widget.defaultValue ?? '#000000',
        border: const OutlineInputBorder(),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: GestureDetector(
            onTap: () => widget.onChanged(''),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: context.inTheme.border, width: 1),
              ),
            ),
          ),
        ),
      ),
      onChanged: (v) => widget.onChanged(v.trim()),
    );
  }
}

/// Preset chips + free entry for font sizes. Chips render `12px`,
/// `14px`, …; tapping one writes that value.
class FontSizeInput extends StatelessWidget {
  const FontSizeInput({
    super.key,
    required this.labelKey,
    required this.value,
    required this.onChanged,
    this.presets = const ['12px', '14px', '16px', '18px', '24px', '32px'],
  });

  final String labelKey;
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String> presets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(labelKey),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        SizedBox(height: InSpacing.sm),
        Wrap(
          spacing: 6,
          children: [
            for (final p in presets)
              ChoiceChip(
                label: Text(p),
                selected: value == p,
                onSelected: (s) => onChanged(s ? p : null),
              ),
          ],
        ),
        SizedBox(height: InSpacing.sm),
        PxInput(
          labelKey: 'font_size',
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Number-with-optional-`px` field. Empty input emits `null` so callers
/// can `mergePxOrOmit` (remove the key entirely from `block.properties`).
/// Optional [minPx] / [maxPx] clamp the parsed integer before it's
/// re-emitted — mirrors React's `coerceBorderWidthPx` for the table
/// border editor.
class PxInput extends StatefulWidget {
  const PxInput({
    super.key,
    required this.labelKey,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.resettable = false,
    this.minPx,
    this.maxPx,
  });

  final String labelKey;
  final Object? value;
  final ValueChanged<String?> onChanged;
  final String? hintText;
  final bool resettable;
  final int? minPx;
  final int? maxPx;

  @override
  State<PxInput> createState() => _PxInputState();
}

class _PxInputState extends State<PxInput> {
  late final TextEditingController _controller;
  Object? _lastBoundValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _stringify(widget.value));
    _lastBoundValue = widget.value;
  }

  static String _stringify(Object? v) {
    if (v == null) return '';
    final s = v.toString();
    return s.replaceAll('px', '');
  }

  @override
  void didUpdateWidget(covariant PxInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _lastBoundValue) {
      _lastBoundValue = widget.value;
      final next = _stringify(widget.value);
      if (next != _controller.text) {
        _controller.text = next;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: context.tr(widget.labelKey),
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        suffixIcon: widget.resettable && _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged(null);
                },
              )
            : null,
      ),
      onChanged: (v) {
        final trimmed = v.trim();
        if (trimmed.isEmpty) {
          widget.onChanged(null);
          return;
        }
        final parsed = int.tryParse(trimmed);
        if (parsed == null) {
          widget.onChanged(null);
          return;
        }
        var clamped = parsed;
        if (widget.minPx != null && clamped < widget.minPx!) {
          clamped = widget.minPx!;
        }
        if (widget.maxPx != null && clamped > widget.maxPx!) {
          clamped = widget.maxPx!;
        }
        widget.onChanged('${clamped}px');
      },
    );
  }
}

/// LineHeight is a unit-less float; presets at 1.0 / 1.2 / 1.4 / 1.6 /
/// 2.0 cover the common cases.
class LineHeightInput extends StatelessWidget {
  const LineHeightInput({
    super.key,
    required this.labelKey,
    required this.value,
    required this.onChanged,
  });

  final String labelKey;
  final String? value;
  final ValueChanged<String?> onChanged;

  static const List<String> _presets = ['1.0', '1.2', '1.3', '1.4', '1.6', '2.0'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(labelKey),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        SizedBox(height: InSpacing.sm),
        Wrap(
          spacing: 6,
          children: [
            for (final p in _presets)
              ChoiceChip(
                label: Text(p),
                selected: value == p,
                onSelected: (s) => onChanged(s ? p : null),
              ),
          ],
        ),
      ],
    );
  }
}

/// Property-mutation helper mirroring React's `mergePxOrOmit`:
/// - `null` / empty → remove the key from `properties` entirely.
/// - everything else → set the key to the value.
/// Centralizes the "lean wire payload" rule from React.
Map<String, dynamic> mergePropertyOrOmit(
  Map<String, dynamic> properties,
  String key,
  Object? value,
) {
  final next = Map<String, dynamic>.from(properties);
  if (value == null || (value is String && value.isEmpty)) {
    next.remove(key);
  } else {
    next[key] = value;
  }
  return next;
}
