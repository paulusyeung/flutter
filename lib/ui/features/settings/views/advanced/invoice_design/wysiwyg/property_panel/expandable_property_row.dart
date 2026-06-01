import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// Phase 15b: shared chrome for the per-row property editors used by
/// the Info / Total / Table block-property panels.
///
/// Three editors (`info_block_properties.dart`,
/// `total_block_properties.dart`, `table_block_properties.dart`) all
/// build a reorderable list of rows that follow the same shape:
///
/// ```
/// [drag handle] [title + subtitle column]  [expand chevron] [trailing]
/// (when expanded → editor-specific [expandedChild] indented underneath)
/// ```
///
/// Differences across the three call sites are minor:
///   * Info + Table → [trailing] is `IconButton(delete_outline)`.
///   * Total → [trailing] is `Switch.adaptive` (items are hideable, not
///     deletable).
///
/// This widget owns the surrounding `Padding` + `Column` + the
/// drag-handle / chevron buttons; callers provide the rich [title] /
/// [subtitle] widgets and the [expandedChild] body.
class ExpandablePropertyRow extends StatelessWidget {
  const ExpandablePropertyRow({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggleExpanded,
    required this.trailing,
    required this.expandedChild,
  });

  /// Position in the surrounding `ReorderableListView` — used to wire
  /// the [ReorderableDragStartListener] for the drag handle.
  final int index;

  /// Primary label (typically a `Text` styled `textTheme.bodyMedium`).
  final Widget title;

  /// Secondary label below [title] — typically a monospace `Text` with
  /// the field path / variable hint, but Total uses a `Row` so the
  /// flag icons can sit inline.
  final Widget subtitle;

  /// `true` → [expandedChild] is mounted below the row. `false` → row
  /// stands alone.
  final bool expanded;

  /// Fired when the user taps the expand/collapse chevron.
  final VoidCallback onToggleExpanded;

  /// Right-most widget — delete `IconButton` on Info/Table, `Switch.
  /// adaptive` on Total. Lives outside the chevron so callers control
  /// the affordance.
  final Widget trailing;

  /// Inline editor body that renders below the row when [expanded] is
  /// true. Each caller picks its own (`_ExpandedFieldEditor`,
  /// `_ExpandedTotalEditor`, `_ExpandedColumnEditor`).
  final Widget expandedChild;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_indicator, color: tokens.ink3, size: 20),
              ),
              SizedBox(width: InSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, subtitle],
                ),
              ),
              IconButton(
                tooltip: context.tr(expanded ? 'collapse' : 'expand'),
                icon: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                onPressed: onToggleExpanded,
              ),
              trailing,
            ],
          ),
          if (expanded) expandedChild,
        ],
      ),
    );
  }
}
