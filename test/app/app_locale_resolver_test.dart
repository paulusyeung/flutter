import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/app_locale_resolver.dart';

/// Pure mapping tests for the statics-locale → shipped-locale resolution that
/// drives the app UI language (React-parity company-language behaviour).
void main() {
  group('AppLocaleResolver.bestSupportedLocale', () {
    Locale map(String code) => AppLocaleResolver.bestSupportedLocale(code);

    test('exact language match passes through', () {
      expect(map('de'), const Locale('de'));
      expect(map('fr'), const Locale('fr'));
      expect(map('en'), const Locale('en'));
    });

    test('exact language+country match passes through', () {
      expect(map('pt_BR'), const Locale('pt', 'BR'));
      expect(map('en_GB'), const Locale('en', 'GB'));
    });

    test('country variant we do not ship falls back to the base language '
        '(fr_CA → fr) so the right asset loads, not English', () {
      // The bug guarded against: Locale("fr","CA") passes the delegate's
      // isSupported (matches "fr") but load("fr_CA") finds no asset and falls
      // back to English. Mapping to "fr" loads French.
      expect(map('fr_CA'), const Locale('fr'));
      expect(map('fr_CH'), const Locale('fr'));
    });

    test('a different country of the same language maps to the shipped variant '
        '(zh_TW → zh_CN)', () {
      expect(map('zh_TW'), const Locale('zh', 'CN'));
    });

    test('an unshipped language falls back to English', () {
      expect(map('af_ZA'), const Locale('en'));
      expect(map('sq'), const Locale('en'));
      expect(map('ar'), const Locale('en'));
    });

    test('empty code falls back to English', () {
      expect(map(''), const Locale('en'));
    });
  });
}
