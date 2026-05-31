import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/_shared.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/sample/sample_data.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/variables/variable_replacer.dart';

/// Renders `logo` and `image` blocks. Both use the same shape: an
/// optionally-aligned image with `maxWidth` clamped by a `ConstrainedBox`
/// and `objectFit` mapped to Flutter's `BoxFit`.
///
/// `logo` defaults `source` to `$company.logo`; `image` uses an empty
/// string and shows a placeholder when no image URL is set. Variable
/// substitution turns the token into the real URL (sample data carries
/// `'/logo180.png'` — a relative path that won't actually load in tests,
/// so the renderer shows the placeholder icon for those).
class ImageBlock extends StatelessWidget {
  const ImageBlock({super.key, required this.block, required this.sample});

  final DesignBlock block;
  final DesignerSampleData sample;

  @override
  Widget build(BuildContext context) {
    final props = block.properties;
    final rawSource = (props['source'] as String?)?.trim() ?? '';
    final resolvedSource = replaceVariables(rawSource, data: sample);
    final maxWidth = parsePx(props['maxWidth']);
    final fit = parseObjectFit(props['objectFit'] as String?);
    final alignment = parseAlignment(props['align'] as String?);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: _imageOrPlaceholder(context, resolvedSource, fit),
      ),
    );
  }

  Widget _imageOrPlaceholder(BuildContext context, String src, BoxFit fit) {
    if (src.isEmpty || !_looksLikeAbsoluteUrl(src)) {
      return _Placeholder(label: src);
    }
    return Image.network(
      src,
      fit: fit,
      errorBuilder: (_, _, _) => _Placeholder(label: src),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : const _PlaceholderSpinner(),
    );
  }

  bool _looksLikeAbsoluteUrl(String src) =>
      src.startsWith('http://') ||
      src.startsWith('https://') ||
      src.startsWith('data:');
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, color: tokens.ink3, size: 32),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: tokens.ink3),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceholderSpinner extends StatelessWidget {
  const _PlaceholderSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
