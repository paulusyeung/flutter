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
}
