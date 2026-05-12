import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Tells the macOS native splash overlay (installed by `MainFlutterWindow`)
/// to fade out. Called from the app's first post-frame callback so the splash
/// stays up until Flutter has actually painted something.
///
/// macOS-only. No-op everywhere else.
class NativeSplash {
  NativeSplash._();

  static const MethodChannel _channel = MethodChannel('invoice_ninja/splash');
  static bool _dismissed = false;

  static Future<void> dismiss() async {
    if (_dismissed) return;
    if (kIsWeb || !Platform.isMacOS) return;
    _dismissed = true;
    try {
      await _channel.invokeMethod<void>('dismiss');
    } catch (e) {
      // Native side has a safety timeout that fires the same fade, so a
      // missing handler (older Swift code) is non-fatal.
      debugPrint('NativeSplash.dismiss failed: $e');
    }
  }
}
