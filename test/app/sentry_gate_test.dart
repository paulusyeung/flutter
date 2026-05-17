import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/sentry_gate.dart';

void main() {
  group('sentryShouldSend', () {
    test('sends only when the account opted in', () {
      expect(sentryShouldSend(reportErrors: true), isTrue);
    });

    test('drops when the account has not opted in (privacy-safe default)',
        () {
      expect(sentryShouldSend(reportErrors: false), isFalse);
    });
  });
}
