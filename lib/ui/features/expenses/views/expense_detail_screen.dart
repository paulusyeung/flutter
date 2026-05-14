import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/detail/entity_documents_tab.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/expenses/view_models/expense_detail_view_model.dart';
import 'package:admin/ui/features/expenses/widgets/detail/expense_detail_actions_row.dart';
import 'package:admin/ui/features/expenses/widgets/detail/expense_detail_cards_grid.dart';
import 'package:admin/ui/features/expenses/widgets/detail/expense_detail_header.dart';
import 'package:admin/ui/features/expenses/widgets/detail/expense_detail_kpi_strip.dart';
import 'package:admin/ui/features/expenses/widgets/expense_actions.dart';

/// Read-only Expense detail screen.
class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen>
    with FormatterHostMixin {
  late final ExpenseDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = ExpenseDetailViewModel.bound(
      _services.expenses.watch(companyId: _companyId, id: widget.id),
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
    return EntityDetailScaffold<Expense>(
      vm: _vm,
      emptyIcon: Icons.account_balance_wallet_outlined,
      emptyTitle: context.tr('expense_not_found'),
      actionsForItem: (context, e) => ExpenseDetailActionsRow(
        expense: e,
        onAction: (a) => ExpenseActions.dispatch(
          context,
          _services,
          _companyId,
          e,
          a,
        ),
      ),
      bodyBuilder: (context, e) {
        final docCount = e.documents.length;
        final docsLabel = docCount > 0
            ? context.tr('documents_with_count', {'count': '$docCount'})
            : context.tr('documents');
        return SingleChildScrollView(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExpenseDetailHeader(expense: e, formatter: formatter),
              const SizedBox(height: InSpacing.xl),
              EntityDetailTabs(
                tabs: [
                  EntityDetailTab(
                    label: context.tr('overview'),
                    icon: Icons.dashboard_outlined,
                    bodyBuilder: (_) => Padding(
                      padding: EdgeInsets.all(InSpacing.lg(context)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ExpenseDetailKpiStrip(
                            expense: e,
                            formatter: formatter,
                          ),
                          SizedBox(height: InSpacing.md(context)),
                          ExpenseDetailCardsGrid(
                            expense: e,
                            companyId: _companyId,
                            formatter: formatter,
                          ),
                        ],
                      ),
                    ),
                  ),
                  EntityDetailTab(
                    label: docsLabel,
                    icon: Icons.description_outlined,
                    bodyBuilder: (_) => EntityDocumentsTab(
                      entityId: e.id,
                      documents: e.documents,
                      formatter: formatter,
                      onUpload: (paths) async {
                        for (final path in paths) {
                          await _services.expenses.uploadDocument(
                            companyId: _companyId,
                            expenseId: e.id,
                            localPath: path,
                          );
                        }
                      },
                      onDelete: (doc) async {
                        await _services.expenses.deleteDocument(
                          companyId: _companyId,
                          expenseId: e.id,
                          documentId: doc.id,
                        );
                      },
                      onToggleVisibility: (doc) async {
                        await _services.expenses.setDocumentVisibility(
                          companyId: _companyId,
                          expenseId: e.id,
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
      },
    );
  }
}
