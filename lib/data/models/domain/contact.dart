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
    @Default('') String password,
    required DateTime updatedAt,
    required bool isDeleted,
    @Default('') String link,
  }) = _Contact;

  factory Contact.fromApi(ContactApi a) => Contact(
    id: a.id,
    firstName: a.firstName,
    lastName: a.lastName,
    email: a.email,
    phone: a.phone,
    isPrimary: a.isPrimary,
    sendEmail: a.sendEmail,
    password: a.password,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    isDeleted: a.isDeleted,
    link: a.link,
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
    if (password.isNotEmpty) 'password': password,
    'link': link,
  };
}
