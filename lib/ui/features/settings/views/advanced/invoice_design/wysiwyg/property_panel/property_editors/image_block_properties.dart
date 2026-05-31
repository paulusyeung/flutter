import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/property_inputs.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

/// Property editor for `image` and `logo` blocks. Phase 7f matches
/// React's `ImageBlockProperties.tsx` surface:
/// - in-editor preview + remove (X) for `data:` / `http(s)` sources
/// - drag-and-drop dropzone on desktop, file-picker upload everywhere
/// - **Use Company Logo** quick-button → `source = '$company.logo'`
/// - `maxWidth` + `maxHeight` + `padding` PxInputs
/// - alignment SegmentedButton + objectFit dropdown
/// - hides the uploader UI on `logo` blocks (mirrors React's
///   `block.type !== 'logo'` guard)
class ImageBlockProperties extends StatefulWidget {
  const ImageBlockProperties({
    super.key,
    required this.vm,
    required this.block,
  });

  final WysiwygDesignViewModel vm;
  final DesignBlock block;

  @override
  State<ImageBlockProperties> createState() => _ImageBlockPropertiesState();
}

class _ImageBlockPropertiesState extends State<ImageBlockProperties> {
  late final TextEditingController _source;
  String _lastBlockId = '';
  bool _dropHover = false;

  @override
  void initState() {
    super.initState();
    _source = TextEditingController();
    _sync();
  }

  void _sync() {
    if (_lastBlockId == widget.block.id) return;
    _lastBlockId = widget.block.id;
    _source.text =
        (widget.block.properties['source'] as String?) ?? '';
  }

  @override
  void didUpdateWidget(covariant ImageBlockProperties old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  void _write(String key, Object? value) {
    widget.vm.updateBlock(
      widget.block.copyWith(
        properties:
            mergePropertyOrOmit(widget.block.properties, key, value),
      ),
    );
  }

  String _mimeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'application/octet-stream';
  }

  Future<void> _commitBytes(Uint8List bytes, String filename) async {
    const maxBytes = 2 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      if (!mounted) return;
      Notify.error(context, context.tr('file_too_large'));
      return;
    }
    final mime = _mimeFor(filename);
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    setState(() => _source.text = dataUrl);
    _write('source', dataUrl);
  }

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      Notify.error(context, context.tr('error_unable_to_upload'));
      return;
    }
    await _commitBytes(bytes, file.name);
  }

  Future<void> _onDrop(DropDoneDetails details) async {
    setState(() => _dropHover = false);
    if (details.files.isEmpty) return;
    final f = details.files.first;
    try {
      final bytes = await f.readAsBytes();
      await _commitBytes(bytes, f.name);
    } catch (_) {
      if (!mounted) return;
      Notify.error(context, context.tr('error_unable_to_upload'));
    }
  }

  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    final props = widget.block.properties;
    final src = _source.text;
    final isLogo = widget.block.type == 'logo';
    final hasImage = src.startsWith('data:') ||
        src.startsWith('http://') ||
        src.startsWith('https://');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Uploader is hidden on the `logo` block — React's
        // `block.type !== 'logo'` guard. Logo blocks are driven by the
        // company's stored logo (and a "Use Company Logo" button
        // re-attaches if the user typed something else).
        if (!isLogo) _ImageUploader(
          hasImage: hasImage,
          src: src,
          dropHover: _dropHover,
          canDrop: _isDesktop,
          onPick: _pickAndUpload,
          onRemove: () {
            setState(() => _source.clear());
            _write('source', null);
          },
          onDropEnter: () => setState(() => _dropHover = true),
          onDropLeave: () => setState(() => _dropHover = false),
          onDrop: _onDrop,
        ),
        if (!isLogo) SizedBox(height: InSpacing.md(context)),
        OutlinedButton.icon(
          icon: const Icon(Icons.business_outlined, size: 16),
          label: Text(context.tr('use_company_logo')),
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () {
            setState(() => _source.text = r'$company.logo');
            _write('source', r'$company.logo');
          },
        ),
        SizedBox(height: InSpacing.md(context)),
        TextField(
          controller: _source,
          decoration: InputDecoration(
            labelText: context.tr('image_url'),
            hintText: r'$company.logo  or  https://…',
            border: const OutlineInputBorder(),
            helperText: src.startsWith('data:')
                ? context.tr('uploaded_image_data_url')
                : null,
          ),
          onChanged: (v) => _write('source', v.trim()),
        ),
        const SectionDivider(labelKey: 'dimensions'),
        PxInput(
          labelKey: 'max_width',
          value: props['maxWidth'],
          hintText: '150',
          resettable: true,
          onChanged: (v) => _write('maxWidth', v),
        ),
        SizedBox(height: InSpacing.md(context)),
        PxInput(
          labelKey: 'max_height',
          value: props['maxHeight'],
          resettable: true,
          onChanged: (v) => _write('maxHeight', v),
        ),
        const SectionDivider(labelKey: 'layout'),
        AlignmentInput(
          labelKey: 'alignment',
          value: props['align'] as String?,
          onChanged: (v) => _write('align', v),
        ),
        SizedBox(height: InSpacing.md(context)),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: context.tr('object_fit'),
            border: const OutlineInputBorder(),
          ),
          initialValue: (props['objectFit'] as String?) ?? 'contain',
          // CSS object-fit value labels — React renders these literal
          // strings too; they're CSS keywords more than natural prose.
          items: const [
            DropdownMenuItem(value: 'contain', child: Text('Contain')), // i18n-exempt: CSS keyword
            DropdownMenuItem(value: 'cover', child: Text('Cover')), // i18n-exempt: CSS keyword
            DropdownMenuItem(value: 'fill', child: Text('Fill')), // i18n-exempt: CSS keyword
            DropdownMenuItem(value: 'scale-down', child: Text('Scale down')), // i18n-exempt: CSS keyword
            DropdownMenuItem(value: 'none', child: Text('None')), // i18n-exempt: CSS keyword
          ],
          onChanged: (v) {
            if (v != null) _write('objectFit', v);
          },
        ),
        const SectionDivider(labelKey: 'spacing'),
        PxInput(
          labelKey: 'padding',
          value: props['padding'],
          hintText: '0',
          resettable: true,
          onChanged: (v) => _write('padding', v),
        ),
      ],
    );
  }
}

class _ImageUploader extends StatelessWidget {
  const _ImageUploader({
    required this.hasImage,
    required this.src,
    required this.dropHover,
    required this.canDrop,
    required this.onPick,
    required this.onRemove,
    required this.onDropEnter,
    required this.onDropLeave,
    required this.onDrop,
  });

  final bool hasImage;
  final String src;
  final bool dropHover;
  final bool canDrop;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final VoidCallback onDropEnter;
  final VoidCallback onDropLeave;
  final void Function(DropDoneDetails) onDrop;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          Padding(
            padding: EdgeInsets.only(bottom: InSpacing.sm),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 128,
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    border: Border.all(color: tokens.border, width: 2),
                    borderRadius: BorderRadius.circular(InRadii.r2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(InRadii.r2),
                    child: Image.network(
                      src,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: tokens.ink3, size: 32),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Material(
                    color: tokens.overdue,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onRemove,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        canDrop
            ? DropTarget(
                onDragEntered: (_) => onDropEnter(),
                onDragExited: (_) => onDropLeave(),
                onDragDone: onDrop,
                child: _DashedDropArea(
                  hover: dropHover,
                  hasImage: hasImage,
                  onTap: onPick,
                ),
              )
            : _DashedDropArea(
                hover: false,
                hasImage: hasImage,
                onTap: onPick,
              ),
      ],
    );
  }
}

class _DashedDropArea extends StatelessWidget {
  const _DashedDropArea({
    required this.hover,
    required this.hasImage,
    required this.onTap,
  });

  final bool hover;
  final bool hasImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(InRadii.r2),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(InSpacing.lg(context)),
        decoration: BoxDecoration(
          color: hover ? tokens.accentSoft : tokens.bg,
          border: Border.all(
            color: hover ? tokens.accent : tokens.border,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(InRadii.r2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 32, color: tokens.ink3),
            SizedBox(height: InSpacing.sm),
            Text(
              context.tr(hasImage ? 'upload' : 'drag_and_drop_to_add'),
              style: TextStyle(fontSize: 13, color: tokens.ink),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
