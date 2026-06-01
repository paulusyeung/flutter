import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/canvas/wysiwyg_canvas.dart'
    show CanvasDropPayload, PalettePayload;
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

/// Left pane of the WYSIWYG designer. Lists the 17 block types grouped by
/// [BlockCategory]. Each tile is both a [Draggable] (mouse drag onto the
/// canvas, desktop-friendly) AND a tap-to-add (one-tap on mobile/tablet,
/// drops the block in the next free row).
///
/// Drag payload is the [BlockSpec] itself — the canvas turns it into a
/// concrete [DesignBlock] at drop time so palette tiles stay reusable.
class ComponentPalette extends StatelessWidget {
  const ComponentPalette({super.key, required this.vm});

  final WysiwygDesignViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final groups = <BlockCategory, List<BlockSpec>>{};
    for (final s in kBlockLibrary) {
      groups.putIfAbsent(s.category, () => <BlockSpec>[]).add(s);
    }

    return Container(
      width: 240,
      color: tokens.surface,
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: InSpacing.md(context)),
        children: [
          _Header(label: context.tr('components')),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: InSpacing.lg(context),
              vertical: InSpacing.sm,
            ),
            child: Text(
              context.tr('drag_and_drop_to_add'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.ink3),
            ),
          ),
          for (final category in BlockCategory.values)
            ..._categorySection(
              context,
              category,
              groups[category] ?? const [],
            ),
        ],
      ),
    );
  }

  List<Widget> _categorySection(
    BuildContext context,
    BlockCategory category,
    List<BlockSpec> specs,
  ) {
    if (specs.isEmpty) return const [];
    return [
      Padding(
        padding: EdgeInsets.fromLTRB(
          InSpacing.lg(context),
          InSpacing.md(context),
          InSpacing.lg(context),
          InSpacing.sm,
        ),
        child: Text(
          context.tr(_labelKeyFor(category)),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.inTheme.ink3,
            letterSpacing: 1.0,
          ),
        ),
      ),
      for (final spec in specs) _PaletteTile(spec: spec, vm: vm),
    ];
  }

  String _labelKeyFor(BlockCategory c) => switch (c) {
    BlockCategory.branding => 'branding',
    BlockCategory.content => 'content',
    BlockCategory.data => 'data',
    BlockCategory.layout => 'layout',
  };
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({required this.spec, required this.vm});

  final BlockSpec spec;
  final WysiwygDesignViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final tile = ListTile(
      dense: true,
      leading: Icon(spec.icon, size: 20, color: tokens.ink),
      title: Text(context.tr(spec.labelKey)),
      trailing: Icon(Icons.drag_indicator, size: 16, color: tokens.ink3),
      onTap: () => vm.addBlock(spec),
    );
    return Draggable<CanvasDropPayload>(
      data: PalettePayload(spec),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(InRadii.r2),
        child: Container(
          width: 200,
          padding: EdgeInsets.all(InSpacing.md(context)),
          decoration: BoxDecoration(
            color: tokens.accentSoft,
            borderRadius: BorderRadius.circular(InRadii.r2),
          ),
          child: Row(
            children: [
              Icon(spec.icon, size: 18),
              SizedBox(width: InSpacing.sm),
              Expanded(child: Text(context.tr(spec.labelKey))),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: tile,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      InSpacing.lg(context),
      InSpacing.md(context),
      InSpacing.lg(context),
      0,
    ),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}
