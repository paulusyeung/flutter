import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/widgets/copyable_value.dart';

/// `CopyableValue` copies via the platform clipboard channel. Reading the
/// clipboard back hangs in a widget test (fake-async), so these tests intercept
/// the `Clipboard.setData` method-channel call and assert what was written.
void main() {
  String? copied;

  setUp(() {
    copied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(InTheme.light),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('empty value renders the child with no copy affordance', (
    tester,
  ) async {
    await pump(tester, const CopyableValue(value: '', child: Text('x')));

    expect(find.text('x'), findsOneWidget);
    expect(find.byType(CopyIconButton), findsNothing);
  });

  testWidgets('mobile: tapping the value copies it, no hover icon', (
    tester,
  ) async {
    // Reset inside the body (not addTearDown): the foundation-vars invariant
    // check runs before teardowns, so a lingering override fails the test.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pump(
        tester,
        const CopyableValue(value: 'VAT-123', child: Text('VAT-123')),
      );

      // No persistent copy icon on touch — the value itself is the target.
      expect(find.byType(CopyIconButton), findsNothing);

      await tester.tap(find.text('VAT-123'));
      await tester.pumpAndSettle();

      expect(copied, 'VAT-123');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop: hover reveals the copy icon and clicking it copies', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pump(
        tester,
        const CopyableValue(value: 'GB42', child: Text('GB42')),
      );

      // Tapping the value does nothing on desktop — copy is via the icon only.
      await tester.tap(find.text('GB42'));
      await tester.pumpAndSettle();
      expect(copied, isNull);

      // Hover the value to reveal the (otherwise pointer-ignoring) icon.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('GB42')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CopyIconButton));
      await tester.pumpAndSettle();

      expect(copied, 'GB42');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
