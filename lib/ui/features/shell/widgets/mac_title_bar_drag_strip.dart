import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/native_window.dart';

/// Reserved height at the very top of the sidebar (and the narrow-layout
/// column) for the macOS traffic-light buttons, which float over the content
/// once the native title bar is hidden. Matches the standard macOS titlebar
/// height — a native OS metric, not an [InSpacing] design token.
const double kMacTitleBarHeight = 28.0;

/// A transparent strip that stands in for the removed macOS title bar: it
/// reserves space for the floating traffic-light buttons and lets the user
/// drag the window (and double-click to zoom). The native buttons render in a
/// layer above the FlutterView, so they keep receiving their own clicks — this
/// strip only catches drags in the empty space around them.
///
/// Renders nothing (`SizedBox.shrink`) on web and every non-macOS platform.
class MacTitleBarDragStrip extends StatelessWidget {
  const MacTitleBarDragStrip({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      // Opaque so the otherwise-empty strip is hit-testable for the pan.
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => NativeWindow.instance.startDrag(),
      onDoubleTap: () => NativeWindow.instance.handleDoubleClick(),
      child: SizedBox(
        height: kMacTitleBarHeight,
        width: double.infinity,
        // Defined background so the strip never reveals a gap in the narrow
        // layout (where it sits above the per-screen Scaffold). In the sidebar
        // it matches the surrounding surface-colored rail.
        child: ColoredBox(color: context.inTheme.surface),
      ),
    );
  }
}
