import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/contact.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Drives the Client edit + create screen.
///
/// Holds the in-progress draft in memory. [save] (inherited from
/// [GenericEditViewModel]) is optimistic — it lands the draft in Drift via
/// the repository and pops the route immediately; the outbox handles the
/// server round-trip in the background. 422 validation errors populate
/// `fieldErrors`; other errors land on [submitError].
class ClientEditViewModel extends GenericEditViewModel<Client> {
  ClientEditViewModel({
    required this.repo,
    required this.companyId,
    Client? existing,
    Client? cloneFrom,
  }) : super(
         initialDraft: cloneFrom ?? existing ?? _emptyClient(),
         original: existing,
       );

  final ClientRepository repo;
  final String companyId;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.name.isNotEmpty ||
        d.number.isNotEmpty ||
        d.phone.isNotEmpty ||
        d.website.isNotEmpty ||
        d.address1.isNotEmpty ||
        d.privateNotes.isNotEmpty ||
        d.publicNotes.isNotEmpty;
  }

  @override
  Future<Client> performSave() async {
    if (isCreate) {
      return await repo.create(companyId: companyId, draft: draft);
    }
    await repo.save(companyId: companyId, client: draft);
    return draft;
  }

  /// Reset back to the original draft (or an empty client in create mode).
  void resetToEmpty() => reset(emptyDraft: _emptyClient());

  void setName(String value) =>
      updateDraft(draft.copyWith(name: value, displayName: value));
  void setNumber(String value) => updateDraft(draft.copyWith(number: value));
  void setIdNumber(String value) =>
      updateDraft(draft.copyWith(idNumber: value));
  void setVatNumber(String value) =>
      updateDraft(draft.copyWith(vatNumber: value));
  void setWebsite(String value) => updateDraft(draft.copyWith(website: value));
  void setPhone(String value) => updateDraft(draft.copyWith(phone: value));
  void setAddress1(String value) =>
      updateDraft(draft.copyWith(address1: value));
  void setAddress2(String value) =>
      updateDraft(draft.copyWith(address2: value));
  void setCity(String value) => updateDraft(draft.copyWith(city: value));
  void setState(String value) => updateDraft(draft.copyWith(state: value));
  void setPostalCode(String value) =>
      updateDraft(draft.copyWith(postalCode: value));
  void setCountryId(String value) =>
      updateDraft(draft.copyWith(countryId: value));
  void setPrivateNotes(String value) =>
      updateDraft(draft.copyWith(privateNotes: value));
  void setPublicNotes(String value) =>
      updateDraft(draft.copyWith(publicNotes: value));

  void setCustomValue1(String value) =>
      updateDraft(draft.copyWith(customValue1: value));
  void setCustomValue2(String value) =>
      updateDraft(draft.copyWith(customValue2: value));
  void setCustomValue3(String value) =>
      updateDraft(draft.copyWith(customValue3: value));
  void setCustomValue4(String value) =>
      updateDraft(draft.copyWith(customValue4: value));

  // ───────────────────────── contacts (indexed) ─────────────────────────

  /// Append a fresh empty contact. The new row is marked primary only when
  /// the list was empty — there should always be exactly one primary on a
  /// non-empty list.
  void addContact() {
    final contacts = [...draft.contacts];
    final isFirst = contacts.isEmpty;
    contacts.add(_emptyContact().copyWith(isPrimary: isFirst));
    updateDraft(draft.copyWith(contacts: contacts));
  }

  /// Remove the contact at [index]. If that contact was the primary and any
  /// others remain, contacts[0] is promoted so the entity always carries one
  /// primary (or none when the list ends up empty).
  void removeContact(int index) {
    if (index < 0 || index >= draft.contacts.length) return;
    final contacts = [...draft.contacts];
    final removed = contacts.removeAt(index);
    if (removed.isPrimary && contacts.isNotEmpty) {
      contacts[0] = contacts[0].copyWith(isPrimary: true);
    }
    updateDraft(draft.copyWith(contacts: contacts));
  }

  /// Mark [index] as primary; clears `isPrimary` on every other contact.
  /// Idempotent — calling it on the already-primary index just re-notifies.
  void setContactPrimary(int index) {
    if (index < 0 || index >= draft.contacts.length) return;
    final contacts = <Contact>[
      for (var i = 0; i < draft.contacts.length; i++)
        draft.contacts[i].copyWith(isPrimary: i == index),
    ];
    updateDraft(draft.copyWith(contacts: contacts));
  }

  void setContactFirstNameAt(int i, String v) =>
      _updateContactAt(i, (c) => c.copyWith(firstName: v));
  void setContactLastNameAt(int i, String v) =>
      _updateContactAt(i, (c) => c.copyWith(lastName: v));
  void setContactEmailAt(int i, String v) =>
      _updateContactAt(i, (c) => c.copyWith(email: v));
  void setContactPhoneAt(int i, String v) =>
      _updateContactAt(i, (c) => c.copyWith(phone: v));

  void _updateContactAt(int index, Contact Function(Contact) edit) {
    if (index < 0 || index >= draft.contacts.length) return;
    final contacts = [...draft.contacts];
    contacts[index] = edit(contacts[index]);
    updateDraft(draft.copyWith(contacts: contacts));
  }

  // ───────────────────────── primary contact (legacy) ───────────────────

  // Kept for backwards compatibility with `client_edit_view_model_test.dart`,
  // which exercises the "create primary on the fly when none exists" and
  // "edit-in-place" semantics. New UI code should prefer the indexed
  // `setContactFirstNameAt(i, v)` family.

  void setPrimaryContactFirstName(String value) =>
      _updatePrimaryContact((c) => c.copyWith(firstName: value));
  void setPrimaryContactLastName(String value) =>
      _updatePrimaryContact((c) => c.copyWith(lastName: value));
  void setPrimaryContactEmail(String value) =>
      _updatePrimaryContact((c) => c.copyWith(email: value));
  void setPrimaryContactPhone(String value) =>
      _updatePrimaryContact((c) => c.copyWith(phone: value));

  void _updatePrimaryContact(Contact Function(Contact) edit) {
    final contacts = [...draft.contacts];
    if (contacts.isEmpty) {
      contacts.add(edit(_emptyContact()));
    } else {
      final i = contacts.indexWhere((c) => c.isPrimary);
      final idx = i < 0 ? 0 : i;
      contacts[idx] = edit(contacts[idx]);
    }
    updateDraft(draft.copyWith(contacts: contacts));
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
