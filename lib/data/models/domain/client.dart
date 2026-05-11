import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../api/client_api_model.dart';
import '../value/money.dart';
import 'contact.dart';

part 'client.freezed.dart';

/// Clean domain shape for a Client.
///
/// Money is [Decimal] (never `double`). Timestamps are UTC [DateTime];
/// date-only server fields use the custom `Date` type when introduced.
@freezed
class Client with _$Client {
  const factory Client({
    required String id,
    required String name,
    required String displayName,
    required String number,
    required String idNumber,
    required String vatNumber,
    required String website,
    required String phone,
    required String address1,
    required String address2,
    required String city,
    required String state,
    required String postalCode,
    required String countryId,
    required Decimal balance,
    required Decimal paidToDate,
    required Decimal creditBalance,
    required String currencyId,
    required String languageId,
    required String paymentTerms,
    required String privateNotes,
    required String publicNotes,
    required String groupSettingsId,
    required String assignedUserId,
    required DateTime updatedAt,
    required DateTime? archivedAt,
    required bool isDeleted,
    required List<Contact> contacts,
    // Local-only — never sent to the server. Populated by the repository
    // from the Drift row's `is_dirty` column so the UI can render an
    // "Unsynced" chip on the detail screen.
    @Default(false) bool isDirty,
  }) = _Client;

  factory Client.fromApi(ClientApi a) => Client(
    id: a.id,
    name: a.name,
    displayName: a.displayName.isNotEmpty ? a.displayName : a.name,
    number: a.number,
    idNumber: a.idNumber,
    vatNumber: a.vatNumber,
    website: a.website,
    phone: a.phone,
    address1: a.address1,
    address2: a.address2,
    city: a.city,
    state: a.state,
    postalCode: a.postalCode,
    countryId: a.countryId,
    balance: parseMoney(a.balance),
    paidToDate: parseMoney(a.paidToDate),
    creditBalance: parseMoney(a.creditBalance),
    currencyId: a.currencyId,
    languageId: a.languageId,
    paymentTerms: a.paymentTerms,
    privateNotes: a.privateNotes,
    publicNotes: a.publicNotes,
    groupSettingsId: a.groupSettingsId,
    assignedUserId: a.assignedUserId,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      a.updatedAt * 1000,
      isUtc: true,
    ),
    archivedAt: a.archivedAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(a.archivedAt * 1000, isUtc: true)
        : null,
    isDeleted: a.isDeleted,
    contacts: a.contacts.map(Contact.fromApi).toList(growable: false),
  );
}

extension ClientPayload on Client {
  /// Serialize back to the JSON shape the server expects for create/update.
  /// Empty `id` lets the server allocate one (the outbox handles tmp→real
  /// remapping after the response lands).
  ///
  /// [preserveTempId] is for **local storage** only — the Drift row needs to
  /// keep the tmp id so the detail screen can keep watching it. The outbox
  /// payload that goes to the server uses the default (drops tmp ids).
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) => {
    if (preserveTempId || !id.startsWith('tmp_')) 'id': id,
    'name': name,
    'display_name': displayName,
    'number': number,
    'id_number': idNumber,
    'vat_number': vatNumber,
    'website': website,
    'phone': phone,
    'address1': address1,
    'address2': address2,
    'city': city,
    'state': state,
    'postal_code': postalCode,
    'country_id': countryId,
    'balance': balance.toString(),
    'paid_to_date': paidToDate.toString(),
    'credit_balance': creditBalance.toString(),
    'currency_id': currencyId,
    'language_id': languageId,
    'payment_terms': paymentTerms,
    'private_notes': privateNotes,
    'public_notes': publicNotes,
    'group_settings_id': groupSettingsId,
    'assigned_user_id': assignedUserId,
    'contacts': contacts.map((c) => c.toApiJson()).toList(),
  };
}
