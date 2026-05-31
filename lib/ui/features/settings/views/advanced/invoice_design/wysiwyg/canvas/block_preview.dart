import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/image_blocks.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/info_blocks.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/simple_blocks.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/table_blocks.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/text_blocks.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/total_block.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/sample/sample_data.dart';

/// Canvas-level block preview. Thin chrome (header strip + lock badge) +
/// a type-specific renderer dispatched by [_renderBlockBody]. Each
/// renderer lives under `block_renderers/` and takes
/// `(DesignBlock, DesignerSampleData)`.
///
/// Falls back to a labelled placeholder for unknown types so a future
/// server-side block type doesn't crash the canvas — render the type
/// string in italic so it's obvious in dev.
class BlockPreview extends StatelessWidget {
  const BlockPreview({super.key, required this.block, required this.sample});

  final DesignBlock block;
  final DesignerSampleData sample;

  @override
  Widget build(BuildContext context) {
    final spec = blockSpecFor(block.type);
    final tokens = context.inTheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: tokens.border, width: 0.5),
        borderRadius: BorderRadius.circular(InRadii.r1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(spec: spec, block: block),
          const SizedBox(height: 4),
          Expanded(child: _renderBlockBody(block, sample)),
        ],
      ),
    );
  }
}

/// Registry dispatch: maps `block.type` to the matching renderer widget.
/// New block types add a `case` clause here AND a renderer file under
/// `block_renderers/`. Unknown types fall through to a debug placeholder.
Widget _renderBlockBody(DesignBlock block, DesignerSampleData sample) {
  switch (block.type) {
    case 'logo':
    case 'image':
      return ImageBlock(block: block, sample: sample);
    case 'text':
      return FormattedTextBlock(block: block, sample: sample);
    case 'public-notes':
      return FormattedTextBlock(
        block: block,
        sample: sample,
        defaultContent: r'$public_notes',
      );
    case 'terms':
      return FormattedTextBlock(
        block: block,
        sample: sample,
        defaultContent: r'$terms',
      );
    case 'footer':
      return FormattedTextBlock(
        block: block,
        sample: sample,
        defaultContent: r'$footer',
      );
    case 'company-info':
    case 'client-info':
    case 'client-shipping-info':
      return InfoBlock(block: block, sample: sample);
    case 'invoice-details':
      return InvoiceDetailsBlock(block: block, sample: sample);
    case 'table':
    case 'tasks-table':
      return TableBlock(block: block, sample: sample);
    case 'total':
      return TotalBlock(block: block, sample: sample);
    case 'divider':
      return DividerBlock(block: block);
    case 'spacer':
      return SpacerBlock(block: block);
    case 'qrcode':
      return QrcodeBlockPreview(block: block, sample: sample);
    case 'signature':
      return SignatureBlock(block: block, sample: sample);
    default:
      return _UnknownPlaceholder(type: block.type);
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.spec, required this.block});
  final BlockSpec? spec;
  final DesignBlock block;
  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // A 1-column block (e.g. a w=1 spacer) is narrower than the leading
        // type icon + gap (16px), which RenderFlex-overflowed this header
        // Row. Drop the icon when there isn't room so the label ellipsizes
        // instead of overflowing.
        final showIcon = constraints.maxWidth >= 28;
        return Row(
          children: [
            if (showIcon) ...[
              Icon(
                spec?.icon ?? Icons.crop_square,
                size: 12,
                color: tokens.ink3,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                spec != null ? context.tr(spec!.labelKey) : block.type,
                style: TextStyle(
                  fontSize: 10,
                  color: tokens.ink3,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (block.locked) Icon(Icons.lock, size: 10, color: tokens.ink3),
          ],
        );
      },
    );
  }
}

class _UnknownPlaceholder extends StatelessWidget {
  const _UnknownPlaceholder({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      type,
      style: TextStyle(
        fontSize: 12,
        color: context.inTheme.ink3,
        fontStyle: FontStyle.italic,
      ),
    ),
  );
}
