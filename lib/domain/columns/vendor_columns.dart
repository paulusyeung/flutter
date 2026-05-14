import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/models/domain/vendor_contact.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';

// Re-export the shared min width so vendor-screen code keeps the same
// single source as clients/products.
export 'package:admin/ui/core/list/entity_list_constants.dart'
    show kColumnFlexMinWidth;

typedef VendorColumn = ColumnDefinition<Vendor>;

/// Default columns the legacy admin-portal exposes for the Vendor list
/// when the user has never customized — mirrors `vendor_presenter.dart`
/// `getDefaultTableFields` from `/Users/hillel/Code/admin-portal/lib/ui/
/// vendor/vendor_presenter.dart`. Order matters: the table renders
/// left-to-right.
const List<String> kDefaultVendorColumns = <String>[
  VendorFieldIds.name,
  VendorFieldIds.number,
  VendorFieldIds.city,
  VendorFieldIds.balance,
];

/// Wire ids — must match the snake_case constants in admin-portal's
/// `vendor_model.dart` `VendorFields`. Renaming any of these breaks
/// compatibility with the existing app.
class VendorFieldIds {
  static const String name = 'name';
  static const String number = 'number';
  static const String balance = 'balance';
  static const String paidToDate = 'paid_to_date';
  static const String contactName = 'contact_name';
  static const String contactEmail = 'contact_email';
  static const String contactPhone = 'contact_phone';
  static const String idNumber = 'id_number';
  static const String vatNumber = 'vat_number';
  static const String address1 = 'address1';
  static const String address2 = 'address2';
  static const String city = 'city';
  static const String state = 'state';
  static const String postalCode = 'postal_code';
  static const String phone = 'phone';
  static const String website = 'website';
  static const String currencyId = 'currency_id';
  static const String publicNotes = 'public_notes';
  static const String privateNotes = 'private_notes';
  static const String custom1 = 'custom1';
  static const String custom2 = 'custom2';
  static const String custom3 = 'custom3';
  static const String custom4 = 'custom4';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String archivedAt = 'archived_at';
}

/// Every column the new app knows how to render for the vendor list.
///
/// Mirrors `kAllClientColumns` in shape — includes columns we can't yet
/// fully populate so a list saved here round-trips cleanly through the
/// admin-portal without losing entries.
final List<VendorColumn> kAllVendorColumns = <VendorColumn>[
  VendorColumn(
    id: VendorFieldIds.number,
    labelKey: 'number',
    width: 100,
    cellBuilder: (v, _) => cellText(v.number),
    valueBuilder: (v) => cellNonZeroString(v.number),
  ),
  VendorColumn(
    id: VendorFieldIds.name,
    labelKey: 'name',
    cellBuilder: (v, _) =>
        cellText(v.name.isNotEmpty ? v.name : _fallbackName(v), bold: true),
    valueBuilder: (v) =>
        cellNonZeroString(v.name.isNotEmpty ? v.name : _fallbackName(v)),
  ),
  VendorColumn(
    id: VendorFieldIds.balance,
    labelKey: 'balance',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (v, _) => cellMoney(v.balance, cents: true),
    valueBuilder: (v) => cellMoneyValue(v.balance),
  ),
  VendorColumn(
    id: VendorFieldIds.paidToDate,
    labelKey: 'paid_to_date',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (v, _) => cellMoney(v.paidToDate, cents: false),
    valueBuilder: (v) => cellMoneyValue(v.paidToDate),
  ),
  VendorColumn(
    id: VendorFieldIds.contactName,
    labelKey: 'contact_name',
    width: 160,
    cellBuilder: (v, _) {
      final c = _firstContact(v.contacts);
      if (c == null) return cellEmpty();
      final n = ('${c.firstName} ${c.lastName}').trim();
      return cellText(n);
    },
    valueBuilder: (v) {
      final c = _firstContact(v.contacts);
      if (c == null) return null;
      return cellNonZeroString(('${c.firstName} ${c.lastName}').trim());
    },
  ),
  VendorColumn(
    id: VendorFieldIds.contactEmail,
    labelKey: 'contact_email',
    width: 200,
    cellBuilder: (v, _) {
      final c = _firstContact(v.contacts);
      return cellText(c?.email ?? '');
    },
    valueBuilder: (v) => cellNonZeroString(_firstContact(v.contacts)?.email ?? ''),
  ),
  VendorColumn(
    id: VendorFieldIds.contactPhone,
    labelKey: 'contact_phone',
    width: 140,
    cellBuilder: (v, _) {
      final c = _firstContact(v.contacts);
      return cellText(c?.phone ?? '');
    },
    valueBuilder: (v) => cellNonZeroString(_firstContact(v.contacts)?.phone ?? ''),
  ),
  VendorColumn(
    id: VendorFieldIds.idNumber,
    labelKey: 'id_number',
    width: 120,
    cellBuilder: (v, _) => cellText(v.idNumber),
    valueBuilder: (v) => cellNonZeroString(v.idNumber),
  ),
  VendorColumn(
    id: VendorFieldIds.vatNumber,
    labelKey: 'vat_number',
    width: 120,
    cellBuilder: (v, _) => cellText(v.vatNumber),
    valueBuilder: (v) => cellNonZeroString(v.vatNumber),
  ),
  VendorColumn(
    id: VendorFieldIds.address1,
    labelKey: 'address1',
    width: 200,
    cellBuilder: (v, _) => cellText(v.address1),
    valueBuilder: (v) => cellNonZeroString(v.address1),
  ),
  VendorColumn(
    id: VendorFieldIds.address2,
    labelKey: 'address2',
    width: 160,
    cellBuilder: (v, _) => cellText(v.address2),
    valueBuilder: (v) => cellNonZeroString(v.address2),
  ),
  VendorColumn(
    id: VendorFieldIds.city,
    labelKey: 'city',
    width: 120,
    cellBuilder: (v, _) => cellText(v.city),
    valueBuilder: (v) => cellNonZeroString(v.city),
  ),
  VendorColumn(
    id: VendorFieldIds.state,
    labelKey: 'state',
    width: 100,
    cellBuilder: (v, _) => cellText(v.state),
    valueBuilder: (v) => cellNonZeroString(v.state),
  ),
  VendorColumn(
    id: VendorFieldIds.postalCode,
    labelKey: 'postal_code',
    width: 110,
    cellBuilder: (v, _) => cellText(v.postalCode),
    valueBuilder: (v) => cellNonZeroString(v.postalCode),
  ),
  VendorColumn(
    id: VendorFieldIds.phone,
    labelKey: 'phone',
    width: 130,
    cellBuilder: (v, _) => cellText(v.phone),
    valueBuilder: (v) => cellNonZeroString(v.phone),
  ),
  VendorColumn(
    id: VendorFieldIds.website,
    labelKey: 'website',
    width: 160,
    cellBuilder: (v, _) => cellText(v.website),
    valueBuilder: (v) => cellNonZeroString(v.website),
  ),
  VendorColumn(
    id: VendorFieldIds.publicNotes,
    labelKey: 'public_notes',
    width: 200,
    cellBuilder: (v, _) => cellText(v.publicNotes),
    valueBuilder: (v) => cellNonZeroString(v.publicNotes),
  ),
  VendorColumn(
    id: VendorFieldIds.privateNotes,
    labelKey: 'private_notes',
    width: 200,
    cellBuilder: (v, _) => cellText(v.privateNotes),
    valueBuilder: (v) => cellNonZeroString(v.privateNotes),
  ),
  VendorColumn(
    id: VendorFieldIds.custom1,
    labelKey: 'custom1',
    width: 140,
    cellBuilder: (v, _) => cellText(v.customValue1),
    valueBuilder: (v) => cellNonZeroString(v.customValue1),
  ),
  VendorColumn(
    id: VendorFieldIds.custom2,
    labelKey: 'custom2',
    width: 140,
    cellBuilder: (v, _) => cellText(v.customValue2),
    valueBuilder: (v) => cellNonZeroString(v.customValue2),
  ),
  VendorColumn(
    id: VendorFieldIds.custom3,
    labelKey: 'custom3',
    width: 140,
    cellBuilder: (v, _) => cellText(v.customValue3),
    valueBuilder: (v) => cellNonZeroString(v.customValue3),
  ),
  VendorColumn(
    id: VendorFieldIds.custom4,
    labelKey: 'custom4',
    width: 140,
    cellBuilder: (v, _) => cellText(v.customValue4),
    valueBuilder: (v) => cellNonZeroString(v.customValue4),
  ),
  VendorColumn(
    id: VendorFieldIds.createdAt,
    labelKey: 'created',
    width: 110,
    cellBuilder: (v, ctx) => cellDate(v.createdAt, ctx),
    valueBuilder: (v) => v.createdAt.toIso8601String(),
  ),
  VendorColumn(
    id: VendorFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 110,
    cellBuilder: (v, ctx) => cellDate(v.updatedAt, ctx),
    valueBuilder: (v) => v.updatedAt.toIso8601String(),
  ),
  VendorColumn(
    id: VendorFieldIds.archivedAt,
    labelKey: 'archived',
    width: 110,
    cellBuilder: (v, ctx) =>
        v.archivedAt == null ? cellEmpty() : cellDate(v.archivedAt!, ctx),
    valueBuilder: (v) => v.archivedAt?.toIso8601String(),
  ),
];

final Map<String, VendorColumn> vendorColumnsById = {
  for (final c in kAllVendorColumns) c.id: c,
};

/// Resolve a list of wire ids to renderable column definitions. Unknown ids
/// are dropped here — but never dropped from the underlying storage list.
List<VendorColumn> resolveVendorColumns(List<String> ids) {
  final out = <VendorColumn>[];
  for (final id in ids) {
    final col = vendorColumnsById[id];
    if (col != null) out.add(col);
  }
  return out;
}

VendorContact? _firstContact(List<VendorContact> contacts) {
  if (contacts.isEmpty) return null;
  return contacts.first;
}

String _fallbackName(Vendor v) {
  final c = _firstContact(v.contacts);
  if (c == null) return '';
  final composed = ('${c.firstName} ${c.lastName}').trim();
  if (composed.isNotEmpty) return composed;
  return c.email;
}
