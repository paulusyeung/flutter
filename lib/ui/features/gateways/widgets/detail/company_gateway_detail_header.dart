import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity header for the CompanyGateway detail screen. Maps the
/// gateway's domain fields into the shared `EntityDetailHeader` slots; the
/// Test-mode pill is rendered as a Row sibling above the header so users
/// can see it at-a-glance.
class CompanyGatewayDetailHeader extends StatelessWidget {
  const CompanyGatewayDetailHeader({
    super.key,
    required this.gateway,
    this.formatter,
  });

  final CompanyGateway gateway;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final providerName = statics.gateway(gateway.gatewayKey)?.name;
    final displayName = gateway.resolveDisplayName(gatewayName: providerName);
    final tokens = context.inTheme;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      gateway.createdAt * 1000,
    );
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      gateway.updatedAt * 1000,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (gateway.testMode)
          Padding(
            padding: EdgeInsets.only(bottom: InSpacing.md(context)),
            child: StatusPill(
              label: context.tr('test'),
              fgColor: tokens.sent,
              bgColor: tokens.sentSoft,
            ),
          ),
        EntityDetailHeader(
          seedForAvatar: gateway.id.isEmpty ? displayName : gateway.id,
          displayName: displayName,
          number: providerName != null && providerName != displayName
              ? providerName
              : null,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isDeleted: gateway.isDeleted,
          isArchived: gateway.archivedAt != 0,
          isDirty: gateway.isDirty,
          formatter: formatter,
        ),
      ],
    );
  }
}
