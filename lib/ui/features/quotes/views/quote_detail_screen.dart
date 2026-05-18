import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/client_name_label.dart';
import 'package:admin/ui/core/widgets/invoice_name_label.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/quote.dart';
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
import 'package:admin/ui/features/quotes/view_models/quote_detail_view_model.dart';
import 'package:admin/ui/features/quotes/widgets/quote_actions.dart';
import 'package:admin/ui/features/quotes/widgets/quote_status_pill.dart';

class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen>
    with FormatterHostMixin {
  late final QuoteDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = QuoteDetailViewModel.bound(
      _services.quotes.watch(companyId: _companyId, id: widget.id),
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
    return EntityDetailScaffold<Quote>(
      vm: _vm,
      emptyIcon: Icons.request_quote_outlined,
      emptyTitle: context.tr('quote_not_found'),
      actionsForItem: (context, quote) => EntityDetailActionsRow<QuoteAction>(
        items: QuoteActions.itemsFor(
          context,
          quote,
          (a) => QuoteActions.dispatch(
            context,
            _services,
            _companyId,
            quote,
            a,
          ),
        ),
      ),
      bodyBuilder: (context, quote) => _Body(
        quote: quote,
        services: _services,
        companyId: _companyId,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.quote,
    required this.services,
    required this.companyId,
  });

  final Quote quote;
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
                type: EntityType.quote,
                id: quote.id,
                label: quote.number.isEmpty
                    ? context.tr('quote')
                    : '#${quote.number}',
                child: _Header(quote: quote),
              ),
              SizedBox(height: InSpacing.lg(context)),
              EntityDetailTabs(
                tabs: [
                  EntityDetailTab(
                    label: context.tr('overview'),
                    icon: Icons.dashboard_outlined,
                    bodyBuilder: (_) => Padding(
                      padding: EdgeInsets.all(InSpacing.lg(context)),
                      child: _Overview(quote: quote),
                    ),
                  ),
                  EntityDetailTab(
                    label: quote.documents.isEmpty
                        ? context.tr('documents')
                        : context.tr('documents_with_count', {
                            'count': '${quote.documents.length}',
                          }),
                    icon: Icons.description_outlined,
                    bodyBuilder: (_) => EntityDocumentsTab(
                      entityId: quote.id,
                      documents: quote.documents,
                      onUpload: (paths) async {
                        for (final p in paths) {
                          await services.quotes.uploadDocument(
                            companyId: companyId,
                            entityId: quote.id,
                            localPath: p,
                          );
                        }
                      },
                      onDelete: (doc) async {
                        await services.quotes.deleteDocument(
                          companyId: companyId,
                          entityId: quote.id,
                          documentId: doc.id,
                        );
                      },
                      onToggleVisibility: (doc) async {
                        await services.quotes.setDocumentVisibility(
                          companyId: companyId,
                          entityId: quote.id,
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
                      entityWireName: 'quote',
                      entityId: quote.id,
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
                      entityWireName: 'quote',
                      entityId: quote.id,
                      invitations: quote.invitations,
                      clientId: quote.clientId,
                      isHosted:
                          services.auth.session.value?.isHosted ?? false,
                      onReactivate: (messageId) =>
                          services.quotes.reactivateInvitationEmail(
                            companyId: companyId,
                            id: quote.id,
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
            Expanded(flex: 6, child: _PdfPane(quote: quote)),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.quote});
  final Quote quote;

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
                quote.number.isEmpty ? '—' : '#${quote.number}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(width: 12),
              QuoteStatusPill(
                statusId: quote.calculatedStatusId,
                hasBounce: quote.hasBouncedInvitation,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClientNameLabel(
            clientId: quote.clientId,
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
                value: quote.amount.toString(),
              ),
              if (quote.dueDate != null)
                _LabelValue(
                  label: context.tr('valid_until'),
                  value: quote.dueDate!.toIso(),
                  strong: quote.isExpired,
                ),
              if (quote.invoiceId.isNotEmpty)
                _LabelValue(
                  label: context.tr('converted_to'),
                  valueChild: InvoiceNameLabel(
                    invoiceId: quote.invoiceId,
                    link: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.inTheme.ink,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.quote});
  final Quote quote;

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
          quote.publicNotes.isEmpty ? '—' : quote.publicNotes,
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
          quote.terms.isEmpty ? '—' : quote.terms,
          style: TextStyle(color: tokens.ink),
        ),
      ],
    );
  }
}

class _PdfPane extends StatelessWidget {
  const _PdfPane({required this.quote});
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return BillingDocPdfView(
      entity: BillingDocType.quote,
      entityNumber: quote.number,
      fetcher: ({String? designId, required bool deliveryNote}) =>
          services.quotes.api.downloadPdf(
        entityJson: quote.toApiJson(),
        designId: designId ??
            (quote.designId.isEmpty ? null : quote.designId),
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    this.value = '',
    this.valueChild,
    this.strong = false,
  });
  final String label;
  final String value;

  /// When provided, rendered instead of the [value] string (used for
  /// reference rows that resolve a name via a `*NameLabel`).
  final Widget? valueChild;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: tokens.ink3)),
        const SizedBox(height: 2),
        valueChild ??
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
