import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_info_row.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Details" card on the client detail screen — website, phone, vat / id
/// numbers, custom fields. Renders nothing when every field is empty (cards
/// hide entirely rather than showing a title with no rows).
class ClientDetailDetailsCard extends StatelessWidget {
  const ClientDetailDetailsCard({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget?>[
      if (client.website.isNotEmpty)
        ClientDetailInfoRow(
          label: context.tr('website'),
          value: client.website,
        ),
      if (client.phone.isNotEmpty)
        ClientDetailInfoRow(label: context.tr('phone'), value: client.phone),
      if (client.vatNumber.isNotEmpty)
        ClientDetailInfoRow(
          label: context.tr('vat_number'),
          value: client.vatNumber,
        ),
      if (client.idNumber.isNotEmpty)
        ClientDetailInfoRow(
          label: context.tr('id_number'),
          value: client.idNumber,
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
    if (rows.whereType<Widget>().isEmpty) return const SizedBox.shrink();
    return DashboardCardShell(
      title: context.tr('details'),
      child: ClientDetailRowStack(children: rows),
    );
  }
}
