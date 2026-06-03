import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:admin/app/env.dart';

/// Drives native desktop window actions that no longer have a title bar to back
/// them once it's hidden: moving the window, the double-click title-bar action,
/// and (on platforms where the app draws its own window buttons) minimize /
/// maximize / close. Triggered from the window-caption chrome at the top of the
/// shell (`WindowCaptionStrip`, plus the drawn controls on Windows/Linux).
///
/// Mirrors the `NativeWindowTheme` bridge shape. Desktop-only — every method is
/// a no-op on web and mobile. Each desktop runner answers the shared
/// `invoice_ninja/native_window` channel; see `docs/desktop-window-state.md`
/// § Desktop hidden title bar for which methods each platform implements (macOS
/// is wired today; Windows/Linux when those runners are added).
class NativeWindow {
  NativeWindow._();

  static final NativeWindow instance = NativeWindow._();

  static const MethodChannel _channel = MethodChannel(
    'invoice_ninja/native_window',
  );

  /// Begin a native window drag. Call from a pan start while the mouse is still
  /// down so the current event is a drag event (macOS `performDrag`; Win/Linux
  /// `WM_NCLBUTTONDOWN` / `gtk_window_begin_move_drag`).
  Future<void> startDrag() => _invoke('startDrag');

  /// Run the platform's title-bar double-click action (macOS honors System
  /// Settings; Win/Linux toggle maximize).
  Future<void> handleDoubleClick() => _invoke('doubleClick');

  /// Minimize the window. Used by the drawn window buttons on Windows/Linux;
  /// unused on macOS (its native traffic lights handle this).
  Future<void> minimize() => _invoke('minimize');

  /// Toggle maximize / restore. Drawn-button target on Windows/Linux.
  Future<void> toggleMaximize() => _invoke('toggleMaximize');

  /// Close the window. Drawn-button target on Windows/Linux.
  Future<void> close() => _invoke('close');

  Future<void> _invoke(String method) async {
    if (!Env.isDesktop) return;
    try {
      await _channel.invokeMethod<void>(method);
    } catch (e) {
      // Missing handler (a method this platform's runner doesn't implement, or
      // older native code) is non-fatal — that control just does nothing until
      // the native side catches up.
      debugPrint('NativeWindow.$method failed: $e');
    }
  }
}
