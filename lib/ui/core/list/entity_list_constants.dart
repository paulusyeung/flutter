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

/// Width of the leading row-actions slot. In the wide data table this holds
/// the circled edit pencil + an 8 px gap + the `…` overflow menu. Sized to
/// exactly fit that cluster (36 edit + 8 gap + 36 menu = 80) so there's no
/// dead space to the right of the menu, while the column-header strip and
/// `computeTableMinWidth()` stay aligned (all read this same constant).
const double kColWMoreMenu = 80;

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

/// Gap between the leading row-actions slot ([kColWMoreMenu]) and the
/// avatar / select-checkbox slot. Intentionally tighter than the 12 px
/// inter-column [kColCellGap] so the action cluster sits flush against the
/// checkbox. Used by the header strip and every wide row tile at exactly
/// that one position so they stay column-aligned. (The actions slot already
/// hugs its cluster — [kColWMoreMenu] = edit + 8 + menu — so 0 here puts the
/// checkbox directly after the menu with no dead space.)
const double kColActionsLeadingGap = 0;

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
  var total = kColWMoreMenu + kColActionsLeadingGap; // actions + tight gap
  total += kColLeadingWidth + kColCellGap; // avatar/checkbox + gap
  for (final c in columns) {
    total += c.isFlex ? kColumnFlexMinWidth : c.width!;
    total += kColCellGap;
  }
  total += kColWPillSlot;
  // Mirror the row's horizontal padding (`EdgeInsetsDirectional.fromSTEB(16, _, 16, _)`).
  return total + 32;
}
