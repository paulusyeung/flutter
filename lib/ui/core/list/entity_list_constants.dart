/// Shared column-width constants for entity list data tables.
///
/// The screen-level column header strip ([EntityListColumnHeaders]) and the
/// per-entity row tiles (`ClientListTile`, `ProductListTile`, …) read these
/// so headers and rows stay column-aligned. Don't drift them apart.
library;

import 'package:admin/domain/columns/column_definition.dart';

/// Reserved width for the trailing pill (status badge) slot on the
/// header. Row tiles that don't render a pill should still reserve this
/// width so the header columns line up with the row cells.
const double kColWPillSlot = 96;

/// Width of the leading row-actions slot (the `…` overflow menu).
const double kColWMoreMenu = 48;

/// Width of the avatar / select-all checkbox slot.
const double kColLeadingWidth = 32;

/// Stable minimum height for every entity-list row.
///
/// Applied as a `minHeight` floor by the list scaffold so a row never
/// changes height when its leading slot swaps between avatar and selection
/// checkbox — toggling a row's checkbox must not reflow the list. Slightly
/// taller than the previous content-driven ~64 px so short rows breathe and
/// tall rows (2-line identity + money column) are never clipped. Also used
/// for the master-detail auto-scroll estimate.
const double kEntityListRowHeight = 72;

/// Horizontal gap between cells in the table grid.
const double kColCellGap = 12;

/// Minimum width for a flex column when the table sums its min widths to
/// decide whether to engage the horizontal scroller. Today only one column
/// per entity flexes (typically the identity / name column).
const double kColumnFlexMinWidth = 220;

/// Total minimum width the wide-mode data-table needs to lay out without
/// overflowing. Add up the slot widths used by every row tile and column
/// header so the scaffold can decide when to engage the horizontal
/// scroller. Mirrors the (previously duplicated) `_computeTableMinWidth`
/// helper that lived in each list screen.
double computeTableMinWidth(List<ColumnDefinition<dynamic>> columns) {
  var total = kColWMoreMenu + kColCellGap; // leading `…` actions + gap
  total += kColLeadingWidth + kColCellGap; // avatar/checkbox + gap
  for (final c in columns) {
    total += c.isFlex ? kColumnFlexMinWidth : c.width!;
    total += kColCellGap;
  }
  total += kColWPillSlot;
  // Mirror the row's horizontal padding (`EdgeInsetsDirectional.fromSTEB(16, _, 16, _)`).
  return total + 32;
}
