import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/detail/entity_documents_tab.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/pdf/billing_doc_pdf_view.dart';
import 'package:admin/ui/features/credits/view_models/credit_detail_view_model.dart';
import 'package:admin/ui/features/credits/widgets/credit_actions.dart';
import 'package:admin/ui/features/credits/widgets/credit_status_pill.dart';

class CreditDetailScreen extends StatefulWidget {
  const CreditDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen>
    with FormatterHostMixin {
  late final CreditDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = CreditDetailViewModel.bound(
      _services.credits.watch(companyId: _companyId, id: widget.id),
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
    return EntityDetailScaffold<Credit>(
      vm: _vm,
      emptyIcon: Icons.assignment_return_outlined,
      emptyTitle: context.tr('credit_not_found'),
      actionsForItem: (context, credit) => EntityDetailActionsRow<CreditAction>(
        items: CreditActions.itemsFor(
          context,
          credit,
          (a) => CreditActions.dispatch(
            context,
            _services,
            _companyId,
            credit,
            a,
          ),
        ),
      ),
      bodyBuilder: (context, credit) => _Body(
        credit: credit,
        services: _services,
        companyId: _companyId,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.credit,
    required this.services,
    required this.companyId,
  });

  final Credit credit;
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
              _Header(credit: credit),
              SizedBox(height: InSpacing.lg(context)),
              EntityDetailTabs(
                tabs: [
                  EntityDetailTab(
                    label: context.tr('overview'),
                    icon: Icons.dashboard_outlined,
                    bodyBuilder: (_) => Padding(
                      padding: EdgeInsets.all(InSpacing.lg(context)),
                      child: _Overview(credit: credit),
                    ),
                  ),
                  EntityDetailTab(
                    label: credit.documents.isEmpty
                        ? context.tr('documents')
                        : context.tr('documents_with_count', {
                            'count': '${credit.documents.length}',
                          }),
                    icon: Icons.description_outlined,
                    bodyBuilder: (_) => EntityDocumentsTab(
                      entityId: credit.id,
                      documents: credit.documents,
                      onUpload: (paths) async {
                        for (final p in paths) {
                          await services.credits.uploadDocument(
                            companyId: companyId,
                            entityId: credit.id,
                            localPath: p,
                          );
                        }
                      },
                      onDelete: (doc) async {
                        await services.credits.deleteDocument(
                          companyId: companyId,
                          entityId: credit.id,
                          documentId: doc.id,
                        );
                      },
                      onToggleVisibility: (doc) async {
                        await services.credits.setDocumentVisibility(
                          companyId: companyId,
                          entityId: credit.id,
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
            Expanded(flex: 6, child: _PdfPane(credit: credit)),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.credit});
  final Credit credit;

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
                credit.number.isEmpty ? '—' : '#${credit.number}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(width: 12),
              CreditStatusPill(statusId: credit.calculatedStatusId),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            credit.clientId.isEmpty ? '—' : credit.clientId,
            style: TextStyle(color: tokens.ink3),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _LabelValue(
                label: context.tr('amount'),
                value: credit.amount.toString(),
              ),
              _LabelValue(
                label: context.tr('balance'),
                value: credit.balance.toString(),
              ),
              if (credit.paidToDate.toString() != '0')
                _LabelValue(
                  label: context.tr('applied'),
                  value: credit.paidToDate.toString(),
                ),
              if (credit.dueDate != null)
                _LabelValue(
                  label: context.tr('due_date'),
                  value: credit.dueDate!.toIso(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.credit});
  final Credit credit;

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
          credit.publicNotes.isEmpty ? '—' : credit.publicNotes,
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
          credit.terms.isEmpty ? '—' : credit.terms,
          style: TextStyle(color: tokens.ink),
        ),
      ],
    );
  }
}

class _PdfPane extends StatelessWidget {
  const _PdfPane({required this.credit});
  final Credit credit;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return BillingDocPdfView(
      entity: BillingDocType.credit,
      entityNumber: credit.number,
      fetcher: ({String? designId, required bool deliveryNote}) =>
          services.credits.api.downloadPdf(
        id: credit.id,
        designId: designId ??
            (credit.designId.isEmpty ? null : credit.designId),
      ),
    );
  }
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
