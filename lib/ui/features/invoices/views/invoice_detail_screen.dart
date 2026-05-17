import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/client_name_label.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/detail/build_standard_documents_tab.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/billing_shared/activity/billing_doc_activity_tab.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_view.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_detail_view_model.dart';
import 'package:admin/ui/features/invoices/widgets/detail/invoice_reminders_summary.dart';
import 'package:admin/ui/features/invoices/widgets/detail/invoice_unapplied_payments_section.dart';
import 'package:admin/ui/features/invoices/widgets/detail/invoice_payment_schedule_tab.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_actions.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_status_pill.dart';
import 'package:admin/ui/features/invoices/widgets/rectify_invoice.dart';

/// Read-only Invoice detail screen.
///
/// **M1** shipped the header (number + balance + status pill + actions row).
/// **M2** adds the Documents tab, a wide-mode PDF preview pane, and wires
/// the action set (send email, mark sent/paid, autoBill, view/download/print PDF).
/// **M3** adds line items + invitations + payment history. **M4** adds
/// Verifactu + unapplied payments + reminders.
class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen>
    with FormatterHostMixin {
  late final InvoiceDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = InvoiceDetailViewModel.bound(
      _services.invoices.watch(companyId: _companyId, id: widget.id),
    );
    loadFormatter(_services, _companyId);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityDetailScaffold<Invoice>(
      vm: _vm,
      emptyIcon: Icons.receipt_long_outlined,
      emptyTitle: context.tr('invoice_not_found'),
      actionsForItem: (context, invoice) => _InvoiceActionsRow(
        invoice: invoice,
        services: _services,
        companyId: _companyId,
      ),
      bodyBuilder: (context, invoice) => _Body(
        invoice: invoice,
        services: _services,
        companyId: _companyId,
      ),
    );
  }
}

/// Invoice actions row. The Verifactu "rectify" action's visibility depends
/// on the invoice's client country + the company's `e_invoice_type` — async
/// inputs not available to the synchronous `itemsFor`. We pre-gate on the
/// cheap invoice-only subset ([rectifyPreGate]) and only subscribe the
/// client/company streams when that passes (the rare Verifactu case).
class _InvoiceActionsRow extends StatefulWidget {
  const _InvoiceActionsRow({
    required this.invoice,
    required this.services,
    required this.companyId,
  });

  final Invoice invoice;
  final Services services;
  final String companyId;

  @override
  State<_InvoiceActionsRow> createState() => _InvoiceActionsRowState();
}

class _InvoiceActionsRowState extends State<_InvoiceActionsRow> {
  @override
  void initState() {
    super.initState();
    _ensureClient();
  }

  @override
  void didUpdateWidget(_InvoiceActionsRow old) {
    super.didUpdateWidget(old);
    if (old.invoice.clientId != widget.invoice.clientId) _ensureClient();
  }

  /// The rectify gate needs the invoice's client in Drift (paginated lists
  /// prefetch only page 1). Mirror `ClientNameLabel._ensure`: deduped /
  /// negative-cached / safe to fire unconditionally. Only when the cheap
  /// pre-gate passes, so non-Verifactu invoice opens don't fetch the client.
  void _ensureClient() {
    final inv = widget.invoice;
    if (!rectifyPreGate(inv) || inv.clientId.isEmpty) return;
    widget.services.clients.ensureLoaded(
      companyId: widget.companyId,
      id: inv.clientId,
    );
  }

  Widget _row(BuildContext context, bool rectifyEligible) =>
      EntityDetailActionsRow<InvoiceAction>(
        items: InvoiceActions.itemsFor(
          context,
          widget.invoice,
          (a) => InvoiceActions.dispatch(
            context,
            widget.services,
            widget.companyId,
            widget.invoice,
            a,
          ),
          rectifyEligible: rectifyEligible,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    if (!rectifyPreGate(inv)) return _row(context, false);
    return StreamBuilder<Client?>(
      stream: widget.services.clients
          .watch(companyId: widget.companyId, id: inv.clientId),
      builder: (context, clientSnap) {
        return StreamBuilder<Company?>(
          stream: widget.services.company.watchCompany(widget.companyId),
          builder: (context, companySnap) {
            final eligible = isRectifyEligible(
              invoice: inv,
              clientCountryId: clientSnap.data?.countryId,
              eInvoiceType: companySnap.data?.settings.eInvoiceType,
            );
            return _row(context, eligible);
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.invoice,
    required this.services,
    required this.companyId,
  });

  final Invoice invoice;
  final Services services;
  final String companyId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two-pane on wide: left = info + tabs, right = sticky PDF preview.
        // Single-column on narrow with a "View PDF" affordance routing to
        // `/invoices/:id/pdf`.
        final wide = Breakpoints.isWide(constraints) &&
            constraints.maxWidth >= 900;
        final main = SingleChildScrollView(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(invoice: invoice),
              SizedBox(height: InSpacing.lg(context)),
              EntityDetailTabs(
                tabs: [
                  EntityDetailTab(
                    label: context.tr('overview'),
                    icon: Icons.dashboard_outlined,
                    bodyBuilder: (_) => Padding(
                      padding: EdgeInsets.all(InSpacing.lg(context)),
                      child: _Overview(invoice: invoice),
                    ),
                  ),
                  buildStandardDocumentsTab(
                    context: context,
                    companyId: companyId,
                    entityId: invoice.id,
                    documents: invoice.documents,
                    repo: services.invoices,
                  ),
                  EntityDetailTab(
                    label: context.tr('activity'),
                    icon: Icons.history_outlined,
                    bodyBuilder: (_) => BillingDocActivityTab(
                      entityWireName: 'invoice',
                      entityId: invoice.id,
                      companyId: companyId,
                      activitiesApi: services.activities,
                      outboxDao: services.db.outboxDao,
                    ),
                  ),
                  EntityDetailTab(
                    label: context.tr('unapplied_payments'),
                    icon: Icons.account_balance_wallet_outlined,
                    bodyBuilder: (_) => InvoiceUnappliedPaymentsSection(
                      invoice: invoice,
                      services: services,
                      companyId: companyId,
                    ),
                  ),
                  if (invoiceSupportsPaymentSchedule(
                    invoice,
                    canViewOrEdit:
                        (services.auth.session.value?.currentCompany
                                ?.can('edit_invoice') ??
                            false) ||
                        (services.auth.session.value?.currentCompany
                                ?.can('view_invoice') ??
                            false),
                  ))
                    EntityDetailTab(
                      label: context.tr('payment_schedule'),
                      icon: Icons.event_repeat_outlined,
                      bodyBuilder: (_) =>
                          InvoicePaymentScheduleTab(invoice: invoice),
                    ),
                ],
              ),
            ],
          ),
        );
        if (!wide) return main;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: main),
            VerticalDivider(width: 1, color: context.inTheme.border),
            Expanded(
              flex: 6,
              child: _PdfPane(invoice: invoice),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
        color: tokens.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (invoice.isLocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LockedBanner(),
            ),
          Row(
            children: [
              Text(
                invoice.number.isEmpty ? '—' : '#${invoice.number}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(width: 12),
              InvoiceStatusPill(statusId: invoice.calculatedStatusId),
            ],
          ),
          const SizedBox(height: 8),
          ClientNameLabel(
            clientId: invoice.clientId,
            link: true,
            style: TextStyle(color: tokens.ink3),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _LabelValue(
                label: context.tr('amount'),
                value: invoice.amount.toString(),
              ),
              _LabelValue(
                label: context.tr('balance'),
                value: invoice.balance.toString(),
                strong: invoice.isPastDue,
              ),
              _LabelValue(
                label: context.tr('paid_to_date'),
                value: invoice.paidToDate.toString(),
              ),
              if (invoice.dueDate != null)
                _LabelValue(
                  label: context.tr('due_date'),
                  value: invoice.dueDate!.toIso(),
                  strong: invoice.isPastDue,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // M3 lands the full overview (line items / payments). For M2 we
          // surface the public notes / terms / footer so something useful
          // shows on the tab.
          context.tr('public_notes'),
          style: TextStyle(
            fontSize: 12,
            color: tokens.ink3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          invoice.publicNotes.isEmpty ? '—' : invoice.publicNotes,
          style: TextStyle(color: tokens.ink),
        ),
        SizedBox(height: InSpacing.md(context)),
        Text(
          context.tr('terms'),
          style: TextStyle(
            fontSize: 12,
            color: tokens.ink3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          invoice.terms.isEmpty ? '—' : invoice.terms,
          style: TextStyle(color: tokens.ink),
        ),
        SizedBox(height: InSpacing.md(context)),
        InvoiceRemindersSummary(invoice: invoice),
      ],
    );
  }
}

class _PdfPane extends StatelessWidget {
  const _PdfPane({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return BillingDocPdfView(
      entity: BillingDocType.invoice,
      entityNumber: invoice.number,
      fetcher: ({String? designId, required bool deliveryNote}) =>
          services.invoices.api.downloadPdf(
            id: invoice.id,
            designId: designId ??
                (invoice.designId.isEmpty ? null : invoice.designId),
            deliveryNote: deliveryNote,
          ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.md(context),
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: tokens.overdueSoft,
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: tokens.overdue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr('invoice_locked'),
              style: TextStyle(color: tokens.overdue, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: tokens.ink3),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: strong ? tokens.overdue : tokens.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
