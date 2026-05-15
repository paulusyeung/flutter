import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/detail/build_standard_documents_tab.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_activity_tab.dart';

/// Bottom of the client detail screen: a tab strip listing every related-
/// entity table we plan to ship (Invoices, Quotes, Payments, …) plus the
/// already-wired Activity + Documents tabs.
///
/// Most tabs are still placeholders ("coming soon" body); Documents and
/// Activity are wired. The tab list order mirrors the React reference at
/// `react/src/pages/clients/show/useTabs.tsx`; Activity sits at the end so
/// graduating placeholder tabs doesn't reshuffle its index.
///
/// Tab scaffolding is delegated to [EntityDetailTabs] in
/// `lib/ui/core/detail/entity_detail_tabs.dart` so Product and future
/// entities reuse the same strip + lazy-mount semantics.
class ClientDetailTabs extends StatelessWidget {
  const ClientDetailTabs({
    required this.client,
    required this.formatter,
    super.key,
  });

  final Client client;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value!.currentCompanyId;

    return EntityDetailTabs(
      tabs: [
        EntityDetailTab(
          label: context.tr('invoices'),
          icon: Icons.receipt_long_outlined,
          bodyBuilder: (_) => const _ComingSoonBody(),
        ),
        EntityDetailTab(
          label: context.tr('quotes'),
          icon: Icons.request_quote_outlined,
          bodyBuilder: (_) => const _ComingSoonBody(),
        ),
        EntityDetailTab(
          label: context.tr('payments'),
          icon: Icons.payments_outlined,
          bodyBuilder: (_) => const _ComingSoonBody(),
        ),
        EntityDetailTab(
          label: context.tr('recurring_invoices'),
          icon: Icons.autorenew,
          bodyBuilder: (_) => const _ComingSoonBody(),
        ),
        EntityDetailTab(
          label: context.tr('credits'),
          icon: Icons.credit_card_outlined,
          bodyBuilder: (_) => const _ComingSoonBody(),
        ),
        EntityDetailTab(
          label: context.tr('projects'),
          icon: Icons.folder_outlined,
          bodyBuilder: (_) => const _ComingSoonBody(),
        ),
        EntityDetailTab(
          label: context.tr('tasks'),
          icon: Icons.check_circle_outline,
          bodyBuilder: (_) => const _ComingSoonBody(),
        ),
        EntityDetailTab(
          label: context.tr('expenses'),
          icon: Icons.account_balance_wallet_outlined,
          bodyBuilder: (_) => const _ComingSoonBody(),
        ),
        buildStandardDocumentsTab(
          context: context,
          companyId: companyId,
          entityId: client.id,
          documents: client.documents,
          repo: services.clients,
          formatter: formatter,
        ),
        EntityDetailTab(
          label: context.tr('activity'),
          icon: Icons.history,
          bodyBuilder: (_) =>
              ClientActivityTabBody(client: client, formatter: formatter),
        ),
      ],
    );
  }
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.xl,
      ),
      child: Center(
        child: Text(
          context.tr('coming_soon_subtitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
        ),
      ),
    );
  }
}
