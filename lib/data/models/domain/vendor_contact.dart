import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/vendor_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'vendor_contact.freezed.dart';

/// Clean domain shape for a Vendor contact. Lives embedded inside [Vendor]
/// because vendor contacts are never browsed independently.
///
/// Parallel to `Contact` in `lib/data/models/domain/contact.dart` — Vendor
/// contacts carry the same identity/email/phone fields, plus the password
/// + send_email flag the server stores for portal access. Vendor contacts
/// also carry their own `custom_value1..4` slots.
@freezed
abstract class VendorContact with _$VendorContact {
  const factory VendorContact({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required bool sendEmail,
    // Lone non-`required` field: a server-managed boolean defaulting false,
    // mirrors `Contact.isLocked` so call sites that don't care can omit it.
    @Default(false) bool ccOnly,
    required bool isPrimary,
    required String customValue1,
    required String customValue2,
    required String customValue3,
    required String customValue4,
    required DateTime updatedAt,
    required bool isDeleted,
  }) = _VendorContact;

  factory VendorContact.fromApi(VendorContactApi a) => VendorContact(
    id: a.id,
    firstName: a.firstName,
    lastName: a.lastName,
    email: a.email,
    phone: a.phone,
    password: a.password,
    sendEmail: a.sendEmail,
    ccOnly: a.ccOnly,
    isPrimary: a.isPrimary,
    customValue1: a.customValue1,
    customValue2: a.customValue2,
    customValue3: a.customValue3,
    customValue4: a.customValue4,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    isDeleted: a.isDeleted,
  );
}

extension VendorContactPayload on VendorContact {
  /// Serialize back to the JSON shape the server expects on vendor
  /// create/update. The `id` slot is omitted when it's a `tmp_<uuid>`
  /// (added offline) so the server allocates a real id — unless
  /// [preserveTempId] is `true` for local-only Drift persistence, which
  /// has to keep the temp id so the detail screen can keep watching it.
  /// Mirrors `Contact.toApiJson`.
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) => {
    if (preserveTempId || (!id.startsWith('tmp_') && id.isNotEmpty)) 'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    if (password.isNotEmpty) 'password': password,
    'send_email': sendEmail,
    'cc_only': ccOnly,
    'is_primary': isPrimary,
    'custom_value1': customValue1,
    'custom_value2': customValue2,
    'custom_value3': customValue3,
    'custom_value4': customValue4,
  };
}
