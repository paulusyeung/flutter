import 'package:admin/data/models/domain/design.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';

/// Phase 4c: hand-crafted starter templates for the WYSIWYG designer.
/// Three layouts cover the common shapes the React app ships in its 458-line
/// `templates.ts`. Mirrors React's category strings (`modern` / `minimal` /
/// `classic`) so the gallery can group / sort them later. Each `blocks`
/// list is the freshly-instantiated `DesignBlock` set the canvas drops
/// onto when the user picks the template.
///
/// Templates are pure data — no DB / network. New templates land here as
/// additional const records.
///
/// **Per-block styling note (Phase 8 Tier 2 decision, 2026-05-31).**
/// React's templates carry per-block property overrides (specific colors,
/// fonts, column widths, header/row borders). These starters use each
/// block's library defaults instead — the structural layout matches
/// React, the per-block styling is bare. Rationale: users almost always
/// re-style after picking a template; carrying React's choices into
/// Flutter would have the user's first action be "undo what the starter
/// did." Revisit if a user reports the starters feel undifferentiated.

class DesignTemplateStarter {
  const DesignTemplateStarter({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.category,
    required this.blocks,
  });

  final String id;
  final String nameKey;
  final String descriptionKey;

  /// Category for the gallery filter chips. Mirrors React's
  /// `modern` / `classic` / `minimal` / `creative` values.
  final String category;
  final List<DesignBlock> blocks;
}

/// Make a `DesignBlock` from a [BlockSpec] at a given grid position.
/// Centralized so templates stay terse and pick up the spec's default
/// properties (table columns, info field configs, totals items, etc.).
DesignBlock _b(String type, int x, int y, {int? w, int? h}) {
  final spec = blockSpecFor(type);
  if (spec == null) {
    throw ArgumentError('Unknown block type "$type" in starter template');
  }
  return spec
      .newInstance(idPrefix: spec.type, x: x, y: y)
      .copyWith(
        gridPosition: GridPosition(
          x: x,
          y: y,
          w: w ?? spec.defaultWidth,
          h: h ?? spec.defaultHeight,
        ),
      );
}

/// Get the three Phase-4 starters fresh — re-evaluated per call so each
/// pick produces blocks with brand-new ids.
List<DesignTemplateStarter> buildStarterTemplates() => [
  DesignTemplateStarter(
    id: 'standard',
    nameKey: 'starter_standard',
    descriptionKey: 'starter_standard_hint',
    category: 'classic',
    blocks: _standardLayout(),
  ),
  DesignTemplateStarter(
    id: 'minimal',
    nameKey: 'starter_minimal',
    descriptionKey: 'starter_minimal_hint',
    category: 'minimal',
    blocks: _minimalLayout(),
  ),
  DesignTemplateStarter(
    id: 'quote_friendly',
    nameKey: 'starter_quote_friendly',
    descriptionKey: 'starter_quote_friendly_hint',
    category: 'modern',
    blocks: _quoteFriendlyLayout(),
  ),
];

/// Classic two-column header: logo + invoice details up top, client info
/// + ship-to side by side, products table, then totals on the right.
List<DesignBlock> _standardLayout() => [
  _b('logo', 0, 0, w: 4, h: 4),
  _b('invoice-details', 6, 0, w: 6, h: 4),
  _b('client-info', 0, 4, w: 6, h: 4),
  _b('client-shipping-info', 6, 4, w: 6, h: 4),
  _b('table', 0, 8, w: 12, h: 8),
  _b('total', 6, 16, w: 6, h: 6),
  _b('public-notes', 0, 22, w: 12, h: 3),
  _b('footer', 0, 25, w: 12, h: 2),
];

/// Minimal layout — single-column flow without the shipping block.
List<DesignBlock> _minimalLayout() => [
  _b('logo', 0, 0, w: 3, h: 3),
  _b('invoice-details', 8, 0, w: 4, h: 3),
  _b('client-info', 0, 3, w: 12, h: 4),
  _b('table', 0, 7, w: 12, h: 8),
  _b('total', 6, 15, w: 6, h: 6),
  _b('footer', 0, 21, w: 12, h: 2),
];

/// Quote-friendly — emphasizes terms + public notes alongside the totals.
List<DesignBlock> _quoteFriendlyLayout() => [
  _b('logo', 0, 0, w: 4, h: 3),
  _b('company-info', 8, 0, w: 4, h: 3),
  _b('client-info', 0, 3, w: 6, h: 4),
  _b('invoice-details', 6, 3, w: 6, h: 4),
  _b('table', 0, 7, w: 12, h: 8),
  _b('public-notes', 0, 15, w: 6, h: 4),
  _b('total', 6, 15, w: 6, h: 4),
  _b('terms', 0, 19, w: 12, h: 3),
  _b('signature', 0, 22, w: 4, h: 3),
  _b('footer', 0, 25, w: 12, h: 2),
];
