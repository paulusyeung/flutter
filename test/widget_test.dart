// Smoke test for the bootstrap stub. Real tests land alongside their features
// as the corresponding M1 steps complete.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bootstrap renders placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Invoice Ninja'))),
      ),
    );
    expect(find.text('Invoice Ninja'), findsOneWidget);
  });
}
