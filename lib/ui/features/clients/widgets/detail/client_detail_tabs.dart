import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/detail/build_standard_documents_tab.dart';
import 'package:admin/ui/core/detail/related_entity_section.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_activity_tab.dart';
import 'package:admin/ui/features/credits/views/credit_list_screen.dart';
import 'package:admin/ui/features/expenses/views/expense_list_screen.dart';
import 'package:admin/ui/features/invoices/views/invoice_list_screen.dart';
import 'package:admin/ui/features/payments/views/payment_list_screen.dart';
import 'package:admin/ui/features/projects/views/project_list_screen.dart';
import 'package:admin/ui/features/quotes/views/quote_list_screen.dart';
import 'package:admin/ui/features/recurring_invoices/views/recurring_invoice_list_screen.dart';
import 'package:admin/ui/features/tasks/views/task_list_screen.dart';

/// Bottom of the client detail screen: a tab strip listing every related-
/// entity table (Invoices, Quotes, Payments, …) plus Activity + Documents.
///
/// Each related-entity tab embeds the corresponding workspace list screen
/// in `embedded: true` mode scoped to this client via its `clientId`
/// constructor param. A "View all" link inside [RelatedEntitySection]
/// routes to the standalone list pre-scoped through a `client_id=`
/// query param (read by each entity's `listBuilder` in
/// `lib/app/entity_modules.dart`).
///
/// Tab order mirrors the React reference at
/// `react/src/pages/clients/show/useTabs.tsx`; Activity sits at the end.
/// Tab scaffolding is delegated to [EntityDetailTabs] in
/// `lib/ui/core/detail/entity_detail_tabs.dart` so other detail screens
/// reuse the same strip + lazy-mount semantics.
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

    final clientId = client.id;
    return EntityDetailTabs(
      tabs: [
        EntityDetailTab(
          label: context.tr('invoices'),
          icon: Icons.receipt_long_outlined,
          bodyBuilder: (_) => RelatedEntitySection(
            titleKey: 'invoices',
            viewAllPath: '/invoices?client_id=$clientId',
            viewAllLabelKey: 'view_all_invoices',
            child: InvoiceListScreen(clientId: clientId, embedded: true),
          ),
        ),
        EntityDetailTab(
          label: context.tr('quotes'),
          icon: Icons.request_quote_outlined,
          bodyBuilder: (_) => RelatedEntitySection(
            titleKey: 'quotes',
            viewAllPath: '/quotes?client_id=$clientId',
            viewAllLabelKey: 'view_all_quotes',
            child: QuoteListScreen(clientId: clientId, embedded: true),
          ),
        ),
        EntityDetailTab(
          label: context.tr('payments'),
          icon: Icons.payments_outlined,
          bodyBuilder: (_) => RelatedEntitySection(
            titleKey: 'payments',
            viewAllPath: '/payments?client_id=$clientId',
            viewAllLabelKey: 'view_all_payments',
            child: PaymentListScreen(clientId: clientId, embedded: true),
          ),
        ),
        EntityDetailTab(
          label: context.tr('recurring_invoices'),
          icon: Icons.autorenew,
          bodyBuilder: (_) => RelatedEntitySection(
            titleKey: 'recurring_invoices',
            viewAllPath: '/recurring_invoices?client_id=$clientId',
            viewAllLabelKey: 'view_all_recurring_invoices',
            child: RecurringInvoiceListScreen(
              clientId: clientId,
              embedded: true,
            ),
          ),
        ),
        EntityDetailTab(
          label: context.tr('credits'),
          icon: Icons.credit_card_outlined,
          bodyBuilder: (_) => RelatedEntitySection(
            titleKey: 'credits',
            viewAllPath: '/credits?client_id=$clientId',
            viewAllLabelKey: 'view_all_credits',
            child: CreditListScreen(clientId: clientId, embedded: true),
          ),
        ),
        EntityDetailTab(
          label: context.tr('projects'),
          icon: Icons.folder_outlined,
          bodyBuilder: (_) => RelatedEntitySection(
            titleKey: 'projects',
            viewAllPath: '/projects?client_id=$clientId',
            viewAllLabelKey: 'view_all_projects',
            child: ProjectListScreen(clientId: clientId, embedded: true),
          ),
        ),
        EntityDetailTab(
          label: context.tr('tasks'),
          icon: Icons.check_circle_outline,
          bodyBuilder: (_) => RelatedEntitySection(
            titleKey: 'tasks',
            viewAllPath: '/tasks?client_id=$clientId',
            viewAllLabelKey: 'view_all_tasks',
            child: TaskListScreen(clientId: clientId, embedded: true),
          ),
        ),
        EntityDetailTab(
          label: context.tr('expenses'),
          icon: Icons.account_balance_wallet_outlined,
          bodyBuilder: (_) => RelatedEntitySection(
            titleKey: 'expenses',
            viewAllPath: '/expenses?client_id=$clientId',
            viewAllLabelKey: 'view_all_expenses',
            child: ExpenseListScreen(clientId: clientId, embedded: true),
          ),
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

