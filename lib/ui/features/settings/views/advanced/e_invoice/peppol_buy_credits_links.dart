import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/link_text.dart';
import 'package:admin/ui/features/gateways/oauth_setup_launcher.dart'
    show openExternal;
import 'package:admin/ui/features/settings/views/advanced/e_invoice/e_invoice_constants.dart';

/// Buy-PEPPOL-credits affordance shared by the onboarding + preferences cards.
///
/// Mirrors React's `BuyCredits` step (`peppol/Onboarding.tsx:330-372`) and the
/// preferences card's `buy_credits` button: two external links to the hosted
/// billing portal (PEPPOL 500 / PEPPOL 1000). The links reflow with [Wrap] so
/// they don't overflow on narrow widths.
///
/// **Hosted-only.** The subscription URLs are invoicing.co billing links that
/// don't apply to self-hosted installs, so the widget renders nothing when the
/// session isn't hosted — callers can drop it in unconditionally.
class PeppolBuyCreditsLinks extends StatelessWidget {
  const PeppolBuyCreditsLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<Services>().auth.session.value;
    if (session == null || !session.isHosted) return const SizedBox.shrink();

    final tokens = context.inTheme;
    final theme = Theme.of(context);
    // Just the two purchase links — no explanatory blurb. React's preferences
    // card shows the buy action bare too; its `peppol_credits_info` copy (which
    // ends "…click Continue") lives only inside the web wizard's modal and would
    // dangle here. `Wrap` so the links reflow instead of overflowing when narrow.
    return Wrap(
      spacing: InSpacing.md(context),
      runSpacing: InSpacing.sm,
      children: [
        LinkText(
          label: '${context.tr('buy')} (PEPPOL 500)',
          color: tokens.accent,
          style: theme.textTheme.bodyMedium,
          onTap: () => unawaited(openExternal(Uri.parse(kPeppolBuy500Url))),
        ),
        LinkText(
          label: '${context.tr('buy')} (PEPPOL 1000)',
          color: tokens.accent,
          style: theme.textTheme.bodyMedium,
          onTap: () => unawaited(openExternal(Uri.parse(kPeppolBuy1000Url))),
        ),
      ],
    );
  }
}
