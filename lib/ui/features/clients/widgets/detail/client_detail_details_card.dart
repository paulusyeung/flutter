import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_info_row.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Details" card on the client detail screen — website, phone, vat / id
/// numbers, custom fields. Always renders so the wide-grid layout stays
/// column-symmetric; empty standard fields show a muted `—`. Custom fields
/// stay conditional and append below the standard rows when populated.
class ClientDetailDetailsCard extends StatelessWidget {
  const ClientDetailDetailsCard({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    String orDash(String v) => v.isEmpty ? '—' : v;
    Color? dimIfEmpty(String v) => v.isEmpty ? tokens.ink4 : null;

    final rows = <Widget?>[
      ClientDetailInfoRow(
        label: context.tr('website'),
        value: orDash(client.website),
        valueColor: dimIfEmpty(client.website),
      ),
      ClientDetailInfoRow(
        label: context.tr('phone'),
        value: orDash(client.phone),
        valueColor: dimIfEmpty(client.phone),
      ),
      ClientDetailInfoRow(
        label: context.tr('vat_number'),
        value: orDash(client.vatNumber),
        valueColor: dimIfEmpty(client.vatNumber),
      ),
      ClientDetailInfoRow(
        label: context.tr('id_number'),
        value: orDash(client.idNumber),
        valueColor: dimIfEmpty(client.idNumber),
      ),
      if (client.customValue1.isNotEmpty)
        ClientDetailInfoRow(
          label: context.tr('custom_value1'),
          value: client.customValue1,
        ),
      if (client.customValue2.isNotEmpty)
        ClientDetailInfoRow(
          label: context.tr('custom_value2'),
          value: client.customValue2,
        ),
      if (client.customValue3.isNotEmpty)
        ClientDetailInfoRow(
          label: context.tr('custom_value3'),
          value: client.customValue3,
        ),
      if (client.customValue4.isNotEmpty)
        ClientDetailInfoRow(
          label: context.tr('custom_value4'),
          value: client.customValue4,
        ),
    ];
    return DashboardCardShell(
      title: context.tr('details'),
      child: ClientDetailRowStack(children: rows),
    );
  }
}
