import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header_host.dart';
import 'package:admin/utils/formatting.dart';

class PaymentDetailHeader extends StatelessWidget {
  const PaymentDetailHeader({super.key, required this.payment, this.formatter});

  final Payment payment;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeaderHost<Payment>(
      entity: payment,
      formatter: formatter,
      project: (context, p) => EntityHeaderFields(
        seedForAvatar: p.id,
        displayName: p.number.isEmpty
            ? context.tr('no_name_fallback')
            : '#${p.number}',
        number: p.clientId.isEmpty ? null : p.clientId,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        isDeleted: p.isDeleted,
        isArchived: p.archivedAt != null,
        isDirty: p.isDirty,
      ),
    );
  }
}
