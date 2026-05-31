import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/templates.dart';

/// Phase 8f: rich template gallery — mirrors React's `TemplateGallery.tsx`.
/// Categorized card grid + abstract preview shapes (no real invoice
/// rendering) + category filter chips. Two-column on desktop/tablet,
/// single-column on phone. Tap a card → resolves with the selected
/// [DesignTemplateStarter].
///
/// At 3 templates this is admittedly heavier than the prior `SimpleDialog`,
/// but it's also the user-facing surface React invests in and the model
/// scales when the starter list grows.
Future<DesignTemplateStarter?> showRichTemplateGallery(
  BuildContext context,
) {
  return showDialog<DesignTemplateStarter>(
    context: context,
    builder: (_) => const _TemplateGalleryDialog(),
  );
}

class _TemplateGalleryDialog extends StatefulWidget {
  const _TemplateGalleryDialog();

  @override
  State<_TemplateGalleryDialog> createState() => _TemplateGalleryDialogState();
}

class _TemplateGalleryDialogState extends State<_TemplateGalleryDialog> {
  static const _kAll = '__all__';
  String _filter = _kAll;
  late final List<DesignTemplateStarter> _starters = buildStarterTemplates();

  List<String> get _categories {
    final seen = <String>{_kAll};
    for (final s in _starters) {
      seen.add(s.category);
    }
    return seen.toList(growable: false);
  }

  List<DesignTemplateStarter> get _filtered {
    if (_filter == _kAll) return _starters;
    return _starters.where((s) => s.category == _filter).toList();
  }

  String _label(BuildContext context, String key) =>
      key == _kAll ? context.tr('all') : context.tr(key);

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 720 ? 2 : 1;
    return Dialog(
      insetPadding: EdgeInsets.all(InSpacing.lg(context)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('start_from_template'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: context.tr('close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: InSpacing.md(context)),
              Wrap(
                spacing: 6,
                children: [
                  for (final cat in _categories)
                    ChoiceChip(
                      label: Text(_label(context, cat)),
                      selected: _filter == cat,
                      onSelected: (_) => setState(() => _filter = cat),
                    ),
                ],
              ),
              SizedBox(height: InSpacing.md(context)),
              Flexible(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: InSpacing.md(context),
                    crossAxisSpacing: InSpacing.md(context),
                    childAspectRatio: 1.05,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final s = _filtered[i];
                    return _TemplateCard(
                      starter: s,
                      tokens: tokens,
                      onTap: () => Navigator.of(context).pop(s),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.starter,
    required this.tokens,
    required this.onTap,
  });

  final DesignTemplateStarter starter;
  final InTheme tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InRadii.r3),
        side: BorderSide(color: tokens.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: tokens.surfaceAlt,
                padding: EdgeInsets.all(InSpacing.md(context)),
                child: _TemplatePreviewShapes(starter: starter, tokens: tokens),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(InSpacing.md(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(starter.nameKey),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: InSpacing.xs),
                  Text(
                    context.tr(starter.descriptionKey),
                    style: TextStyle(fontSize: 12, color: tokens.ink3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abstract block-layout preview. Renders each block as a coloured
/// rectangle in its grid slot — gives the user a structural sense of
/// the template without rendering real invoice content (the real
/// preview is the full canvas after they pick).
class _TemplatePreviewShapes extends StatelessWidget {
  const _TemplatePreviewShapes({required this.starter, required this.tokens});

  final DesignTemplateStarter starter;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    if (starter.blocks.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(builder: (_, c) {
      // 12 columns × derived rows (the tallest block edge).
      var rows = 1;
      for (final b in starter.blocks) {
        final bottom = b.gridPosition.y + b.gridPosition.h;
        if (bottom > rows) rows = bottom;
      }
      final cellW = c.maxWidth / 12;
      final cellH = c.maxHeight / rows;
      return Stack(
        children: [
          for (final b in starter.blocks)
            Positioned(
              left: b.gridPosition.x * cellW,
              top: b.gridPosition.y * cellH,
              width: b.gridPosition.w * cellW,
              height: b.gridPosition.h * cellH,
              child: Padding(
                padding: const EdgeInsets.all(1.5),
                child: Container(
                  decoration: BoxDecoration(
                    color: _shapeColorFor(b.type),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  /// Distinct tints per block "kind" so the abstract preview reads as
  /// structure (header / data / footer) without overwhelming colour.
  Color _shapeColorFor(String type) {
    switch (type) {
      case 'logo':
      case 'image':
        return tokens.accent.withValues(alpha: 0.55);
      case 'invoice-details':
      case 'client-info':
      case 'client-shipping-info':
      case 'company-info':
        return tokens.ink.withValues(alpha: 0.32);
      case 'table':
      case 'tasks-table':
        return tokens.ink.withValues(alpha: 0.22);
      case 'total':
        return tokens.accent.withValues(alpha: 0.40);
      case 'public-notes':
      case 'terms':
      case 'footer':
        return tokens.ink.withValues(alpha: 0.14);
      case 'signature':
      case 'divider':
      case 'spacer':
      case 'qrcode':
      default:
        return tokens.ink.withValues(alpha: 0.18);
    }
  }
}
