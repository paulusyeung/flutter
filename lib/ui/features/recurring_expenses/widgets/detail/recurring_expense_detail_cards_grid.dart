import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/custom_field_detail_rows.dart';
import 'package:admin/ui/core/detail/entity_link_card.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/recurring_expenses/widgets/recurring_expense_status_pill.dart';
import 'package:admin/utils/formatting.dart';

/// Responsive grid for the recurring-expense detail body cards.
///
/// - **≥1100 px**: two equal-width columns. Left holds Summary, Notes (when
///   populated), Schedule (last-sent + remaining cycles + upcoming-runs
///   preview), and Tax Breakdown. Right holds the related-entity link cards
///   (Vendor / Client / Project / Category) and Custom Fields. If the right
///   column ends up empty we fall back to single-column.
/// - **<1100 px**: single stacked column matching the pre-refactor order.
class RecurringExpenseDetailCardsGrid extends StatelessWidget {
  const RecurringExpenseDetailCardsGrid({
    super.key,
    required this.recurringExpense,
    required this.companyId,
    this.formatter,
  });

  final RecurringExpense recurringExpense;
  final String companyId;
  final Formatter? formatter;

  static const double _wideBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        if (wide) return _wide(context);
        return _stacked(context);
      },
    );
  }

  Widget _wide(BuildContext context) {
    final e = recurringExpense;
    final leftCards = <Widget>[
      _SummaryCard(recurringExpense: e, formatter: formatter),
      if (_hasAnyNote(e)) _NotesCard(recurringExpense: e),
      if (_hasScheduleDetail(e))
        _ScheduleCard(recurringExpense: e, formatter: formatter),
      if (_hasAnyTax(e))
        _TaxBreakdownCard(recurringExpense: e, formatter: formatter),
    ];
    final rightCards = _relatedCards(context, e);

    if (rightCards.isEmpty) {
      return _stack(context, leftCards);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _stack(context, leftCards)),
          SizedBox(width: InSpacing.md(context)),
          Expanded(child: _stack(context, rightCards)),
        ],
      ),
    );
  }

  Widget _stacked(BuildContext context) {
    final e = recurringExpense;
    final cards = <Widget>[
      _SummaryCard(recurringExpense: e, formatter: formatter),
      if (_hasAnyNote(e)) _NotesCard(recurringExpense: e),
      if (_hasScheduleDetail(e))
        _ScheduleCard(recurringExpense: e, formatter: formatter),
      ..._relatedCards(context, e),
      if (_hasAnyTax(e))
        _TaxBreakdownCard(recurringExpense: e, formatter: formatter),
    ];
    return _stack(context, cards);
  }

  List<Widget> _relatedCards(BuildContext context, RecurringExpense e) {
    final cards = <Widget>[];
    if (e.vendorId.isNotEmpty) {
      cards.add(
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
      );
    }
    if (e.clientId.isNotEmpty) {
      cards.add(
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
      );
    }
    if (e.projectId.isNotEmpty) {
      cards.add(
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
      );
    }
    if (e.categoryId.isNotEmpty) {
      cards.add(
        EntityLinkCard<ExpenseCategory>(
          titleKey: 'category',
          icon: Icons.label_outline,
          entityId: e.categoryId,
          routePath: '/settings/expense_categories/${e.categoryId}',
          permissionKey: 'view_expense',
          watchBuilder: () => context.read<Services>().expenseCategories.watch(
            companyId: companyId,
            id: e.categoryId,
          ),
          displayNameOf: (c) => c.name.isEmpty ? e.categoryId : c.name,
        ),
      );
    }
    if (_hasAnyCustomValue(e)) {
      cards.add(
        _CustomFieldsCard(
          recurringExpense: e,
          companyId: companyId,
          formatter: formatter,
        ),
      );
    }
    return cards;
  }

  Widget _stack(BuildContext context, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(height: InSpacing.lg(context)),
          cards[i],
        ],
      ],
    );
  }
}

bool _hasAnyTax(RecurringExpense e) =>
    e.taxAmount1 != Decimal.zero ||
    e.taxAmount2 != Decimal.zero ||
    e.taxAmount3 != Decimal.zero ||
    e.taxRate1 != Decimal.zero ||
    e.taxRate2 != Decimal.zero ||
    e.taxRate3 != Decimal.zero;

bool _hasAnyCustomValue(RecurringExpense e) =>
    e.customValue1.isNotEmpty ||
    e.customValue2.isNotEmpty ||
    e.customValue3.isNotEmpty ||
    e.customValue4.isNotEmpty;

bool _hasAnyNote(RecurringExpense e) =>
    e.publicNotes.isNotEmpty || e.privateNotes.isNotEmpty;

// The KPI strip already surfaces frequency + next_send_date — Schedule only
// earns a card if it adds something beyond those two facts.
bool _hasScheduleDetail(RecurringExpense e) =>
    e.lastSentDate != null ||
    e.remainingCycles != -1 ||
    e.recurringDates.any((r) => r.sendDate != null);

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    // Tighten the label column on narrow phones so the value keeps a usable
    // width (a fixed 160px would eat ~half a 360px screen).
    final labelWidth = MediaQuery.sizeOf(context).width < 480 ? 100.0 : 160.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
  const _SummaryCard({required this.recurringExpense, required this.formatter});
  final RecurringExpense recurringExpense;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final e = recurringExpense;
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
            value: RecurringExpenseStatusPill(statusId: e.calculatedStatusId),
          ),
          _Row(
            label: context.tr('number'),
            value: Text(e.number.isEmpty ? '—' : e.number),
          ),
          _Row(label: context.tr('date'), value: Text(dateText)),
          _Row(label: context.tr('amount'), value: Text(amountText)),
          if (e.taxAmountSum != Decimal.zero)
            _Row(label: context.tr('gross_amount'), value: Text(grossText)),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.recurringExpense});
  final RecurringExpense recurringExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final hasPrivate = recurringExpense.privateNotes.isNotEmpty;
    final hasPublic = recurringExpense.publicNotes.isNotEmpty;
    return DashboardCardShell(
      title: context.tr('notes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPrivate)
            _NotesBlock(
              label: context.tr('private_notes'),
              body: recurringExpense.privateNotes,
              labelColor: tokens.ink3,
              bodyStyle: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.ink,
              ),
            ),
          if (hasPrivate && hasPublic) ...[
            SizedBox(height: InSpacing.md(context)),
            Divider(height: 1, thickness: 1, color: tokens.border),
            SizedBox(height: InSpacing.md(context)),
          ],
          if (hasPublic)
            _NotesBlock(
              label: context.tr('public_notes'),
              body: recurringExpense.publicNotes,
              labelColor: tokens.ink3,
              bodyStyle: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.ink,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  const _NotesBlock({
    required this.label,
    required this.body,
    required this.labelColor,
    required this.bodyStyle,
  });

  final String label;
  final String body;
  final Color labelColor;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: InSpacing.xs),
        Text(body, style: bodyStyle),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.recurringExpense,
    required this.formatter,
  });
  final RecurringExpense recurringExpense;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final e = recurringExpense;
    final f = formatter;
    String renderDate(Date? value) {
      if (value == null) return '—';
      return f == null ? value.toIso() : f.date(value.toIso());
    }

    final cyclesLabel = e.remainingCycles == -1
        ? context.tr('endless')
        : '${e.remainingCycles}';

    final upcoming = e.recurringDates
        .where((r) => r.sendDate != null)
        .take(3)
        .map((r) => renderDate(r.sendDate))
        .toList(growable: false);

    return DashboardCardShell(
      title: context.tr('schedule'),
      child: Column(
        children: [
          if (e.lastSentDate != null)
            _Row(
              label: context.tr('last_sent_date'),
              value: Text(renderDate(e.lastSentDate)),
            ),
          _Row(label: context.tr('remaining_cycles'), value: Text(cyclesLabel)),
          if (upcoming.isNotEmpty)
            _Row(
              label: context.tr('upcoming'),
              value: Text(upcoming.join(', ')),
            ),
        ],
      ),
    );
  }
}

class _TaxBreakdownCard extends StatelessWidget {
  const _TaxBreakdownCard({
    required this.recurringExpense,
    required this.formatter,
  });
  final RecurringExpense recurringExpense;
  final Formatter? formatter;

  String _fmt(Decimal amount) {
    final f = formatter;
    if (f == null) return amount.toString();
    return f.money(amount, clientCurrencyId: recurringExpense.currencyId);
  }

  @override
  Widget build(BuildContext context) {
    final e = recurringExpense;
    return DashboardCardShell(
      title: context.tr('tax_breakdown'),
      child: Column(
        children: [
          if (e.taxName1.isNotEmpty || e.taxRate1 != Decimal.zero)
            _Row(
              label: e.taxName1.isEmpty ? context.tr('tax_rate1') : e.taxName1,
              value: Text('${e.taxRate1}% · ${_fmt(e.taxAmount1Computed)}'),
            ),
          if (e.taxName2.isNotEmpty || e.taxRate2 != Decimal.zero)
            _Row(
              label: e.taxName2.isEmpty ? context.tr('tax_rate2') : e.taxName2,
              value: Text('${e.taxRate2}% · ${_fmt(e.taxAmount2Computed)}'),
            ),
          if (e.taxName3.isNotEmpty || e.taxRate3 != Decimal.zero)
            _Row(
              label: e.taxName3.isEmpty ? context.tr('tax_rate3') : e.taxName3,
              value: Text('${e.taxRate3}% · ${_fmt(e.taxAmount3Computed)}'),
            ),
          _Row(
            label: context.tr('inclusive_taxes'),
            value: Text(
              e.usesInclusiveTaxes ? context.tr('yes') : context.tr('no'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomFieldsCard extends StatelessWidget {
  const _CustomFieldsCard({
    required this.recurringExpense,
    required this.companyId,
    this.formatter,
  });
  final RecurringExpense recurringExpense;
  final String companyId;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final e = recurringExpense;
    final yes = context.tr('yes');
    final no = context.tr('no');
    return StreamBuilder<Company?>(
      stream: context.read<Services>().company.watchCompany(companyId),
      builder: (context, snapshot) {
        final rows = customFieldDetailRows(
          company: snapshot.data,
          // Recurring expenses reuse the expense custom fields.
          prefix: 'expense',
          values: [
            e.customValue1,
            e.customValue2,
            e.customValue3,
            e.customValue4,
          ],
          formatter: formatter,
          yes: yes,
          no: no,
        );
        if (rows.isEmpty) return const SizedBox.shrink();
        return DashboardCardShell(
          title: context.tr('custom_fields'),
          child: Column(
            children: [
              for (final r in rows) _Row(label: r.label, value: Text(r.value)),
            ],
          ),
        );
      },
    );
  }
}
