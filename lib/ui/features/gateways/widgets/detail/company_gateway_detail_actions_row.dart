import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/features/gateways/widgets/company_gateway_actions.dart';

/// Wraps `EntityDetailActionsRow` with the gateway-specific action set.
/// Used by the detail screen's AppBar actions slot.
class CompanyGatewayDetailActionsRow extends StatelessWidget {
  const CompanyGatewayDetailActionsRow({super.key, required this.gateway});

  final CompanyGateway gateway;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value!.currentCompanyId;
    return EntityDetailActionsRow<CompanyGatewayAction>(
      items: CompanyGatewayActions.itemsFor(
        context,
        gateway,
        (action) => CompanyGatewayActions.dispatch(
          context,
          services,
          companyId,
          gateway,
          action,
        ),
      ),
    );
  }
}
