import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Drives native macOS window actions that no longer have a title bar to back
/// them once it's hidden (`fullSizeContentView`): moving the window and the
/// double-click title-bar action. Triggered from the draggable strip at the
/// top of the sidebar (`MacTitleBarDragStrip`).
///
/// Mirrors the [NativeWindowTheme] bridge shape. macOS-only — every method is a
/// no-op on web and every other platform.
class NativeWindow {
  NativeWindow._();

  static final NativeWindow instance = NativeWindow._();

  static const MethodChannel _channel = MethodChannel(
    'invoice_ninja/native_window',
  );

  /// Begin a native window drag (AppKit `performDrag`). Call from a pan start
  /// while the mouse is still down so the current event is a drag event.
  Future<void> startDrag() => _invoke('startDrag');

  /// Run the user's configured double-click title-bar action (zoom by default;
  /// honors System Settings' Minimize / None).
  Future<void> handleDoubleClick() => _invoke('doubleClick');

  bool get _isMac => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> _invoke(String method) async {
    if (!_isMac) return;
    try {
      await _channel.invokeMethod<void>(method);
    } catch (e) {
      // Missing handler (e.g. running against older native code) is non-fatal —
      // the window just isn't draggable from the strip until the next launch
      // picks up the new Swift side.
      debugPrint('NativeWindow.$method failed: $e');
    }
  }
}
