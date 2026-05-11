import 'package:admin/utils/url_safety.dart';
import 'package:flutter_test/flutter_test.dart';

/// The predicate gates server-controlled URLs before they're handed to
/// `Image.network`. Loose acceptance lets a hostile server downgrade to
/// http or point at internal addresses — both are tracking/disclosure
/// vectors even when no creds are involved.

void main() {
  group('isSafeHttpsUrl', () {
    test('accepts a plain https URL', () {
      expect(isSafeHttpsUrl('https://cdn.invoiceninja.com/logo.png'), isTrue);
    });
    test('accepts https with query string', () {
      expect(isSafeHttpsUrl('https://cdn.example/logo.png?v=42'), isTrue);
    });
    test('rejects null', () {
      expect(isSafeHttpsUrl(null), isFalse);
    });
    test('rejects empty', () {
      expect(isSafeHttpsUrl(''), isFalse);
    });
    test('rejects http:// (downgrade)', () {
      expect(isSafeHttpsUrl('http://cdn.example/logo.png'), isFalse);
    });
    test('rejects scheme-less', () {
      expect(isSafeHttpsUrl('cdn.example/logo.png'), isFalse);
    });
    test('rejects file://', () {
      expect(isSafeHttpsUrl('file:///etc/passwd'), isFalse);
    });
    test('rejects javascript:', () {
      expect(isSafeHttpsUrl('javascript:alert(1)'), isFalse);
    });
    test('rejects URL with embedded credentials', () {
      expect(isSafeHttpsUrl('https://u:p@cdn.example/logo.png'), isFalse);
    });
    test('rejects empty host', () {
      expect(isSafeHttpsUrl('https://'), isFalse);
    });
  });
}
