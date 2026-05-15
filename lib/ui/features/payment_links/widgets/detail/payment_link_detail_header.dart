import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity header for the Payment Link detail screen. Wraps the
/// shared [EntityDetailHeader] with the payment link's identity fields.
/// Falls back to `no_name_fallback` for nameless rows so the avatar
/// seed stays deterministic.
class PaymentLinkDetailHeader extends StatelessWidget {
  const PaymentLinkDetailHeader({
    super.key,
    required this.paymentLink,
    this.formatter,
  });

  final PaymentLink paymentLink;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeader(
      seedForAvatar: paymentLink.name.isEmpty
          ? paymentLink.id
          : paymentLink.name,
      displayName: paymentLink.name.isEmpty
          ? context.tr('no_name_fallback')
          : paymentLink.name,
      createdAt: paymentLink.createdAt,
      updatedAt: paymentLink.updatedAt,
      isDeleted: paymentLink.isDeleted,
      isArchived: paymentLink.archivedAt != null,
      isDirty: paymentLink.isDirty,
      formatter: formatter,
    );
  }
}
