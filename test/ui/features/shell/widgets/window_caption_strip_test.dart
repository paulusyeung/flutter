import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/screenshot_window_controller.dart';
import 'package:admin/ui/features/shell/widgets/window_caption_strip.dart';

/// Theme that supplies the `InTheme` extension the strip reads via
/// `context.inTheme` on the platform where it actually renders.
ThemeData _theme() => ThemeData.light().copyWith(
  extensions: <ThemeExtension<dynamic>>[InTheme.light],
);

Widget _wrap(Widget child) => MaterialApp(
  theme: _theme(),
  home: Scaffold(body: Column(children: [child])),
);

void main() {
  // The strip's controller pings the native window channel when buttons are
  // hidden; swallow those calls so `setWindowButtonsHidden` doesn't throw
  // `MissingPluginException`.
  const channel = MethodChannel('invoice_ninja/native_window');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // The platform override must be reset inside the test body (a `finally`, not
  // `addTearDown`) — the test framework asserts all foundation debug vars are
  // unset before tear-downs run.

  // Guards the platform gate: window chrome must never leak onto platforms that
  // still show their native title bar (mobile today; web is `kIsWeb`-gated in
  // the widget). Only macOS hides its title bar, so only macOS renders the strip.
  testWidgets('renders nothing on a platform without a hidden title bar', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        _wrap(WindowCaptionStrip(controller: ScreenshotWindowController())),
      );

      expect(find.byType(WindowCaptionStrip), findsOneWidget);
      // The SizedBox.shrink path: no drag handle, zero height.
      expect(
        find.descendant(
          of: find.byType(WindowCaptionStrip),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      expect(tester.getSize(find.byType(WindowCaptionStrip)).height, 0);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('renders a draggable caption strip on macOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        _wrap(WindowCaptionStrip(controller: ScreenshotWindowController())),
      );

      expect(
        find.descendant(
          of: find.byType(WindowCaptionStrip),
          matching: find.byType(GestureDetector),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(WindowCaptionStrip)).height, 28);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  // Hiding the OS buttons from the Debug Panel collapses the strip so the
  // sidebar / content rises to the window's top edge.
  testWidgets('collapses to zero height when window buttons are hidden', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final controller = ScreenshotWindowController();
      await tester.pumpWidget(
        _wrap(WindowCaptionStrip(controller: controller)),
      );

      // Baseline: buttons visible → the 28-px draggable strip is reserved.
      expect(tester.getSize(find.byType(WindowCaptionStrip)).height, 28);

      await controller.setWindowButtonsHidden(true);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(WindowCaptionStrip),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      expect(tester.getSize(find.byType(WindowCaptionStrip)).height, 0);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
