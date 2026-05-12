import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/contact.dart';
import 'package:admin/domain/columns/column_definition.dart';

typedef ClientColumn = ColumnDefinition<Client>;

/// Minimum width for a flex column (today only the name column has
/// `width == null` and therefore flexes). Headers and row cells reference
/// this so the column shrinks to a legible floor on narrow viewports
/// before the horizontal scroller engages.
const double kColumnFlexMinWidth = 220;

/// Default columns the old admin-portal exposes when the user has never
/// customized — mirrors `admin-portal/lib/ui/client/client_presenter.dart`
/// `getDefaultTableFields`. Order matters: the table renders left-to-right.
const List<String> kDefaultClientColumns = <String>[
  ClientFieldIds.number,
  ClientFieldIds.name,
  ClientFieldIds.balance,
  ClientFieldIds.paidToDate,
  ClientFieldIds.contactName,
  ClientFieldIds.contactEmail,
  ClientFieldIds.lastLoginAt,
];

/// Wire ids — must match the snake_case constants in
/// `admin-portal/lib/data/models/client_model.dart:59-160` (`ClientFields`).
/// Renaming any of these breaks compatibility with the existing app.
class ClientFieldIds {
  static const String name = 'name';
  static const String number = 'number';
  static const String balance = 'balance';
  static const String paidToDate = 'paid_to_date';
  static const String creditBalance = 'credit_balance';
  static const String contactName = 'contact_name';
  static const String contactEmail = 'contact_email';
  static const String contactPhone = 'contact_phone';
  static const String lastLoginAt = 'last_login_at';
  static const String idNumber = 'id_number';
  static const String vatNumber = 'vat_number';
  static const String address1 = 'address1';
  static const String address2 = 'address2';
  static const String city = 'city';
  static const String state = 'state';
  static const String postalCode = 'postal_code';
  static const String phone = 'phone';
  static const String website = 'website';
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

/// Every column the new app knows how to render for the client list.
///
/// Includes columns we can't yet fully populate (e.g. `country`, `language`,
/// `currency` — those need statics maps; rendered as empty for now) so a
/// list saved from this app round-trips cleanly through the old admin-portal
/// without losing entries. Unknown ids read from the server are not in this
/// list but are preserved in storage via `extraJson` (see UserSettings DAO).
final List<ClientColumn> kAllClientColumns = <ClientColumn>[
  ClientColumn(
    id: ClientFieldIds.number,
    labelKey: 'number',
    width: 100,
    cellBuilder: (c, _) => _text(c.number),
    valueBuilder: (c) => _nz(c.number),
  ),
  ClientColumn(
    id: ClientFieldIds.name,
    labelKey: 'name',
    cellBuilder: (c, _) =>
        _text(c.displayName.isNotEmpty ? c.displayName : c.name, bold: true),
    valueBuilder: (c) => _nz(c.displayName.isNotEmpty ? c.displayName : c.name),
  ),
  ClientColumn(
    id: ClientFieldIds.balance,
    labelKey: 'balance',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (c, ctx) => _money(c.balance, context: ctx, cents: true),
    valueBuilder: (c) => _moneyValue(c.balance),
  ),
  ClientColumn(
    id: ClientFieldIds.paidToDate,
    labelKey: 'paid_to_date',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (c, ctx) => _money(c.paidToDate, context: ctx, cents: false),
    valueBuilder: (c) => _moneyValue(c.paidToDate),
  ),
  ClientColumn(
    id: ClientFieldIds.creditBalance,
    labelKey: 'credit_balance',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (c, ctx) =>
        _money(c.creditBalance, context: ctx, cents: false),
    valueBuilder: (c) => _moneyValue(c.creditBalance),
  ),
  ClientColumn(
    id: ClientFieldIds.contactName,
    labelKey: 'contact_name',
    width: 160,
    cellBuilder: (c, _) {
      final ct = _primary(c.contacts);
      if (ct == null) return _empty();
      final n = ('${ct.firstName} ${ct.lastName}').trim();
      return _text(n);
    },
    valueBuilder: (c) {
      final ct = _primary(c.contacts);
      if (ct == null) return null;
      return _nz(('${ct.firstName} ${ct.lastName}').trim());
    },
  ),
  ClientColumn(
    id: ClientFieldIds.contactEmail,
    labelKey: 'contact_email',
    width: 200,
    cellBuilder: (c, _) {
      final ct = _primary(c.contacts);
      return _text(ct?.email ?? '');
    },
    valueBuilder: (c) => _nz(_primary(c.contacts)?.email ?? ''),
  ),
  ClientColumn(
    id: ClientFieldIds.contactPhone,
    labelKey: 'contact_phone',
    width: 140,
    cellBuilder: (c, _) {
      final ct = _primary(c.contacts);
      return _text(ct?.phone ?? '');
    },
    valueBuilder: (c) => _nz(_primary(c.contacts)?.phone ?? ''),
  ),
  ClientColumn(
    // Not yet wired — contact `lastLogin` isn't on the new domain model.
    // Empty cell keeps the id alive for round-trip through the old app.
    id: ClientFieldIds.lastLoginAt,
    labelKey: 'last_login',
    width: 120,
    cellBuilder: (_, _) => _empty(),
  ),
  ClientColumn(
    id: ClientFieldIds.idNumber,
    labelKey: 'id_number',
    width: 120,
    cellBuilder: (c, _) => _text(c.idNumber),
    valueBuilder: (c) => _nz(c.idNumber),
  ),
  ClientColumn(
    id: ClientFieldIds.vatNumber,
    labelKey: 'vat_number',
    width: 120,
    cellBuilder: (c, _) => _text(c.vatNumber),
    valueBuilder: (c) => _nz(c.vatNumber),
  ),
  ClientColumn(
    id: ClientFieldIds.address1,
    labelKey: 'address1',
    width: 200,
    cellBuilder: (c, _) => _text(c.address1),
    valueBuilder: (c) => _nz(c.address1),
  ),
  ClientColumn(
    id: ClientFieldIds.address2,
    labelKey: 'address2',
    width: 160,
    cellBuilder: (c, _) => _text(c.address2),
    valueBuilder: (c) => _nz(c.address2),
  ),
  ClientColumn(
    id: ClientFieldIds.city,
    labelKey: 'city',
    width: 120,
    cellBuilder: (c, _) => _text(c.city),
    valueBuilder: (c) => _nz(c.city),
  ),
  ClientColumn(
    id: ClientFieldIds.state,
    labelKey: 'state',
    width: 100,
    cellBuilder: (c, _) => _text(c.state),
    valueBuilder: (c) => _nz(c.state),
  ),
  ClientColumn(
    id: ClientFieldIds.postalCode,
    labelKey: 'postal_code',
    width: 110,
    cellBuilder: (c, _) => _text(c.postalCode),
    valueBuilder: (c) => _nz(c.postalCode),
  ),
  ClientColumn(
    id: ClientFieldIds.phone,
    labelKey: 'phone',
    width: 130,
    cellBuilder: (c, _) => _text(c.phone),
    valueBuilder: (c) => _nz(c.phone),
  ),
  ClientColumn(
    id: ClientFieldIds.website,
    labelKey: 'website',
    width: 160,
    cellBuilder: (c, _) => _text(c.website),
    valueBuilder: (c) => _nz(c.website),
  ),
  ClientColumn(
    id: ClientFieldIds.publicNotes,
    labelKey: 'public_notes',
    width: 200,
    cellBuilder: (c, _) => _text(c.publicNotes),
    valueBuilder: (c) => _nz(c.publicNotes),
  ),
  ClientColumn(
    id: ClientFieldIds.privateNotes,
    labelKey: 'private_notes',
    width: 200,
    cellBuilder: (c, _) => _text(c.privateNotes),
    valueBuilder: (c) => _nz(c.privateNotes),
  ),
  ClientColumn(
    id: ClientFieldIds.custom1,
    labelKey: 'custom1',
    width: 140,
    cellBuilder: (c, _) => _text(c.customValue1),
    valueBuilder: (c) => _nz(c.customValue1),
  ),
  ClientColumn(
    id: ClientFieldIds.custom2,
    labelKey: 'custom2',
    width: 140,
    cellBuilder: (c, _) => _text(c.customValue2),
    valueBuilder: (c) => _nz(c.customValue2),
  ),
  ClientColumn(
    id: ClientFieldIds.custom3,
    labelKey: 'custom3',
    width: 140,
    cellBuilder: (c, _) => _text(c.customValue3),
    valueBuilder: (c) => _nz(c.customValue3),
  ),
  ClientColumn(
    id: ClientFieldIds.custom4,
    labelKey: 'custom4',
    width: 140,
    cellBuilder: (c, _) => _text(c.customValue4),
    valueBuilder: (c) => _nz(c.customValue4),
  ),
  ClientColumn(
    id: ClientFieldIds.createdAt,
    labelKey: 'created',
    width: 110,
    cellBuilder: (c, ctx) => _date(c.createdAt, context: ctx),
    valueBuilder: (c) => c.createdAt.toIso8601String(),
  ),
  ClientColumn(
    id: ClientFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 110,
    cellBuilder: (c, ctx) => _date(c.updatedAt, context: ctx),
    valueBuilder: (c) => c.updatedAt.toIso8601String(),
  ),
  ClientColumn(
    id: ClientFieldIds.archivedAt,
    labelKey: 'archived',
    width: 110,
    cellBuilder: (c, ctx) =>
        c.archivedAt == null ? _empty() : _date(c.archivedAt!, context: ctx),
    valueBuilder: (c) => c.archivedAt?.toIso8601String(),
  ),
];

final Map<String, ClientColumn> clientColumnsById = {
  for (final c in kAllClientColumns) c.id: c,
};

/// Resolve a list of wire ids to renderable column definitions. Unknown ids
/// are dropped here — but never dropped from the underlying storage list.
List<ClientColumn> resolveClientColumns(List<String> ids) {
  final out = <ClientColumn>[];
  for (final id in ids) {
    final col = clientColumnsById[id];
    if (col != null) out.add(col);
  }
  return out;
}

String? _nz(String s) => s.isEmpty ? null : s;

String? _moneyValue(Decimal v) => v == Decimal.zero ? null : v.toString();

Contact? _primary(List<Contact> contacts) {
  if (contacts.isEmpty) return null;
  for (final ct in contacts) {
    if (ct.isPrimary) return ct;
  }
  return contacts.first;
}

Widget _text(String value, {bool bold = false}) {
  if (value.isEmpty) return _empty();
  return _CellText(value: value, bold: bold);
}

Widget _empty() => const _CellText(value: '—', muted: true);

Widget _money(
  Decimal value, {
  required BuildContext context,
  required bool cents,
}) {
  final isZero = value == Decimal.zero;
  final formatter = NumberFormat.decimalPattern()
    ..minimumFractionDigits = cents ? 2 : 0
    ..maximumFractionDigits = cents ? 2 : 0;
  return _MoneyText(
    text: isZero ? '—' : formatter.format(value.toDouble()),
    isZero: isZero,
  );
}

Widget _date(DateTime value, {required BuildContext context}) {
  final formatter = DateFormat.yMMMd(
    Localizations.localeOf(context).toString(),
  );
  return _CellText(value: formatter.format(value.toLocal()));
}

class _CellText extends StatelessWidget {
  const _CellText({required this.value, this.bold = false, this.muted = false});
  final String value;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: muted ? tokens.ink4 : tokens.ink,
      ),
    );
  }
}

class _MoneyText extends StatelessWidget {
  const _MoneyText({required this.text, required this.isZero});
  final String text;
  final bool isZero;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 1.2,
        color: isZero ? tokens.ink3 : tokens.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
