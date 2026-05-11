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
}
