import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/bank_account.dart';
import 'package:admin/l10n/localization.dart';

/// Inline warning rendered when the bank integration's upstream provider
/// has dropped the connection (`disabledUpstream == true` + an
/// integration type set). The Reconnect action is stubbed until the
/// Yodlee / Nordigen OAuth flow ships — the button renders disabled with
/// a "Coming soon" tooltip so the affordance is visible without
/// misrepresenting the current capability.
///
/// Shared by `BankAccountEditScreen` and `BankAccountDetailScreen`.
class ReconnectBanner extends StatelessWidget {
  const ReconnectBanner({super.key, required this.account});

  final BankAccount account;

  @override
  Widget build(BuildContext context) {
    if (!account.needsReconnect) return const SizedBox.shrink();
    final tokens = context.inTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.overdueSoft,
        borderRadius: BorderRadius.circular(InRadii.r2),
        border: Border.all(color: tokens.overdue.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.link_off, color: tokens.overdue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('reconnect_bank_account_help'),
              style: TextStyle(color: tokens.ink, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: context.tr('coming_soon'),
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(context.tr('reconnect')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
