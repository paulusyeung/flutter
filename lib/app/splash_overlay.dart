import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/native_splash.dart';

/// iOS-side counterpart to the macOS native splash. UIKit removes the
/// `LaunchScreen.storyboard` the instant the Flutter view appears, so we
/// paint an overlay at the same logo position/size to make the handoff
/// invisible, then fade it out (with a small scale-up) when Flutter has
/// finished its first paint.
///
/// On non-iOS platforms (macOS, Android, web), this is a transparent
/// passthrough — the macOS native splash lives in `MainFlutterWindow.swift`,
/// and other platforms don't have a custom splash to coordinate with.
///
/// Animation phases (iOS only):
///   1. **idle / glow** — α=1, scale=1.0. A soft accent-blue radial halo
///      blooms behind the wordmark: 350 ms ease-out fade-in → 250 ms hold →
///      350 ms ease-in fade-out. Runs once on mount, in parallel with the
///      storyboard → Flutter handoff. The wordmark itself stays still.
///   2. **dismissing** — 0.35 s ease-out, simultaneous α 1→0 and scale
///      1.0→1.04. Reduces to a 0.20 s alpha-only fade under reduced motion.
///
/// Trigger: [NativeSplash.dismissed] flips to `true` from the post-frame
/// callback in `_InvoiceNinjaAppState.initState`; the listener defers the
/// state change with another post-frame callback to avoid `setState during
/// build` if the flag flips mid-build.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

enum _Phase { idle, dismissing, done }

class _SplashOverlayState extends State<SplashOverlay>
    with TickerProviderStateMixin {
  // Glow pulse: 350 ms fade-in → 250 ms hold → 350 ms fade-out, matching the
  // macOS native implementation in MainFlutterWindow.swift.
  static const _glowFadeInEnd = 350.0 / 950.0;
  static const _glowHoldEnd = 600.0 / 950.0;
  static const _glowPeakLight = 0.22;
  static const _glowPeakDark = 0.28;

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  _Phase _phase = _Phase.idle;
  bool get _enabled => !kIsWeb && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (!_enabled) return;
    _exit.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = _Phase.done);
      }
    });
    NativeSplash.dismissed.addListener(_onDismissedFlag);
    if (NativeSplash.dismissed.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runExit());
    } else {
      // Start the glow pulse once the first frame is up. Reduced-motion
      // users get a static logo (no halo, no fade-in animation).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _phase != _Phase.idle) return;
        if (_reduceMotion()) return;
        _glow.forward();
      });
    }
  }

  bool _reduceMotion() {
    if (SemanticsBinding.instance.disableAnimations) return true;
    final mq = MediaQuery.maybeOf(context);
    return mq?.disableAnimations ?? false;
  }

  void _onDismissedFlag() {
    if (!NativeSplash.dismissed.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runExit());
  }

  void _runExit() {
    if (!mounted) return;
    if (_phase == _Phase.dismissing || _phase == _Phase.done) return;
    _glow.stop();
    final reduce = _reduceMotion();
    _exit.duration = Duration(milliseconds: reduce ? 200 : 350);
    setState(() => _phase = _Phase.dismissing);
    _exit.forward(from: 0);
  }

  @override
  void dispose() {
    if (_enabled) {
      NativeSplash.dismissed.removeListener(_onDismissedFlag);
      _glow.dispose();
      _exit.dispose();
    }
    super.dispose();
  }

  /// 0 → 1 → 1 → 0 keyframe shape with ease-out / linear / ease-in segments,
  /// matching the macOS CAKeyframeAnimation. Multiplied against the
  /// theme-aware peak alpha to give the visible halo strength.
  double _glowMultiplier(double t) {
    if (t <= 0.0 || t >= 1.0) return 0.0;
    if (t < _glowFadeInEnd) {
      return Curves.easeOut.transform(t / _glowFadeInEnd);
    }
    if (t < _glowHoldEnd) {
      return 1.0;
    }
    final localT = (t - _glowHoldEnd) / (1.0 - _glowHoldEnd);
    return 1.0 - Curves.easeIn.transform(localT);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || _phase == _Phase.done) return widget.child;

    final tokens = Theme.of(context).extension<InTheme>();
    final bg = tokens?.bg ?? const Color(0xFFF6F4EF);
    final isDark = tokens?.brightness == Brightness.dark;
    final accent = tokens?.accent ?? const Color(0xFF2F7DC3);
    final peak = isDark ? _glowPeakDark : _glowPeakLight;
    // Storyboard `LaunchImage` was generated from these source PNGs by
    // `flutter_native_splash` — render the same files at the same logical
    // size (109×25) so the storyboard → Flutter handoff is invisible.
    final logoAsset = isDark
        ? 'assets/images/logo_light.png'
        : 'assets/images/logo_dark.png';

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([_glow, _exit]),
            builder: (_, _) {
              final exitT = _exit.value;
              final reduce = _reduceMotion();
              final exitOpacity = 1.0 - exitT;
              final exitScale = reduce ? 1.0 : 1.0 + exitT * 0.04;
              final haloAlpha = _glowMultiplier(_glow.value) * peak;

              return Opacity(
                opacity: exitOpacity.clamp(0.0, 1.0),
                child: Container(
                  color: bg,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Halo sits behind the wordmark. Same logical pad
                      // (60 dp around the icon on each side) as the macOS
                      // native CAGradientLayer — scaled to the iOS
                      // 109×25 wordmark gives a 229×145 soft ellipse.
                      // Unscaled on exit: matches macOS, where the
                      // CAGradientLayer halo doesn't take the icon's
                      // transform.scale animation.
                      Container(
                        width: 109 + 120,
                        height: 25 + 120,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: haloAlpha),
                              accent.withValues(alpha: haloAlpha * 0.5),
                              accent.withValues(alpha: 0),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: exitScale,
                        child: Image.asset(
                          logoAsset,
                          width: 109,
                          height: 25,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
