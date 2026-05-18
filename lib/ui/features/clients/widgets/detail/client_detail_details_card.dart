import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/detail_info_row.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Details" card on the client detail screen — website, phone, vat / id
/// numbers, custom fields. In the wide grid it always renders so the layout
/// stays column-symmetric (empty standard fields show a muted `—`); the
/// stacked layout drops it entirely when [hasContent] is false. Custom fields
/// stay conditional and append below the standard rows when populated.
///
/// When [compact] is true (the stacked layout — mobile / master-detail
/// preview pane) blank standard rows are omitted entirely rather than shown
/// as a dimmed `—`; the wide grid keeps them (`compact: false`) so the three
/// columns stay vertically symmetric.
class ClientDetailDetailsCard extends StatelessWidget {
  const ClientDetailDetailsCard({
    super.key,
    required this.client,
    this.compact = false,
  });

  final Client client;
  final bool compact;

  /// Whether any field this card renders is populated. Mirrors the exact set
  /// shown in [build] (the four standard fields + the four conditional custom
  /// values) so the stacked layout can omit a wholly-empty card.
  static bool hasContent(Client c) =>
      c.website.isNotEmpty ||
      c.phone.isNotEmpty ||
      c.vatNumber.isNotEmpty ||
      c.idNumber.isNotEmpty ||
      c.customValue1.isNotEmpty ||
      c.customValue2.isNotEmpty ||
      c.customValue3.isNotEmpty ||
      c.customValue4.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    String orDash(String v) => v.isEmpty ? '—' : v;
    Color? dimIfEmpty(String v) => v.isEmpty ? tokens.ink4 : null;

    final websiteUri = _parseWebsite(client.website);

    // Compact (stacked / pane): drop a blank standard row entirely instead of
    // rendering a dimmed `—`. Wide keeps it for column symmetry.
    DetailInfoRow? stdRow(String label, String value, {VoidCallback? onTap}) {
      if (compact && value.isEmpty) return null;
      return DetailInfoRow(
        label: label,
        value: orDash(value),
        valueColor: dimIfEmpty(value),
        onTap: onTap,
      );
    }

    final rows = <Widget?>[
      stdRow(
        context.tr('website'),
        client.website,
        onTap: websiteUri == null
            ? null
            : () => _openWebsite(context, websiteUri),
      ),
      stdRow(context.tr('phone'), client.phone),
      stdRow(context.tr('vat_number'), client.vatNumber),
      stdRow(context.tr('id_number'), client.idNumber),
      if (client.customValue1.isNotEmpty)
        DetailInfoRow(
          label: context.tr('custom_value1'),
          value: client.customValue1,
        ),
      if (client.customValue2.isNotEmpty)
        DetailInfoRow(
          label: context.tr('custom_value2'),
          value: client.customValue2,
        ),
      if (client.customValue3.isNotEmpty)
        DetailInfoRow(
          label: context.tr('custom_value3'),
          value: client.customValue3,
        ),
      if (client.customValue4.isNotEmpty)
        DetailInfoRow(
          label: context.tr('custom_value4'),
          value: client.customValue4,
        ),
    ];
    return DashboardCardShell(
      title: context.tr('details'),
      child: DetailRowStack(children: rows),
    );
  }
}

/// Parses a user-entered website into a launchable URI. Returns null when
/// the value is empty, unparseable, has no host, or isn't an http(s) URL.
/// Bare hosts like `example.com` are upgraded to `https://example.com`.
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
