import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/gateway_token.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Payment Methods" card on the client detail screen — the saved gateway
/// tokens (cards / bank accounts) the client has on file. Read-only mirror of
/// React's `Gateways` card (brand · last4 · expiry · default badge). Hides
/// entirely when the client has no saved methods (the common case).
class ClientDetailPaymentMethodsCard extends StatelessWidget {
  const ClientDetailPaymentMethodsCard({super.key, required this.client});

  final Client client;

  static bool hasContent(Client c) => c.gatewayTokens.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (client.gatewayTokens.isEmpty) return const SizedBox.shrink();
    final tokens = context.inTheme;
    return DashboardCardShell(
      title: context.tr('payment_methods'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < client.gatewayTokens.length; i++) ...[
            if (i > 0)
              Divider(height: InSpacing.lg(context), color: tokens.border),
            _TokenRow(token: client.gatewayTokens[i]),
          ],
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.token});

  final GatewayToken token;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final statics = context.read<Services>().statics;
    final gatewayTypeName =
        statics.gatewayType(token.gatewayTypeId)?.name ?? '';

    // Primary line: "Visa •••• 4242" when card meta is present, else the
    // gateway type name, else an em-dash so the row never renders blank.
    final brand = token.brand.isNotEmpty ? token.brand : gatewayTypeName;
    final masked = token.last4.isNotEmpty ? '•••• ${token.last4}' : '';
    final title = [brand, masked].where((s) => s.isNotEmpty).join(' ').trim();
    final hasExpiry = token.expMonth.isNotEmpty && token.expYear.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.credit_card_outlined, size: 20, color: tokens.ink3),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.isEmpty ? '—' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasExpiry)
                  Text(
                    '${context.tr('expires')} ${token.expMonth}/${token.expYear}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.ink3,
                    ),
                  ),
              ],
            ),
          ),
          if (token.isDefault) ...[
            SizedBox(width: InSpacing.sm),
            StatusPill(
              label: context.tr('default'),
              fgColor: tokens.sent,
              bgColor: tokens.sentSoft,
            ),
          ],
        ],
      ),
    );
  }
}
