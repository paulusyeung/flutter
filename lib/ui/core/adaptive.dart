import 'package:flutter/widgets.dart';

/// App-wide responsive breakpoints. Use [Breakpoints.isWide] inside a
/// [LayoutBuilder] so layout decisions reflect the parent's allocated width,
/// not the device or window size.
class Breakpoints {
  Breakpoints._();

  /// At or above this width we show two-pane layouts and a `NavigationRail`.
  /// Below it we collapse to single-pane and a `NavigationBar`.
  static const double wide = 600;

  static bool isWide(BoxConstraints constraints) =>
      constraints.maxWidth >= wide;

  /// True when the global persistent `InSidebar` is visible (i.e. the
  /// window is ≥ [wide]). Use this — not [isWide] — to decide whether a
  /// per-screen Scaffold should attach its own `AppDrawer` +
  /// `DrawerHamburger`. The local `LayoutBuilder` constraints can fall
  /// below [wide] even when the global sidebar is visible (e.g. medium
  /// window widths after the InSidebar + SettingsListSidebar take their
  /// share), which would otherwise produce a redundant hamburger menu
  /// that opens a duplicate of the global nav.
  static bool isGlobalNavVisible(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  /// At or above this **window** width the entity routes render as a
  /// slide-over panel: the list stays at full width and the detail /
  /// edit / create floats on top, pinned to the right edge with a
  /// drop shadow. Below this threshold the routes render full-screen
  /// exactly as they do today (no slide-over).
  ///
  /// Picked at 1024 so the **full-width** list keeps wide-mode column
  /// rendering (`Breakpoints.isWide = 600` on the list itself, not on
  /// a post-sidebar slice) at common laptop widths (1280, 1366, 1440).
  /// Below 1024, the slide-over would crowd the list — full-page nav
  /// is the better experience there.
  static const double slideOver = 1024;

  /// True when the current window is wide enough to host the slide-over
  /// pane (see [slideOver]).
  static bool isSlideOver(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= slideOver;

  /// Width thresholds for the Reports screen's three-tier responsive
  /// rendering. The Reports table carries more chrome (sticky header,
  /// per-column filter row, drill-down breadcrumb) than a typical entity
  /// list, so it needs its own breakpoints — and below 600 px it switches
  /// to a card-list layout entirely.
  static const double reportTableMedium = 600;
  static const double reportTableWide = 1024;

  /// Reports body tier for the current viewport, given the body's
  /// available width [maxWidth] (typically `constraints.maxWidth` inside
  /// a [LayoutBuilder]).
  ///
  /// - `wide` (≥1024): full table with every column.
  /// - `medium` (600–1024): pinned-first-column table with horizontal
  ///   scroll for the rest.
  /// - `narrow` (<600): switch to a [ReportCardRow] list; filter row is
  ///   only reachable through the toolbar overflow.
  static ReportLayoutTier reportTier(double maxWidth) {
    if (maxWidth >= reportTableWide) return ReportLayoutTier.wide;
    if (maxWidth >= reportTableMedium) return ReportLayoutTier.medium;
    return ReportLayoutTier.narrow;
  }
}

enum ReportLayoutTier { narrow, medium, wide }
