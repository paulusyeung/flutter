import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/native_window.dart';
import 'package:admin/app/screenshot_window_controller.dart';

/// Height reserved for the macOS caption strip — the standard macOS titlebar
/// height. A native OS metric, not an [InSpacing] design token. Private because
/// only the macOS branch reserves space; Windows/Linux place their controls
/// top-right (see below), so they don't reserve a sidebar strip.
const double _kMacCaptionHeight = 28.0;

/// Window-caption region at the top of the sidebar: it reserves space for any
/// window controls that live there and provides a drag handle now that the
/// native title bar is hidden.
///
/// - **macOS**: a 28-px draggable strip; the real traffic-light buttons float
///   over it (top-left, native — so this strip only catches drags in the empty
///   space around them, and the buttons keep their own clicks + inactive-graying).
///   When the Debug Panel hides the traffic lights for a clean screenshot
///   ([ScreenshotWindowController.windowButtonsHidden]) the strip collapses to
///   zero height: there's nothing left to reserve space for, so the sidebar /
///   content rises to meet the window's top edge.
/// - **Windows/Linux**: their controls are *drawn* top-right (a future
///   `WindowControls` widget over the content top — see
///   `docs/desktop-window-state.md` § Desktop hidden title bar), so the sidebar
///   stays flush and this renders nothing for now. Once those frameless runners
///   are added it becomes the window drag handle on the left.
/// - **web / mobile**: nothing.
class WindowCaptionStrip extends StatelessWidget {
  const WindowCaptionStrip({super.key, required this.controller});

  /// Screenshot/window controller, watched so the strip collapses the instant
  /// the Debug Panel hides the native window buttons.
  final ScreenshotWindowController controller;

  @override
  Widget build(BuildContext context) {
    // Only macOS hides its title bar today (fullSizeContentView). Windows/Linux
    // keep their normal title bar until their runners + frameless mode land, at
    // which point a branch is added here.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // Buttons hidden (screenshot mode): no traffic lights to clear and no
        // title bar to drag, so collapse and let the sidebar move up to the
        // window's top edge.
        if (controller.windowButtonsHidden) return const SizedBox.shrink();
        return GestureDetector(
          // Opaque so the otherwise-empty strip is hit-testable for the pan.
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => NativeWindow.instance.startDrag(),
          onDoubleTap: () => NativeWindow.instance.handleDoubleClick(),
          child: SizedBox(
            height: _kMacCaptionHeight,
            width: double.infinity,
            // Defined background so the strip never reveals a gap in the narrow
            // layout (where it sits above the per-screen Scaffold). In the
            // sidebar it matches the surrounding surface-colored rail.
            child: ColoredBox(color: context.inTheme.surface),
          ),
        );
      },
    );
  }
}
