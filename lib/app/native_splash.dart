import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:admin/app/splash_overlay.dart';

/// Platform-aware splash coordinator.
///
/// On macOS this calls into [`MainFlutterWindow`] via the
/// `invoice_ninja/splash` method channel to fade the native splash overlay
/// (the one installed at window-construction time, before Flutter has
/// painted). On iOS the storyboard launch screen is owned by UIKit and
/// disappears the moment the Flutter view appears — so we layer a
/// Flutter-rendered [SplashOverlay] on top that mirrors the storyboard's
/// logo position/size, plays a gentle exit animation, then unmounts.
///
/// The signal is the same on both platforms: [dismiss] flips the
/// [dismissed] notifier (which the iOS overlay watches) and, on macOS,
/// dispatches the channel call.
class NativeSplash {
  NativeSplash._();

  static const MethodChannel _channel = MethodChannel('invoice_ninja/splash');

  /// Flips to `true` exactly once, when the app has painted its first frame
  /// and we want the splash to go away. The iOS [SplashOverlay] listens
  /// here to trigger its exit animation; macOS doesn't read it (the channel
  /// call drives the native dismissal directly).
  static final ValueNotifier<bool> dismissed = ValueNotifier<bool>(false);

  /// Wrap the [MaterialApp] body so the iOS-side overlay can render above
  /// every route. No-op (passthrough) on non-iOS platforms.
  static Widget wrap({required Widget child}) => SplashOverlay(child: child);

  static Future<void> dismiss() async {
    if (dismissed.value) return;
    dismissed.value = true;
    if (kIsWeb) return;
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod<void>('dismiss');
    } catch (e) {
      // Native side has a safety timeout that fires the same fade, so a
      // missing handler (older Swift code) is non-fatal.
      debugPrint('NativeSplash.dismiss failed: $e');
    }
  }
}
