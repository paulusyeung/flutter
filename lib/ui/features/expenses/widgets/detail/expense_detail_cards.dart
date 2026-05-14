import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_link_card.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/expenses/widgets/detail/expense_status_pill.dart';
import 'package:admin/utils/formatting.dart';

/// Cards stacked under the detail header. Each card is a self-contained
/// surface so they reorder cleanly on narrow viewports. Cross-entity links
/// (Vendor, Client, Project, Category, Invoice) render through the shared
/// [EntityLinkCard], whose row is a `TextButton` — keyboard users can tab
/// to it and press Enter to navigate.
class ExpenseDetailCards extends StatelessWidget {
  const ExpenseDetailCards({
    super.key,
    required this.expense,
    required this.companyId,
    this.formatter,
  });

  final Expense expense;
  final String companyId;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(expense: e, formatter: formatter),
        if (e.vendorId.isNotEmpty) ...[
          SizedBox(height: InSpacing.lg(context)),
          EntityLinkCard<Vendor>(
            titleKey: 'vendor',
            icon: Icons.storefront_outlined,
            entityId: e.vendorId,
            routePath: '/vendors/${e.vendorId}',
            permissionKey: 'view_vendor',
            watchBuilder: () => context.read<Services>().vendors.watch(
              companyId: companyId,
              id: e.vendorId,
            ),
            displayNameOf: (v) => v.name.isEmpty ? e.vendorId : v.name,
          ),
        ],
        if (e.clientId.isNotEmpty) ...[
          SizedBox(height: InSpacing.lg(context)),
          EntityLinkCard<Client>(
            titleKey: 'client',
            icon: Icons.person_outline,
            entityId: e.clientId,
            routePath: '/clients/${e.clientId}',
            permissionKey: 'view_client',
            watchBuilder: () => context.read<Services>().clients.watch(
              companyId: companyId,
              id: e.clientId,
            ),
            displayNameOf: (c) =>
                c.displayName.isNotEmpty ? c.displayName : c.name,
          ),
        ],
        if (e.invoiceId.isNotEmpty) ...[
          SizedBox(height: InSpacing.lg(context)),
          // Invoice isn't wired yet — render a read-only "Generated invoice"
          // line so the user sees the link exists. Tap-to-navigate lands
          // when Invoice ships.
          _InvoiceLinkPlaceholder(invoiceId: e.invoiceId),
        ],
        if (e.projectId.isNotEmpty) ...[
          SizedBox(height: InSpacing.lg(context)),
          EntityLinkCard<Project>(
            titleKey: 'project',
            icon: Icons.work_outline,
            entityId: e.projectId,
            routePath: '/projects/${e.projectId}',
            permissionKey: 'view_project',
            watchBuilder: () => context.read<Services>().projects.watch(
              companyId: companyId,
              id: e.projectId,
            ),
            displayNameOf: (p) => p.name.isEmpty ? e.projectId : p.name,
          ),
        ],
        if (e.categoryId.isNotEmpty) ...[
          SizedBox(height: InSpacing.lg(context)),
          EntityLinkCard<ExpenseCategory>(
            titleKey: 'category',
            icon: Icons.label_outline,
            entityId: e.categoryId,
            routePath: '/settings/expense_categories/${e.categoryId}',
            permissionKey: 'view_expense',
            watchBuilder: () =>
                context.read<Services>().expenseCategories.watch(
                  companyId: companyId,
                  id: e.categoryId,
                ),
            displayNameOf: (c) => c.name.isEmpty ? e.categoryId : c.name,
          ),
        ],
        if (_hasAnyTax(e)) ...[
          SizedBox(height: InSpacing.lg(context)),
          _TaxBreakdownCard(expense: e, formatter: formatter),
        ],
        if (e.isPaid) ...[
          SizedBox(height: InSpacing.lg(context)),
          _PaymentMetadataCard(expense: e, formatter: formatter),
        ],
        if (_hasAnyCustomValue(e)) ...[
          SizedBox(height: InSpacing.lg(context)),
          _CustomFieldsCard(expense: e),
        ],
      ],
    );
  }
}

bool _hasAnyTax(Expense e) =>
    e.taxAmount1 != Decimal.zero ||
    e.taxAmount2 != Decimal.zero ||
    e.taxAmount3 != Decimal.zero ||
    e.taxRate1 != Decimal.zero ||
    e.taxRate2 != Decimal.zero ||
    e.taxRate3 != Decimal.zero;

bool _hasAnyCustomValue(Expense e) =>
    e.customValue1.isNotEmpty ||
    e.customValue2.isNotEmpty ||
    e.customValue3.isNotEmpty ||
    e.customValue4.isNotEmpty;

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: tokens.ink3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle.merge(
              child: value,
              style: TextStyle(fontSize: 13, color: tokens.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.expense, required this.formatter});
  final Expense expense;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final f = formatter;
    final dateText = e.date == null
        ? '—'
        : (f == null ? e.date!.toIso() : f.date(e.date!.toIso()));
    final amountText = f == null
        ? e.amount.toString()
        : f.money(e.amount, clientCurrencyId: e.currencyId);
    final grossText = f == null
        ? e.grossAmount.toString()
        : f.money(e.grossAmount, clientCurrencyId: e.currencyId);
    return DashboardCardShell(
      title: context.tr('details'),
      child: Column(
        children: [
          _Row(
            label: context.tr('status'),
            value: ExpenseStatusPill(statusId: e.calculatedStatusId),
          ),
          _Row(
            label: context.tr('number'),
            value: Text(e.number.isEmpty ? '—' : e.number),
          ),
          _Row(label: context.tr('date'), value: Text(dateText)),
          _Row(label: context.tr('amount'), value: Text(amountText)),
          if (e.taxAmountSum != Decimal.zero)
            _Row(label: context.tr('gross_amount'), value: Text(grossText)),
          if (e.publicNotes.isNotEmpty)
            _Row(label: context.tr('public_notes'), value: Text(e.publicNotes)),
          if (e.privateNotes.isNotEmpty)
            _Row(
              label: context.tr('private_notes'),
              value: Text(e.privateNotes),
            ),
        ],
      ),
    );
  }
}

class _TaxBreakdownCard extends StatelessWidget {
  const _TaxBreakdownCard({required this.expense, required this.formatter});
  final Expense expense;
  final Formatter? formatter;

  String _fmt(Decimal amount) {
    final f = formatter;
    if (f == null) return amount.toString();
    return f.money(amount, clientCurrencyId: expense.currencyId);
  }

  @override
  Widget build(BuildContext context) {
    final e = expense;
    return DashboardCardShell(
      title: context.tr('tax_breakdown'),
      child: Column(
        children: [
          if (e.taxName1.isNotEmpty || e.taxRate1 != Decimal.zero)
            _Row(
              label: e.taxName1.isEmpty
                  ? context.tr('tax_rate1')
                  : e.taxName1,
              value: Text(
                '${e.taxRate1}% · ${_fmt(e.taxAmount1)}',
              ),
            ),
          if (e.taxName2.isNotEmpty || e.taxRate2 != Decimal.zero)
            _Row(
              label: e.taxName2.isEmpty
                  ? context.tr('tax_rate2')
                  : e.taxName2,
              value: Text(
                '${e.taxRate2}% · ${_fmt(e.taxAmount2)}',
              ),
            ),
          if (e.taxName3.isNotEmpty || e.taxRate3 != Decimal.zero)
            _Row(
              label: e.taxName3.isEmpty
                  ? context.tr('tax_rate3')
                  : e.taxName3,
              value: Text(
                '${e.taxRate3}% · ${_fmt(e.taxAmount3)}',
              ),
            ),
          _Row(
            label: context.tr('inclusive_taxes'),
            value: Text(e.usesInclusiveTaxes ? context.tr('yes') : context.tr('no')),
          ),
        ],
      ),
    );
  }
}

class _PaymentMetadataCard extends StatelessWidget {
  const _PaymentMetadataCard({required this.expense, required this.formatter});
  final Expense expense;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final f = formatter;
    final dateText = e.paymentDate == null
        ? '—'
        : (f == null ? e.paymentDate!.toIso() : f.date(e.paymentDate!.toIso()));
    return DashboardCardShell(
      title: context.tr('payment'),
      child: Column(
        children: [
          _Row(label: context.tr('payment_date'), value: Text(dateText)),
          if (e.paymentTypeId.isNotEmpty)
            _Row(
              label: context.tr('payment_type'),
              value: Text(e.paymentTypeId),
            ),
          if (e.transactionReference.isNotEmpty)
            _Row(
              label: context.tr('transaction_reference'),
              value: Text(e.transactionReference),
            ),
        ],
      ),
    );
  }
}

class _CustomFieldsCard extends StatelessWidget {
  const _CustomFieldsCard({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    return DashboardCardShell(
      title: context.tr('custom_fields'),
      child: Column(
        children: [
          if (e.customValue1.isNotEmpty)
            _Row(
              label: context.tr('custom_value1'),
              value: Text(e.customValue1),
            ),
          if (e.customValue2.isNotEmpty)
            _Row(
              label: context.tr('custom_value2'),
              value: Text(e.customValue2),
            ),
          if (e.customValue3.isNotEmpty)
            _Row(
              label: context.tr('custom_value3'),
              value: Text(e.customValue3),
            ),
          if (e.customValue4.isNotEmpty)
            _Row(
              label: context.tr('custom_value4'),
              value: Text(e.customValue4),
            ),
        ],
      ),
    );
  }
}

class _InvoiceLinkPlaceholder extends StatelessWidget {
  const _InvoiceLinkPlaceholder({required this.invoiceId});
  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return DashboardCardShell(
      title: context.tr('invoice'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.receipt_long_outlined, size: 16, color: tokens.ink3),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                invoiceId,
                style: TextStyle(color: tokens.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('coming_soon'),
              style: TextStyle(color: tokens.ink3, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
