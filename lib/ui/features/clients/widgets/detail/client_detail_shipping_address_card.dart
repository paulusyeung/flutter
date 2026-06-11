import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/detail_info_row.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Shipping Address" card on the client detail screen — the shipping_*
/// mirror of [ClientDetailAddressCard]. Hides entirely when every shipping
/// field is empty (the common case), so it only appears for clients that
/// actually ship to a different address.
class ClientDetailShippingAddressCard extends StatelessWidget {
  const ClientDetailShippingAddressCard({super.key, required this.client});

  final Client client;

  /// Whether any shipping field is populated — drives both this card's
  /// visibility and the grid's decision to reserve a slot for it.
  static bool hasContent(Client c) =>
      c.shippingAddress1.isNotEmpty ||
      c.shippingAddress2.isNotEmpty ||
      c.shippingCity.isNotEmpty ||
      c.shippingState.isNotEmpty ||
      c.shippingPostalCode.isNotEmpty ||
      c.shippingCountryId.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cityStateZip = [
      client.shippingCity,
      client.shippingState,
      client.shippingPostalCode,
    ].where((s) => s.isNotEmpty).join(', ');
    final country = _resolveCountryName(context, client.shippingCountryId);

    final rows = <Widget?>[
      if (client.shippingAddress1.isNotEmpty)
        DetailInfoRow(
          label: context.tr('address1'),
          value: client.shippingAddress1,
        ),
      if (client.shippingAddress2.isNotEmpty)
        DetailInfoRow(
          label: context.tr('address2'),
          value: client.shippingAddress2,
        ),
      if (cityStateZip.isNotEmpty)
        DetailInfoRow(label: context.tr('city'), value: cityStateZip),
      if (country.isNotEmpty)
        DetailInfoRow(
          label: context.tr('country'),
          value: country,
          copyable: false,
        ),
    ];
    if (rows.whereType<Widget>().isEmpty) return const SizedBox.shrink();
    return DashboardCardShell(
      title: context.tr('shipping_address'),
      child: DetailRowStack(children: rows),
    );
  }

  /// Best-effort country name lookup (statics map; falls back to the raw id
  /// during the first frame after login). Mirrors [ClientDetailAddressCard].
  String _resolveCountryName(BuildContext context, String countryId) {
    if (countryId.isEmpty) return '';
    final statics = context.read<Services>().statics;
    return statics.country(countryId)?.name ?? countryId;
  }
}
