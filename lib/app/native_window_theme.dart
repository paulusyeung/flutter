import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pushes the active Flutter theme's resolved brightness — and, on macOS, its
/// outermost background + ink colors — into the native desktop window chrome so
/// the OS title bar follows the app's light/dark theme.
///
/// - macOS: Swift restyles the titlebar background, traffic-light glyph color
///   (via `NSAppearance`) and the centered title NSTextField, and owns the
///   `UserDefaults` mirror that prevents a cold-start flash on relaunch — every
///   `apply` from here writes those keys on the native side.
/// - Windows: the runner flips the standard caption between light and dark via
///   `DWMWA_USE_IMMERSIVE_DARK_MODE`, reading only the `brightness` field; the
///   `bgHex`/`titleHex` colors are ignored there (standard system styling).
///
/// macOS and Windows only. On every other platform every method is a no-op.
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
    if (!_isSupported) return;
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

  bool get _isSupported {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows;
  }

  static String _hex(Color c) {
    final v = c.toARGB32() & 0xFFFFFF;
    return v.toRadixString(16).toUpperCase().padLeft(6, '0');
  }
}
