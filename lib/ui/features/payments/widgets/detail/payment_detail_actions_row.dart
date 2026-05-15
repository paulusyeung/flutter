import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/features/payments/widgets/payment_actions.dart';

class PaymentDetailActionsRow extends StatelessWidget {
  const PaymentDetailActionsRow({
    super.key,
    required this.payment,
    required this.onAction,
  });

  final Payment payment;
  final void Function(PaymentAction) onAction;

  @override
  Widget build(BuildContext context) {
    return EntityDetailActionsRow<PaymentAction>(
      items: PaymentActions.itemsFor(context, payment, onAction),
    );
  }
}
