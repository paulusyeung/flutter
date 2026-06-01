import 'dart:async';

import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/property_inputs.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/variable_picker.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

/// Phase 7e: per-block editor for the four text-bearing blocks (`text`,
/// `public-notes`, `terms`, `footer`). Refactored on top of the shared
/// `property_inputs.dart` helpers and extended with `lineHeight` and
/// `padding`, plus an **insert variable** affordance next to the content
/// editor — mirroring React's `TextBlockProperties.tsx`.
class TextBlockProperties extends StatefulWidget {
  const TextBlockProperties({super.key, required this.vm, required this.block});

  final WysiwygDesignViewModel vm;
  final DesignBlock block;

  @override
  State<TextBlockProperties> createState() => _TextBlockPropertiesState();
}

class _TextBlockPropertiesState extends State<TextBlockProperties> {
  late final TextEditingController _content;
  String _lastBlockId = '';
  // React debounces the content textarea at 300 ms
  // (`useDebouncedCallback(…, 300)`). Without this, every keystroke fires
  // notifyListeners → canvas rebuild → server-PDF preview render.
  Timer? _contentDebounce;
  static const _kContentDebounce = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _content = TextEditingController();
    _sync();
  }

  void _sync() {
    if (_lastBlockId == widget.block.id) return;
    _lastBlockId = widget.block.id;
    _content.text = (widget.block.properties['content'] as String?) ?? '';
    // A block-switch makes any pending debounced write meaningless.
    _contentDebounce?.cancel();
  }

  @override
  void didUpdateWidget(covariant TextBlockProperties old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _contentDebounce?.cancel();
    _content.dispose();
    super.dispose();
  }

  void _write(String key, Object? value) {
    widget.vm.updateBlock(
      widget.block.copyWith(
        properties: mergePropertyOrOmit(widget.block.properties, key, value),
      ),
    );
  }

  void _writeContentDebounced(String value) {
    _contentDebounce?.cancel();
    _contentDebounce = Timer(_kContentDebounce, () {
      if (!mounted) return;
      _write('content', value);
    });
  }

  Future<void> _insertVariable() async {
    final picked = await showVariablePicker(context);
    if (picked == null || !mounted) return;
    final sel = _content.selection;
    final text = _content.text;
    final insertAt = sel.isValid ? sel.start : text.length;
    final next =
        '${text.substring(0, insertAt)}$picked${text.substring(sel.isValid ? sel.end : text.length)}';
    _content.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: insertAt + picked.length),
    );
    // Variable insert is a discrete action — flush any pending debounced
    // typing write so it can't clobber the picker insertion later.
    _contentDebounce?.cancel();
    _write('content', next);
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.block.properties;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('content'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.code, size: 16),
              label: Text(context.tr('insert_variable')),
              onPressed: _insertVariable,
            ),
          ],
        ),
        SizedBox(height: InSpacing.sm),
        TextField(
          controller: _content,
          minLines: 3,
          maxLines: null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: _writeContentDebounced,
        ),
        const SectionDivider(labelKey: 'typography'),
        FontSizeInput(
          labelKey: 'font_size',
          value: props['fontSize'] as String?,
          onChanged: (v) => _write('fontSize', v),
        ),
        SizedBox(height: InSpacing.md(context)),
        FontStyleInput(
          fontWeight: props['fontWeight'] as String?,
          fontStyle: props['fontStyle'] as String?,
          onFontWeightChanged: (v) => _write('fontWeight', v),
          onFontStyleChanged: (v) => _write('fontStyle', v),
        ),
        SizedBox(height: InSpacing.md(context)),
        LineHeightInput(
          labelKey: 'line_height',
          value: props['lineHeight'] as String?,
          onChanged: (v) => _write('lineHeight', v),
        ),
        SizedBox(height: InSpacing.md(context)),
        ColorInput(
          labelKey: 'color',
          value: props['color'] as String?,
          onChanged: (v) => _write('color', v),
        ),
        const SectionDivider(labelKey: 'layout'),
        AlignmentInput(
          labelKey: 'alignment',
          value: props['align'] as String?,
          onChanged: (v) => _write('align', v),
        ),
        const SectionDivider(labelKey: 'spacing'),
        PxInput(
          labelKey: 'padding',
          value: props['padding'],
          resettable: true,
          onChanged: (v) => _write('padding', v),
        ),
      ],
    );
  }
}
