import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/client_registration_field_api_model.dart';

void main() {
  group('ClientRegistrationFieldApi', () {
    test('fromJson / toJson round-trips the three boolean+key fields', () {
      const original = ClientRegistrationFieldApi(
        key: 'email',
        required: true,
        visible: true,
      );
      final json = original.toJson();
      expect(json['key'], 'email');
      expect(json['required'], true);
      expect(json['visible'], true);
      final back = ClientRegistrationFieldApi.fromJson(json);
      expect(back, original);
    });

    test('defaults to (key: "", required: false, visible: true)', () {
      final empty = ClientRegistrationFieldApi.fromJson(const {});
      expect(empty.key, '');
      expect(empty.required, false);
      expect(empty.visible, true);
    });

    test('handles a hidden field (visible: false, required: false)', () {
      final hidden = ClientRegistrationFieldApi.fromJson(const {
        'key': 'phone',
        'visible': false,
        'required': false,
      });
      expect(hidden.visible, false);
      expect(hidden.required, false);
    });
  });
}
