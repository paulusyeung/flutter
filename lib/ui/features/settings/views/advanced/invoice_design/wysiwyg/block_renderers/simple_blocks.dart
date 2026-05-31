import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/_shared.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/sample/sample_data.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/variables/variable_replacer.dart';

/// Renders `divider`. Thin horizontal line; `thickness` + `color` +
/// `style` (`solid` / `dashed` — dashed not honored by Flutter's basic
/// `Container`; we approximate as solid).
class DividerBlock extends StatelessWidget {
  const DividerBlock({super.key, required this.block});
  final DesignBlock block;

  @override
  Widget build(BuildContext context) {
    final props = block.properties;
    final thickness = parsePx(props['thickness']) ?? 1.0;
    final color = parseCssColor(
      props['color'] as String?,
      fallback: const Color(0xFFE5E7EB),
    );
    final marginTop = parsePx(props['marginTop']) ?? 0;
    final marginBottom = parsePx(props['marginBottom']) ?? 0;
    return Padding(
      padding: EdgeInsets.only(top: marginTop, bottom: marginBottom),
      child: Container(height: thickness, color: color),
    );
  }
}

/// Renders `spacer`. Just a `SizedBox` with the configured height. The
/// canvas already gives the block its grid-cell footprint; the height
/// here is mostly visual reference inside the cell.
class SpacerBlock extends StatelessWidget {
  const SpacerBlock({super.key, required this.block});
  final DesignBlock block;

  @override
  Widget build(BuildContext context) {
    final height = parsePx(block.properties['height']) ?? 40.0;
    return SizedBox(height: height, width: double.infinity);
  }
}

/// Renders `qrcode`. Phase 5a wires the real `qr_flutter` `QrImageView`.
/// The block's `data` property carries either a template token (e.g.
/// `$payment_qrcode`) — which the variable replacer turns into a stable
/// placeholder string — or a literal URL / arbitrary text the user typed.
/// Empty data falls back to the placeholder icon so an unconfigured block
/// is recognizable on the canvas.
class QrcodeBlockPreview extends StatelessWidget {
  const QrcodeBlockPreview({super.key, required this.block, this.sample});
  final DesignBlock block;
  final DesignerSampleData? sample;

  @override
  Widget build(BuildContext context) {
    final alignment = parseAlignment(block.properties['align'] as String?);
    final size = parsePx(block.properties['size']) ?? 100.0;
    final raw = (block.properties['data'] as String?)?.trim() ?? '';
    final resolved = sample == null
        ? raw
        : replaceVariables(raw, data: sample);
    final hasData = resolved.isNotEmpty && resolved != raw
        ? true
        : (raw.isNotEmpty && !raw.startsWith(r'$'));

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hasData ? Colors.white : context.inTheme.surfaceAlt,
          border: Border.all(color: context.inTheme.border, width: 0.5),
        ),
        child: hasData
            ? QrImageView(
                data: resolved.isEmpty ? raw : resolved,
                size: size,
                padding: const EdgeInsets.all(4),
                backgroundColor: Colors.white,
              )
            : Icon(
                Icons.qr_code,
                color: context.inTheme.ink3,
                size: size * 0.6,
              ),
      ),
    );
  }
}

/// Renders `signature`. Label text (variable-substituted) above a thin
/// horizontal line. Optionally shows a date placeholder below per React's
/// `showDate` flag (kept as plain text — no real date logic).
class SignatureBlock extends StatelessWidget {
  const SignatureBlock({super.key, required this.block, required this.sample});
  final DesignBlock block;
  final DesignerSampleData sample;

  @override
  Widget build(BuildContext context) {
    final props = block.properties;
    final label = replaceVariables(
      (props['label'] as String?) ?? '',
      data: sample,
    );
    final showLine = props['showLine'] as bool? ?? true;
    final showDate = props['showDate'] as bool? ?? false;
    final align = parseAlignment(props['align'] as String?);
    final color = parseCssColor(
      props['color'] as String?,
      fallback: const Color(0xFF6B7280),
    );
    final fontSize = parsePx(props['fontSize']) ?? 12;

    return Align(
      alignment: align,
      child: Column(
        crossAxisAlignment: align == Alignment.center
            ? CrossAxisAlignment.center
            : align == Alignment.centerRight
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLine)
            Container(
              height: 1,
              width: 200,
              color: color,
              margin: const EdgeInsets.only(bottom: 4),
            ),
          if (label.isNotEmpty)
            Text(label, style: TextStyle(fontSize: fontSize, color: color)),
          if (showDate)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                replaceVariables(r'$date', data: sample),
                style: TextStyle(fontSize: fontSize - 2, color: color),
              ),
            ),
        ],
      ),
    );
  }
}
