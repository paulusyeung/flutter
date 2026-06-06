import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/models/domain/vendor_contact.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/detail/custom_field_detail_rows.dart';
import 'package:admin/ui/core/widgets/centered_form_column.dart';
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

/// Responsive grid for the vendor detail body cards.
///
/// - **≥1000 px**: three equal-width columns — Details · Address · Contacts —
///   with Notes spanning the full width on a second row when it has content.
/// - **<1000 px**: single centered column (≤820 px), all cards stacked.
///
/// The KPI strip has moved up into `VendorDetailKpiStrip` (rendered by the
/// screen above this grid), so this widget no longer owns it. Mirror of
/// `ClientDetailCardsGrid`.
class VendorDetailCardsGrid extends StatelessWidget {
  const VendorDetailCardsGrid({
    super.key,
    required this.vendor,
    required this.formatter,
  });

  final Vendor vendor;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= Breakpoints.entityFormMultiColumn;
        if (wide) return _wide(context);
        return CenteredFormColumn(child: _stacked(context));
      },
    );
  }

  Widget _wide(BuildContext context) {
    final hasContacts = vendor.contacts.isNotEmpty;
    final hasNotes =
        vendor.privateNotes.isNotEmpty || vendor.publicNotes.isNotEmpty;
    final columns = <Widget>[
      Expanded(
        child: VendorDetailDetailsCard(vendor: vendor, formatter: formatter),
      ),
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
      VendorDetailDetailsCard(vendor: vendor, formatter: formatter),
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

// Aggregate KPI strip extracted to `vendor_detail_kpi_strip.dart` — vendors
// have no server-side balance, so it shows locally-derived expense aggregates
// (total + last expense date) computed from the local Drift store.

// ───────────────────────── Details ─────────────────────────

class VendorDetailDetailsCard extends StatelessWidget {
  const VendorDetailDetailsCard({
    super.key,
    required this.vendor,
    this.formatter,
  });

  final Vendor vendor;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final yes = context.tr('yes');
    final no = context.tr('no');
    final websiteUri = _parseWebsite(vendor.website);
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(companyId),
      builder: (context, snapshot) {
        final customRows = customFieldDetailRows(
          company: snapshot.data,
          prefix: 'vendor',
          values: [
            vendor.customValue1,
            vendor.customValue2,
            vendor.customValue3,
            vendor.customValue4,
          ],
          formatter: formatter,
          yes: yes,
          no: no,
        );
        final statics = services.statics;
        final currencyName = vendor.currencyId.isEmpty
            ? ''
            : (statics.currency(vendor.currencyId)?.name ?? '');
        final languageName = vendor.languageId.isEmpty
            ? ''
            : (statics.language(vendor.languageId)?.name ?? '');
        final lastLoginText = vendor.lastLogin == null
            ? ''
            : (formatter?.date(vendor.lastLogin!.toIso8601String()) ??
                  vendor.lastLogin!.toIso8601String());
        final rows = <Widget?>[
          if (vendor.website.isNotEmpty)
            DetailInfoRow(
              label: context.tr('website'),
              value: vendor.website,
              onTap: websiteUri == null
                  ? null
                  : () => _openWebsite(context, websiteUri),
            ),
          if (vendor.phone.isNotEmpty)
            DetailInfoRow(label: context.tr('phone'), value: vendor.phone),
          if (vendor.vatNumber.isNotEmpty)
            DetailInfoRow(
              label: context.tr('vat_number'),
              value: vendor.vatNumber,
            ),
          if (vendor.idNumber.isNotEmpty)
            DetailInfoRow(
              label: context.tr('id_number'),
              value: vendor.idNumber,
            ),
          if (vendor.classification.isNotEmpty)
            DetailInfoRow(
              label: context.tr('classification'),
              value: context.tr(vendor.classification),
            ),
          if (vendor.routingId.isNotEmpty)
            DetailInfoRow(
              label: context.tr('routing_id'),
              value: vendor.routingId,
            ),
          if (vendor.isTaxExempt)
            DetailInfoRow(label: context.tr('tax_exempt'), value: yes),
          if (currencyName.isNotEmpty)
            DetailInfoRow(label: context.tr('currency'), value: currencyName),
          if (languageName.isNotEmpty)
            DetailInfoRow(label: context.tr('language'), value: languageName),
          if (lastLoginText.isNotEmpty)
            DetailInfoRow(
              label: context.tr('last_login'),
              value: lastLoginText,
            ),
          for (final r in customRows)
            DetailInfoRow(label: r.label, value: r.value),
        ];
        return DashboardCardShell(
          title: context.tr('details'),
          child: DetailRowStack(children: rows),
        );
      },
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
              bodyStyle: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.ink,
              ),
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
              bodyStyle: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.ink,
              ),
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
