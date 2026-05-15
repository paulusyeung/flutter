import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/detail/entity_documents_tab.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_view.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_detail_view_model.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_actions.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_status_pill.dart';

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
      actionsForItem: (context, invoice) => EntityDetailActionsRow<InvoiceAction>(
        items: InvoiceActions.itemsFor(
          context,
          invoice,
          (a) => InvoiceActions.dispatch(
            context,
            _services,
            _companyId,
            invoice,
            a,
          ),
        ),
      ),
      bodyBuilder: (context, invoice) => _Body(
        invoice: invoice,
        services: _services,
        companyId: _companyId,
      ),
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
                  EntityDetailTab(
                    label: invoice.documents.isEmpty
                        ? context.tr('documents')
                        : context.tr('documents_with_count', {
                            'count': '${invoice.documents.length}',
                          }),
                    icon: Icons.description_outlined,
                    bodyBuilder: (_) => EntityDocumentsTab(
                      entityId: invoice.id,
                      documents: invoice.documents,
                      onUpload: (paths) async {
                        for (final p in paths) {
                          await services.invoices.uploadDocument(
                            companyId: companyId,
                            invoiceId: invoice.id,
                            localPath: p,
                          );
                        }
                      },
                      onDelete: (doc) async {
                        await services.invoices.deleteDocument(
                          companyId: companyId,
                          invoiceId: invoice.id,
                          documentId: doc.id,
                        );
                      },
                      onToggleVisibility: (doc) async {
                        await services.invoices.setDocumentVisibility(
                          companyId: companyId,
                          invoiceId: invoice.id,
                          documentId: doc.id,
                          isPublic: !doc.isPublic,
                        );
                      },
                    ),
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
          Text(
            invoice.clientId.isEmpty ? '—' : invoice.clientId,
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
