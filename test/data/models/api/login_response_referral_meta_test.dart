import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/login_response_api_model.dart';

/// Regression: the live demo server overloads the user's `referral_meta`
/// column with unrelated nested state (`calendar_connection: {status: ...}`)
/// alongside the per-plan integer counts. The model types `referralMeta` as
/// `Map<String, int>`, so a plain `value as num` cast threw
/// `type '_Map<String, dynamic>' is not a subtype of type 'num'` and crashed
/// login deserialization for EVERY session — caught by the live demo
/// integration suite (`integration_test/demo/*`). `_referralMetaFromJson`
/// coerces defensively: keep the integer-valued entries, drop everything else.
void main() {
  group('UserSummaryApi.referral_meta coercion', () {
    test('drops nested-object values; keeps the per-plan int counts '
        '(real demo payload that crashed login)', () {
      final user = UserSummaryApi.fromJson(const {
        'referral_meta': {
          'free': 0,
          'pro': 2,
          'enterprise': 0,
          // The server stuffs unrelated state into the same column.
          'calendar_connection': {'status': 'DISCONNECTED'},
        },
      });

      expect(user.referralMeta, {'free': 0, 'pro': 2, 'enterprise': 0});
      // The nested object must not leak in (and must not throw).
      expect(user.referralMeta.containsKey('calendar_connection'), isFalse);
    });

    test('absent referral_meta falls back to the empty map default', () {
      expect(UserSummaryApi.fromJson(const {}).referralMeta, isEmpty);
      expect(
        UserSummaryApi.fromJson(const {'referral_meta': null}).referralMeta,
        isEmpty,
      );
    });

    test('numeric-string counts parse; non-numeric scalars and lists drop', () {
      final user = UserSummaryApi.fromJson(const {
        'referral_meta': {
          'free': '5', // string-encoded int → 5
          'pro': 1.0, // num → 1
          'enterprise': 'lots', // non-numeric → dropped
          'history': [1, 2, 3], // list → dropped
        },
      });

      expect(user.referralMeta, {'free': 5, 'pro': 1});
    });

    test('a non-map referral_meta is tolerated as empty (no throw)', () {
      expect(
        UserSummaryApi.fromJson(const {
          'referral_meta': 'unexpected',
        }).referralMeta,
        isEmpty,
      );
    });
  });
}
