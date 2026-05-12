import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/detail_info_row.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Address" card on the client detail screen. Renders street, city/state/zip,
/// and country (country name resolved via the cached statics map when
/// available; falls back to the raw id otherwise). Hides entirely when every
/// field is empty.
class ClientDetailAddressCard extends StatelessWidget {
  const ClientDetailAddressCard({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final cityStateZip = [
      client.city,
      client.state,
      client.postalCode,
    ].where((s) => s.isNotEmpty).join(', ');
    final country = _resolveCountryName(context, client.countryId);

    final rows = <Widget?>[
      if (client.address1.isNotEmpty)
        DetailInfoRow(label: context.tr('address1'), value: client.address1),
      if (client.address2.isNotEmpty)
        DetailInfoRow(label: context.tr('address2'), value: client.address2),
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

  /// Best-effort country name lookup. Statics are loaded once at sign-in,
  /// so this is normally available — but during the very first frame after
  /// login the map can be empty. In that window we return the raw id so the
  /// row still renders something useful instead of vanishing.
  String _resolveCountryName(BuildContext context, String countryId) {
    if (countryId.isEmpty) return '';
    final statics = context.read<Services>().statics;
    return statics.country(countryId)?.name ?? countryId;
  }
}
