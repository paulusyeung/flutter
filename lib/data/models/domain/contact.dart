import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/contact_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'contact.freezed.dart';

/// Clean domain shape for a Client contact. Lives embedded inside [Client]
/// because contacts are never browsed independently.
@freezed
abstract class Contact with _$Contact {
  const factory Contact({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required bool isPrimary,
    required bool sendEmail,
    @Default(false) bool ccOnly,
    @Default(false) bool isLocked,
    @Default('') String password,
    required DateTime updatedAt,
    required bool isDeleted,
    @Default('') String link,
    @Default('') String customValue1,
    @Default('') String customValue2,
    @Default('') String customValue3,
    @Default('') String customValue4,
  }) = _Contact;

  factory Contact.fromApi(ContactApi a) => Contact(
    id: a.id,
    firstName: a.firstName,
    lastName: a.lastName,
    email: a.email,
    phone: a.phone,
    isPrimary: a.isPrimary,
    sendEmail: a.sendEmail,
    ccOnly: a.ccOnly,
    isLocked: a.isLocked,
    password: a.password,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    isDeleted: a.isDeleted,
    link: a.link,
    customValue1: a.customValue1,
    customValue2: a.customValue2,
    customValue3: a.customValue3,
    customValue4: a.customValue4,
  );
}

extension ContactCopy on Contact {
  Map<String, dynamic> toApiJson() => {
    if (id.isNotEmpty) 'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'is_primary': isPrimary,
    'send_email': sendEmail,
    'cc_only': ccOnly,
    if (password.isNotEmpty) 'password': password,
    'link': link,
    'custom_value1': customValue1,
    'custom_value2': customValue2,
    'custom_value3': customValue3,
    'custom_value4': customValue4,
  };
}
