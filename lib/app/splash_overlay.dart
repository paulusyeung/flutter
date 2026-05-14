import 'dart:async';
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
///   1. **idle** — α=1, scale=1.0. The first frame matches the storyboard's
///      end state exactly, so the user perceives a seamless handoff.
///   2. **breathing** — gentle opacity pulse 1.0 ↔ 0.95 with a 2.4 s period.
///      Only engages if `dismiss()` hasn't fired within 600 ms of mount, so
///      typical fast boots never see it.
///   3. **dismissing** — 0.35 s ease-out, simultaneous α 1→0 and scale
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

enum _Phase { idle, breathing, dismissing, done }

class _SplashOverlayState extends State<SplashOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  Timer? _breathTimer;
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
      _breathTimer = Timer(const Duration(milliseconds: 600), _engageBreathing);
    }
  }

  bool _reduceMotion() {
    if (SemanticsBinding.instance.disableAnimations) return true;
    final mq = MediaQuery.maybeOf(context);
    return mq?.disableAnimations ?? false;
  }

  void _engageBreathing() {
    if (!mounted || _phase != _Phase.idle) return;
    if (_reduceMotion()) return;
    setState(() => _phase = _Phase.breathing);
    _breath.repeat(reverse: true);
  }

  void _onDismissedFlag() {
    if (!NativeSplash.dismissed.value) return;
    // Cancel synchronously so a breath timer firing in the ~16 ms gap before
    // the post-frame can't briefly engage breathing during a dismiss.
    _breathTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runExit());
  }

  void _runExit() {
    if (!mounted) return;
    if (_phase == _Phase.dismissing || _phase == _Phase.done) return;
    _breathTimer?.cancel();
    _breath.stop();
    final reduce = _reduceMotion();
    _exit.duration = Duration(milliseconds: reduce ? 200 : 350);
    setState(() => _phase = _Phase.dismissing);
    _exit.forward(from: 0);
  }

  @override
  void dispose() {
    NativeSplash.dismissed.removeListener(_onDismissedFlag);
    _breathTimer?.cancel();
    _breath.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || _phase == _Phase.done) return widget.child;

    final tokens = Theme.of(context).extension<InTheme>();
    final bg = tokens?.bg ?? const Color(0xFFF6F4EF);
    final isDark = tokens?.brightness == Brightness.dark;
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
            animation: Listenable.merge([_breath, _exit]),
            builder: (_, _) {
              final breathOpacity = _phase == _Phase.breathing
                  ? 1.0 -
                        (_breath.value * 0.05) // 1.0 → 0.95
                  : 1.0;
              final exitT = _exit.value;
              final reduce = _reduceMotion();
              final exitOpacity = 1.0 - exitT;
              final exitScale = reduce ? 1.0 : 1.0 + exitT * 0.04;
              final opacity = (breathOpacity * exitOpacity).clamp(0.0, 1.0);

              return Opacity(
                opacity: opacity,
                child: Container(
                  color: bg,
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: exitScale,
                    child: Image.asset(
                      logoAsset,
                      width: 109,
                      height: 25,
                      fit: BoxFit.contain,
                    ),
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
