import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pushes the active Flutter theme's outermost color and ink into the native
/// macOS window chrome (titlebar background, traffic-light glyph color via
/// `NSAppearance`, and the centered title NSTextField). Swift owns the
/// `UserDefaults` mirror that prevents a cold-start flash on relaunch — every
/// `apply` from here writes those keys on the native side.
///
/// macOS-only. On every other platform every method is a no-op.
class NativeWindowTheme {
  NativeWindowTheme._();

  static final NativeWindowTheme instance = NativeWindowTheme._();

  static const MethodChannel _channel = MethodChannel(
    'invoice_ninja/native_window_theme',
  );

  Color? _lastBg;
  Color? _lastTitle;
  Brightness? _lastBrightness;

  Future<void> apply({
    required Color background,
    required Color title,
    required Brightness brightness,
  }) async {
    if (!_isMac) return;
    if (background == _lastBg &&
        title == _lastTitle &&
        brightness == _lastBrightness) {
      return;
    }
    _lastBg = background;
    _lastTitle = title;
    _lastBrightness = brightness;

    try {
      await _channel.invokeMethod<void>('apply', <String, Object>{
        'bgHex': _hex(background),
        'titleHex': _hex(title),
        'brightness': brightness == Brightness.dark ? 'dark' : 'light',
      });
    } catch (e) {
      // Missing handler (e.g. running against an older native side) is
      // non-fatal — the UI still works, the titlebar just stays on its
      // OS-derived fallback until the next launch picks up new Swift code.
      debugPrint('NativeWindowTheme.apply failed: $e');
    }
  }

  bool get _isMac {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  static String _hex(Color c) {
    final v = c.toARGB32() & 0xFFFFFF;
    return v.toRadixString(16).toUpperCase().padLeft(6, '0');
  }
}
