import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/models/domain/vendor_contact.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/detail_info_row.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/utils/formatting.dart';

// ────────────────────────────────────────────────────────────────────
// Vendor detail screen cards. One file because the cards are small and
// almost always rendered together — mirror of how the Client detail
// cards live in `widgets/detail/client_detail_*.dart` but compacted
// into a single module since Vendor's surface is narrower than Client's.
// ────────────────────────────────────────────────────────────────────

/// Layout host for the vendor detail body cards.
///
/// - **≥1100 px**: three equal-width columns — Details · Address · Contacts —
///   with Notes spanning the full width on a second row, and Documents +
///   Aggregate stacking below. Mirror of `ClientDetailCardsGrid`.
/// - **<1100 px**: single scrolling column, all cards stacked.
class VendorDetailCards extends StatelessWidget {
  const VendorDetailCards({
    super.key,
    required this.vendor,
    required this.formatter,
  });

  final Vendor vendor;
  final Formatter? formatter;

  static const double _wideBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        if (wide) return _wide(context);
        return _stacked(context);
      },
    );
  }

  Widget _wide(BuildContext context) {
    final hasContacts = vendor.contacts.isNotEmpty;
    final hasNotes = vendor.privateNotes.isNotEmpty || vendor.publicNotes.isNotEmpty;
    final columns = <Widget>[
      Expanded(child: VendorDetailDetailsCard(vendor: vendor)),
      SizedBox(width: InSpacing.md(context)),
      Expanded(child: VendorDetailAddressCard(vendor: vendor)),
      if (hasContacts) ...[
        SizedBox(width: InSpacing.md(context)),
        Expanded(child: VendorDetailContactsCard(contacts: vendor.contacts)),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        VendorDetailAggregateCard(vendor: vendor, formatter: formatter),
        SizedBox(height: InSpacing.md(context)),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columns,
          ),
        ),
        if (hasNotes) ...[
          SizedBox(height: InSpacing.md(context)),
          VendorDetailNotesCard(vendor: vendor),
        ],
      ],
    );
  }

  Widget _stacked(BuildContext context) {
    final cards = <Widget>[
      VendorDetailAggregateCard(vendor: vendor, formatter: formatter),
      VendorDetailDetailsCard(vendor: vendor),
      VendorDetailAddressCard(vendor: vendor),
      VendorDetailContactsCard(contacts: vendor.contacts),
      if (vendor.privateNotes.isNotEmpty || vendor.publicNotes.isNotEmpty)
        VendorDetailNotesCard(vendor: vendor),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(height: InSpacing.md(context)),
          cards[i],
        ],
      ],
    );
  }
}

// ───────────────────────── Aggregate (balance) ─────────────────────────

/// Two-cell strip showing the vendor's balance + paid_to_date. Same
/// pattern as `ClientDetailKpiStrip` but compacted — Vendor has no
/// credit / payment-balance breakdown to surface.
class VendorDetailAggregateCard extends StatelessWidget {
  const VendorDetailAggregateCard({
    super.key,
    required this.vendor,
    required this.formatter,
  });

  final Vendor vendor;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return DashboardCardShell(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.lg(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _AggregateCell(
              label: context.tr('balance'),
              amount: vendor.balance,
              tokens: tokens,
              formatter: formatter,
              currencyId: vendor.currencyId,
              highlightWhenPositive: tokens.overdue,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: InSpacing.lg(context)),
            child: SizedBox(
              width: 1,
              height: 36,
              child: ColoredBox(color: tokens.border),
            ),
          ),
          Expanded(
            child: _AggregateCell(
              label: context.tr('paid_to_date'),
              amount: vendor.paidToDate,
              tokens: tokens,
              formatter: formatter,
              currencyId: vendor.currencyId,
            ),
          ),
        ],
      ),
    );
  }
}

class _AggregateCell extends StatelessWidget {
  const _AggregateCell({
    required this.label,
    required this.amount,
    required this.tokens,
    required this.formatter,
    required this.currencyId,
    this.highlightWhenPositive,
  });

  final String label;
  final Decimal amount;
  final InTheme tokens;
  final Formatter? formatter;
  final String currencyId;
  final Color? highlightWhenPositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZero = amount == Decimal.zero;
    final formatted = formatter?.money(amount, clientCurrencyId: currencyId) ?? '';
    final value = (isZero || formatted.isEmpty) ? '—' : formatted;
    final valueColor = isZero
        ? tokens.ink3
        : (highlightWhenPositive != null && amount > Decimal.zero
              ? highlightWhenPositive!
              : tokens.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.ink3,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Details ─────────────────────────

class VendorDetailDetailsCard extends StatelessWidget {
  const VendorDetailDetailsCard({super.key, required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    String orDash(String v) => v.isEmpty ? '—' : v;
    Color? dimIfEmpty(String v) => v.isEmpty ? tokens.ink4 : null;
    final websiteUri = _parseWebsite(vendor.website);
    final rows = <Widget?>[
      DetailInfoRow(
        label: context.tr('website'),
        value: orDash(vendor.website),
        valueColor: dimIfEmpty(vendor.website),
        onTap: websiteUri == null
            ? null
            : () => _openWebsite(context, websiteUri),
      ),
      DetailInfoRow(
        label: context.tr('phone'),
        value: orDash(vendor.phone),
        valueColor: dimIfEmpty(vendor.phone),
      ),
      DetailInfoRow(
        label: context.tr('vat_number'),
        value: orDash(vendor.vatNumber),
        valueColor: dimIfEmpty(vendor.vatNumber),
      ),
      DetailInfoRow(
        label: context.tr('id_number'),
        value: orDash(vendor.idNumber),
        valueColor: dimIfEmpty(vendor.idNumber),
      ),
      if (vendor.customValue1.isNotEmpty)
        DetailInfoRow(
          label: context.tr('custom_value1'),
          value: vendor.customValue1,
        ),
      if (vendor.customValue2.isNotEmpty)
        DetailInfoRow(
          label: context.tr('custom_value2'),
          value: vendor.customValue2,
        ),
      if (vendor.customValue3.isNotEmpty)
        DetailInfoRow(
          label: context.tr('custom_value3'),
          value: vendor.customValue3,
        ),
      if (vendor.customValue4.isNotEmpty)
        DetailInfoRow(
          label: context.tr('custom_value4'),
          value: vendor.customValue4,
        ),
    ];
    return DashboardCardShell(
      title: context.tr('details'),
      child: DetailRowStack(children: rows),
    );
  }
}

// ───────────────────────── Address ─────────────────────────

class VendorDetailAddressCard extends StatelessWidget {
  const VendorDetailAddressCard({super.key, required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final cityStateZip = [
      vendor.city,
      vendor.state,
      vendor.postalCode,
    ].where((s) => s.isNotEmpty).join(', ');
    final country = _resolveCountryName(context, vendor.countryId);

    final rows = <Widget?>[
      if (vendor.address1.isNotEmpty)
        DetailInfoRow(label: context.tr('address1'), value: vendor.address1),
      if (vendor.address2.isNotEmpty)
        DetailInfoRow(label: context.tr('address2'), value: vendor.address2),
      if (cityStateZip.isNotEmpty)
        DetailInfoRow(label: context.tr('city'), value: cityStateZip),
      if (country.isNotEmpty)
        DetailInfoRow(label: context.tr('country'), value: country),
    ];
    if (rows.whereType<Widget>().isEmpty) return const SizedBox.shrink();
    return DashboardCardShell(
      title: context.tr('address'),
      child: DetailRowStack(children: rows),
    );
  }

  String _resolveCountryName(BuildContext context, String countryId) {
    if (countryId.isEmpty) return '';
    final statics = context.read<Services>().statics;
    return statics.country(countryId)?.name ?? countryId;
  }
}

// ───────────────────────── Contacts ─────────────────────────

class VendorDetailContactsCard extends StatelessWidget {
  const VendorDetailContactsCard({super.key, required this.contacts});

  final List<VendorContact> contacts;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) return const SizedBox.shrink();
    return DashboardCardShell(
      title: context.tr('contacts'),
      child: DetailRowStack(children: contacts.map(_ContactRow.new).toList()),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(this.contact);
  final VendorContact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final name = ('${contact.firstName} ${contact.lastName}').trim();
    final title = name.isNotEmpty
        ? name
        : (contact.email.isNotEmpty
              ? contact.email
              : context.tr('no_name_fallback'));
    final subtitle = [
      if (contact.email.isNotEmpty && contact.email != title) contact.email,
      if (contact.phone.isNotEmpty) contact.phone,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.ink3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (contact.isPrimary)
            Padding(
              padding: const EdgeInsets.only(left: InSpacing.sm, top: 2),
              child: Icon(Icons.star, size: 14, color: tokens.accent),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Notes ─────────────────────────

class VendorDetailNotesCard extends StatelessWidget {
  const VendorDetailNotesCard({super.key, required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final hasPrivate = vendor.privateNotes.isNotEmpty;
    final hasPublic = vendor.publicNotes.isNotEmpty;
    if (!hasPrivate && !hasPublic) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    return DashboardCardShell(
      title: context.tr('notes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPrivate)
            _NotesBlock(
              label: context.tr('private_notes'),
              body: vendor.privateNotes,
              labelColor: tokens.ink3,
              bodyStyle: theme.textTheme.bodyMedium?.copyWith(color: tokens.ink),
            ),
          if (hasPrivate && hasPublic) ...[
            SizedBox(height: InSpacing.md(context)),
            Divider(height: 1, thickness: 1, color: tokens.border),
            SizedBox(height: InSpacing.md(context)),
          ],
          if (hasPublic)
            _NotesBlock(
              label: context.tr('public_notes'),
              body: vendor.publicNotes,
              labelColor: tokens.ink3,
              bodyStyle: theme.textTheme.bodyMedium?.copyWith(color: tokens.ink),
            ),
        ],
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  const _NotesBlock({
    required this.label,
    required this.body,
    required this.labelColor,
    required this.bodyStyle,
  });

  final String label;
  final String body;
  final Color labelColor;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: InSpacing.xs),
        Text(body, style: bodyStyle),
      ],
    );
  }
}

// ───────────────────────── Website opener ─────────────────────────

Uri? _parseWebsite(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return null;
  if (uri.host.isEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  return uri;
}

Future<void> _openWebsite(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final errorMessage =
      Localization.of(context)?.lookup('failed_to_open_url') ??
      'failed_to_open_url';
  try {
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    }
  } catch (_) {
    /* fall through to error toast */
  }
  if (messenger == null) return;
  // ignore: use_build_context_synchronously
  Notify.error(messenger.context, errorMessage, messenger: messenger);
}
