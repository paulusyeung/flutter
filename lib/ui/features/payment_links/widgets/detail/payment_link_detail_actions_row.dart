import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/features/payment_links/widgets/payment_link_actions.dart';

/// Wraps `EntityDetailActionsRow` with the PaymentLink action set. Used
/// by the detail screen's AppBar title slot.
class PaymentLinkDetailActionsRow extends StatelessWidget {
  const PaymentLinkDetailActionsRow({super.key, required this.paymentLink});

  final PaymentLink paymentLink;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.currentCompanyId ?? '';
    return EntityDetailActionsRow<PaymentLinkAction>(
      items: PaymentLinkActions.itemsFor(
        context,
        paymentLink,
        (action) => PaymentLinkActions.dispatch(
          context,
          services,
          companyId,
          paymentLink,
          action,
        ),
      ),
    );
  }
}
