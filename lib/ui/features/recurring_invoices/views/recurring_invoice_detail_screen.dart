import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/client_name_label.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/recurring_invoice.dart';
import 'package:admin/domain/recurring_frequency.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/detail/recent_visit_recorder.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/detail/entity_documents_tab.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/billing_shared/activity/billing_doc_activity_tab.dart';
import 'package:admin/ui/features/billing_shared/sends/billing_doc_sends_tab.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_view.dart';
import 'package:admin/ui/features/recurring_invoices/view_models/recurring_invoice_detail_view_model.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/recurring_invoice_actions.dart';
import 'package:admin/ui/features/recurring_invoices/widgets/recurring_invoice_status_pill.dart';

class RecurringInvoiceDetailScreen extends StatefulWidget {
  const RecurringInvoiceDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<RecurringInvoiceDetailScreen> createState() =>
      _RecurringInvoiceDetailScreenState();
}

class _RecurringInvoiceDetailScreenState
    extends State<RecurringInvoiceDetailScreen> with FormatterHostMixin {
  late final RecurringInvoiceDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = RecurringInvoiceDetailViewModel.bound(
      _services.recurringInvoices.watch(companyId: _companyId, id: widget.id),
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
    return EntityDetailScaffold<RecurringInvoice>(
      vm: _vm,
      emptyIcon: Icons.event_repeat_outlined,
      emptyTitle: context.tr('recurring_invoice_not_found'),
      actionsForItem: (context, ri) =>
          EntityDetailActionsRow<RecurringInvoiceAction>(
        items: RecurringInvoiceActions.itemsFor(
          context,
          ri,
          (a) => RecurringInvoiceActions.dispatch(
            context,
            _services,
            _companyId,
            ri,
            a,
          ),
        ),
      ),
      bodyBuilder: (context, ri) => _Body(
        recurringInvoice: ri,
        services: _services,
        companyId: _companyId,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.recurringInvoice,
    required this.services,
    required this.companyId,
  });

  final RecurringInvoice recurringInvoice;
  final Services services;
  final String companyId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints) &&
            constraints.maxWidth >= 900;
        final main = SingleChildScrollView(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecentVisitRecorder(
                type: EntityType.recurringInvoice,
                id: recurringInvoice.id,
                label: recurringInvoice.number.isEmpty
                    ? context.tr('recurring_invoice')
                    : '#${recurringInvoice.number}',
                child: _Header(recurringInvoice: recurringInvoice),
              ),
              SizedBox(height: InSpacing.lg(context)),
              EntityDetailTabs(
                tabs: [
                  EntityDetailTab(
                    label: context.tr('overview'),
                    icon: Icons.dashboard_outlined,
                    bodyBuilder: (_) => Padding(
                      padding: EdgeInsets.all(InSpacing.lg(context)),
                      child: _Overview(recurringInvoice: recurringInvoice),
                    ),
                  ),
                  EntityDetailTab(
                    label: recurringInvoice.documents.isEmpty
                        ? context.tr('documents')
                        : context.tr('documents_with_count', {
                            'count': '${recurringInvoice.documents.length}',
                          }),
                    icon: Icons.description_outlined,
                    bodyBuilder: (_) => EntityDocumentsTab(
                      entityId: recurringInvoice.id,
                      documents: recurringInvoice.documents,
                      onUpload: (sources) async {
                        for (final s in sources) {
                          await services.recurringInvoices.uploadDocument(
                            companyId: companyId,
                            entityId: recurringInvoice.id,
                            source: s,
                          );
                        }
                      },
                      onDelete: (doc) async {
                        await services.recurringInvoices.deleteDocument(
                          companyId: companyId,
                          entityId: recurringInvoice.id,
                          documentId: doc.id,
                        );
                      },
                      onToggleVisibility: (doc) async {
                        await services.recurringInvoices.setDocumentVisibility(
                          companyId: companyId,
                          entityId: recurringInvoice.id,
                          documentId: doc.id,
                          isPublic: !doc.isPublic,
                        );
                      },
                    ),
                  ),
                  EntityDetailTab(
                    label: context.tr('activity'),
                    icon: Icons.history_outlined,
                    bodyBuilder: (_) => BillingDocActivityTab(
                      entityWireName: 'recurring_invoice',
                      entityId: recurringInvoice.id,
                      companyId: companyId,
                      activitiesApi: services.activities,
                      outboxDao: services.db.outboxDao,
                    ),
                  ),
                  EntityDetailTab(
                    label: context.tr('email_history'),
                    icon: Icons.outgoing_mail,
                    bodyBuilder: (_) => BillingDocSendsTab(
                      services: services,
                      companyId: companyId,
                      entityWireName: 'recurring_invoice',
                      entityId: recurringInvoice.id,
                      invitations: recurringInvoice.invitations,
                      clientId: recurringInvoice.clientId,
                      isHosted:
                          services.auth.session.value?.isHosted ?? false,
                      onReactivate: (messageId) =>
                          services.recurringInvoices.reactivateInvitationEmail(
                            companyId: companyId,
                            id: recurringInvoice.id,
                            messageId: messageId,
                          ),
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
              child: _PdfPane(recurringInvoice: recurringInvoice),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.recurringInvoice});
  final RecurringInvoice recurringInvoice;

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
          Row(
            children: [
              Text(
                recurringInvoice.number.isEmpty
                    ? '—'
                    : '#${recurringInvoice.number}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(width: 12),
              RecurringInvoiceStatusPill(
                statusId: recurringInvoice.calculatedStatusId,
                hasBounce: recurringInvoice.hasBouncedInvitation,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClientNameLabel(
            clientId: recurringInvoice.clientId,
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
                value: recurringInvoice.amount.toString(),
              ),
              if (recurringInvoice.frequencyId.isNotEmpty)
                _LabelValue(
                  label: context.tr('frequency'),
                  value: _frequencyLabel(
                    context,
                    recurringInvoice.frequencyId,
                  ),
                ),
              if (recurringInvoice.nextSendDate != null)
                _LabelValue(
                  label: context.tr('next_send_date'),
                  value: recurringInvoice.nextSendDate!.toIso(),
                ),
              _LabelValue(
                label: context.tr('remaining_cycles'),
                value: recurringInvoice.remainingCycles < 0
                    ? context.tr('endless')
                    : '${recurringInvoice.remainingCycles}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.recurringInvoice});
  final RecurringInvoice recurringInvoice;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('public_notes'),
          style: TextStyle(
            fontSize: 12,
            color: tokens.ink3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          recurringInvoice.publicNotes.isEmpty
              ? '—'
              : recurringInvoice.publicNotes,
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
          recurringInvoice.terms.isEmpty ? '—' : recurringInvoice.terms,
          style: TextStyle(color: tokens.ink),
        ),
      ],
    );
  }
}

class _PdfPane extends StatelessWidget {
  const _PdfPane({required this.recurringInvoice});
  final RecurringInvoice recurringInvoice;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return BillingDocPdfView(
      entity: BillingDocType.recurringInvoice,
      entityNumber: recurringInvoice.number,
      fetcher: ({String? designId, required bool deliveryNote}) =>
          services.recurringInvoices.api.downloadPdf(
        entityJson: recurringInvoice.toApiJson(),
        designId: designId ??
            (recurringInvoice.designId.isEmpty
                ? null
                : recurringInvoice.designId),
      ),
    );
  }
}

/// Localized recurring-frequency label, falling back to the raw id for
/// an unknown code. Mirrors `recurring_expense_detail_kpi_strip`.
String _frequencyLabel(BuildContext context, String id) {
  final key = kRecurringFrequencyLabelKey[id];
  return key == null ? id : context.tr(key);
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: tokens.ink3)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: tokens.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
