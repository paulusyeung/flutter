import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/models/domain/client.dart';
import '../../../../data/models/domain/contact.dart';
import '../../../../data/repositories/client_repository.dart';

/// Drives the Client edit + create screen.
///
/// Holds the in-progress draft in memory. [save] is optimistic — it lands
/// the draft in Drift via the repository and pops the route immediately;
/// the outbox handles the server round-trip in the background. Errors
/// reaching Drift itself (rare — only on corrupt local state) surface on
/// [submitError] instead.
class ClientEditViewModel extends ChangeNotifier {
  ClientEditViewModel({
    required this.repo,
    required this.companyId,
    Client? existing,
  }) : _original = existing,
       _draft = existing ?? _emptyClient();

  final ClientRepository repo;
  final String companyId;
  final Client? _original;
  Client _draft;

  Client get draft => _draft;

  /// True when this VM is for a brand-new client (no existing row).
  bool get isCreate => _original == null;

  /// True when the user has actually changed something. The discard prompt
  /// uses this to decide whether to ask.
  bool get isDirty {
    final orig = _original;
    if (orig == null) return _draftIsNonEmpty();
    return _draft != orig;
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _submitError;
  String? get submitError => _submitError;

  bool _draftIsNonEmpty() {
    return _draft.name.isNotEmpty ||
        _draft.number.isNotEmpty ||
        _draft.phone.isNotEmpty ||
        _draft.website.isNotEmpty ||
        _draft.address1.isNotEmpty ||
        _draft.privateNotes.isNotEmpty ||
        _draft.publicNotes.isNotEmpty;
  }

  void _update(Client next) {
    _draft = next;
    notifyListeners();
  }

  void setName(String value) =>
      _update(_draft.copyWith(name: value, displayName: value));
  void setNumber(String value) => _update(_draft.copyWith(number: value));
  void setIdNumber(String value) => _update(_draft.copyWith(idNumber: value));
  void setVatNumber(String value) => _update(_draft.copyWith(vatNumber: value));
  void setWebsite(String value) => _update(_draft.copyWith(website: value));
  void setPhone(String value) => _update(_draft.copyWith(phone: value));
  void setAddress1(String value) => _update(_draft.copyWith(address1: value));
  void setAddress2(String value) => _update(_draft.copyWith(address2: value));
  void setCity(String value) => _update(_draft.copyWith(city: value));
  void setState(String value) => _update(_draft.copyWith(state: value));
  void setPostalCode(String value) =>
      _update(_draft.copyWith(postalCode: value));
  void setCountryId(String value) => _update(_draft.copyWith(countryId: value));
  void setPrivateNotes(String value) =>
      _update(_draft.copyWith(privateNotes: value));
  void setPublicNotes(String value) =>
      _update(_draft.copyWith(publicNotes: value));

  void setPrimaryContactFirstName(String value) =>
      _updatePrimaryContact((c) => c.copyWith(firstName: value));
  void setPrimaryContactLastName(String value) =>
      _updatePrimaryContact((c) => c.copyWith(lastName: value));
  void setPrimaryContactEmail(String value) =>
      _updatePrimaryContact((c) => c.copyWith(email: value));
  void setPrimaryContactPhone(String value) =>
      _updatePrimaryContact((c) => c.copyWith(phone: value));

  void _updatePrimaryContact(Contact Function(Contact) edit) {
    final contacts = [..._draft.contacts];
    if (contacts.isEmpty) {
      contacts.add(edit(_emptyContact()));
    } else {
      final i = contacts.indexWhere((c) => c.isPrimary);
      final idx = i < 0 ? 0 : i;
      contacts[idx] = edit(contacts[idx]);
    }
    _update(_draft.copyWith(contacts: contacts));
  }

  /// Returns the saved client (with its tmp id for new ones) on success,
  /// null on failure. The view uses the return value to decide whether to
  /// pop the route.
  Future<Client?> save() async {
    if (_isSaving) return null;
    _isSaving = true;
    _submitError = null;
    notifyListeners();
    try {
      if (isCreate) {
        final created = await repo.create(companyId: companyId, draft: _draft);
        return created;
      } else {
        await repo.save(companyId: companyId, client: _draft);
        return _draft;
      }
    } catch (e) {
      _submitError = 'Could not save: $e';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

Client _emptyClient() => Client(
  id: '',
  name: '',
  displayName: '',
  number: '',
  idNumber: '',
  vatNumber: '',
  website: '',
  phone: '',
  address1: '',
  address2: '',
  city: '',
  state: '',
  postalCode: '',
  countryId: '',
  balance: Decimal.zero,
  paidToDate: Decimal.zero,
  creditBalance: Decimal.zero,
  currencyId: '',
  languageId: '',
  paymentTerms: '',
  privateNotes: '',
  publicNotes: '',
  groupSettingsId: '',
  assignedUserId: '',
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  contacts: const [],
);

Contact _emptyContact() => Contact(
  id: '',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  isPrimary: true,
  sendEmail: true,
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  isDeleted: false,
);
