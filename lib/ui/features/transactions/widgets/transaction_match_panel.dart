import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/transactions/widgets/multi_pick_sheet.dart';

/// Match panel for an unmatched/matched bank transaction. Two tabs:
///   * **Create** — turn the transaction into a new payment (CREDIT) /
///     expense (DEBIT) by picking the linked entities.
///   * **Link** — attach to an existing payment / expense.
///
/// CREDIT-Link is degraded today (no PaymentRepository in this rebuild
/// yet): the tab renders an inline placeholder until the entity lands.
/// Everything else routes through the existing
/// `BankTransactionRepository.matchTo* / linkTo*` helpers — which already
/// enqueue the correct outbox rows with the right wire payloads.
class TransactionMatchPanel extends StatefulWidget {
  const TransactionMatchPanel({super.key, required this.transaction});

  final BankTransaction transaction;

  @override
  State<TransactionMatchPanel> createState() => _TransactionMatchPanelState();
}

class _TransactionMatchPanelState extends State<TransactionMatchPanel> {
  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final createLabelKey = tx.isDeposit ? 'create_payment' : 'create_expense';
    final linkLabelKey = tx.isDeposit ? 'link_payment' : 'link_expense';
    return EntityDetailTabs(
      tabs: [
        EntityDetailTab(
          label: context.tr(createLabelKey),
          icon: Icons.add_circle_outline,
          bodyBuilder: (ctx) => Padding(
            padding: const EdgeInsets.all(16),
            child: tx.isDeposit
                ? _CreditCreateTab(transaction: tx)
                : _DebitCreateTab(transaction: tx),
          ),
        ),
        EntityDetailTab(
          label: context.tr(linkLabelKey),
          icon: Icons.link_outlined,
          bodyBuilder: (ctx) => Padding(
            padding: const EdgeInsets.all(16),
            child: tx.isDeposit
                ? const _CreditLinkPlaceholder()
                : _DebitLinkTab(transaction: tx),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// CREDIT — Create Payment (pick client → multi-pick invoices)
// ──────────────────────────────────────────────────────────────────────

class _CreditCreateTab extends StatefulWidget {
  const _CreditCreateTab({required this.transaction});
  final BankTransaction transaction;

  @override
  State<_CreditCreateTab> createState() => _CreditCreateTabState();
}

class _CreditCreateTabState extends State<_CreditCreateTab> {
  Client? _selectedClient;
  List<Invoice> _selectableInvoices = const <Invoice>[];
  Set<String> _selectedInvoiceIds = <String>{};
  bool _submitting = false;
  StreamSubscription<List<Invoice>>? _invoiceSub;

  @override
  void dispose() {
    _invoiceSub?.cancel();
    super.dispose();
  }

  void _bindInvoices(Client? client) {
    _invoiceSub?.cancel();
    if (client == null) {
      setState(() {
        _selectableInvoices = const <Invoice>[];
        _selectedInvoiceIds = <String>{};
      });
      return;
    }
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    _invoiceSub = services.invoices
        .watchForClient(companyId: companyId, clientId: client.id)
        .listen((list) {
      if (!mounted) return;
      // Filter to unpaid, non-deleted, non-archived invoices with a
      // positive balance — the only ones a payment could plausibly match.
      final unpaid = list
          .where(
            (i) =>
                !i.isDeleted &&
                i.archivedAt == null &&
                i.balance > Decimal.zero,
          )
          .toList(growable: false);
      setState(() {
        _selectableInvoices = unpaid;
        _selectedInvoiceIds = _selectedInvoiceIds
            .where((id) => unpaid.any((inv) => inv.id == id))
            .toSet();
      });
    });
  }

  Decimal get _selectedTotal {
    var total = Decimal.zero;
    for (final inv in _selectableInvoices) {
      if (_selectedInvoiceIds.contains(inv.id)) total += inv.balance;
    }
    return total;
  }

  Future<void> _pickInvoices(BuildContext context) async {
    final picked = await showMultiPickSheet<Invoice>(
      context: context,
      title: context.tr('select_invoices'),
      items: _selectableInvoices,
      idOf: (i) => i.id,
      displayString: (i) => i.number.isEmpty ? i.id : '#${i.number}',
      subtitleOf: (i) => i.balance.toStringAsFixed(2),
      amountOf: (i) => i.balance,
      initialSelected: _selectedInvoiceIds.toList(),
    );
    if (picked != null) {
      setState(() => _selectedInvoiceIds = picked.toSet());
    }
  }

  Future<void> _submit() async {
    if (_selectedInvoiceIds.isEmpty) return;
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    setState(() => _submitting = true);
    try {
      await services.bankTransactions.matchToPayment(
        companyId: companyId,
        transactionId: widget.transaction.id,
        invoiceIds: _selectedInvoiceIds.toList(),
      );
      // Custom-action dispatchers don't apply server response → refresh.
      unawaited(services.bankTransactions.refreshAll(companyId: companyId));
      if (!mounted) return;
      Notify.success(context, context.tr('created_payment'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final tokens = context.inTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<List<Client>>(
          stream: services.clients.watchPage(
            companyId: companyId,
            loadedPages: 10,
          ),
          builder: (context, snapshot) {
            final clients = snapshot.data ?? const <Client>[];
            return SearchableDropdownField<Client>(
              label: context.tr('client'),
              items: clients,
              initialValue: _selectedClient,
              idOf: (c) => c.id,
              displayString: (c) =>
                  c.displayName.isEmpty ? c.id : c.displayName,
              onChanged: (c) {
                setState(() => _selectedClient = c);
                _bindInvoices(c);
              },
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 44),
          ),
          icon: const Icon(Icons.checklist, size: 18),
          label: Text(
            _selectedInvoiceIds.isEmpty
                ? context.tr('select_invoices')
                : context.tr('n_selected', {
                    'count': _selectedInvoiceIds.length.toString(),
                  }),
          ),
          onPressed: _selectedClient == null
              ? null
              : () => _pickInvoices(context),
        ),
        if (_selectedInvoiceIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(context.tr('calculate_total'), style: TextStyle(color: tokens.ink2)),
              const Spacer(),
              Text(
                _selectedTotal.toStringAsFixed(2),
                style: TextStyle(
                  color: tokens.ink,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
              icon: const Icon(Icons.check, size: 18),
              label: Text(context.tr('create_payment')),
              onPressed: _submitting || _selectedInvoiceIds.isEmpty
                  ? null
                  : _submit,
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// CREDIT — Link Payment (deferred — no PaymentRepository)
// ──────────────────────────────────────────────────────────────────────

class _CreditLinkPlaceholder extends StatelessWidget {
  const _CreditLinkPlaceholder();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hourglass_empty, color: tokens.ink3, size: 32),
        const SizedBox(height: 12),
        Text(
          context.tr('payments_coming_soon'),
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.ink2),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// DEBIT — Create Expense (vendor + category single-select pickers)
// ──────────────────────────────────────────────────────────────────────

class _DebitCreateTab extends StatefulWidget {
  const _DebitCreateTab({required this.transaction});
  final BankTransaction transaction;

  @override
  State<_DebitCreateTab> createState() => _DebitCreateTabState();
}

class _DebitCreateTabState extends State<_DebitCreateTab> {
  Vendor? _selectedVendor;
  ExpenseCategory? _selectedCategory;
  bool _submitting = false;
  bool _seededFromRule = false;

  /// Pre-fill from the matched transaction rule (if any). The rule already
  /// carries `vendorId` / `categoryId` server-side; resolve through the
  /// local repos so the user lands on a one-tap confirm.
  void _seedFromRuleIfApplicable() {
    if (_seededFromRule || widget.transaction.transactionRuleId.isEmpty) {
      return;
    }
    _seededFromRule = true;
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    services.transactionRules
        .watch(companyId: companyId, id: widget.transaction.transactionRuleId)
        .first
        .then((rule) async {
      if (!mounted || rule == null) return;
      if (rule.vendorId.isNotEmpty) {
        final vendor = await services.vendors
            .watch(companyId: companyId, id: rule.vendorId)
            .first;
        if (mounted && vendor != null && _selectedVendor == null) {
          setState(() => _selectedVendor = vendor);
        }
      }
      if (rule.categoryId.isNotEmpty) {
        final cat = await services.expenseCategories
            .watch(companyId: companyId, id: rule.categoryId)
            .first;
        if (mounted && cat != null && _selectedCategory == null) {
          setState(() => _selectedCategory = cat);
        }
      }
    });
  }

  Future<void> _submit() async {
    final vendor = _selectedVendor;
    final cat = _selectedCategory;
    if (vendor == null && cat == null) return;
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    setState(() => _submitting = true);
    try {
      await services.bankTransactions.matchToExpense(
        companyId: companyId,
        transactionId: widget.transaction.id,
        vendorId: vendor?.id ?? '',
        categoryId: cat?.id ?? '',
      );
      unawaited(services.bankTransactions.refreshAll(companyId: companyId));
      if (!mounted) return;
      Notify.success(context, context.tr('created_expense'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _seedFromRuleIfApplicable();
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<List<Vendor>>(
          stream: services.vendors.watchPage(
            companyId: companyId,
            loadedPages: 10,
          ),
          builder: (context, snapshot) {
            final vendors = snapshot.data ?? const <Vendor>[];
            return SearchableDropdownField<Vendor>(
              label: context.tr('vendor'),
              items: vendors,
              initialValue: _selectedVendor,
              idOf: (v) => v.id,
              displayString: (v) => v.name.isEmpty ? v.id : v.name,
              onChanged: (v) => setState(() => _selectedVendor = v),
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ExpenseCategory>>(
          stream: services.expenseCategories.watchActive(companyId: companyId),
          builder: (context, snapshot) {
            final cats = snapshot.data ?? const <ExpenseCategory>[];
            return SearchableDropdownField<ExpenseCategory>(
              label: context.tr('category'),
              items: cats,
              initialValue: _selectedCategory,
              idOf: (c) => c.id,
              displayString: (c) => c.name.isEmpty ? c.id : c.name,
              onChanged: (c) => setState(() => _selectedCategory = c),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
              icon: const Icon(Icons.check, size: 18),
              label: Text(context.tr('create_expense')),
              onPressed: _submitting ||
                      (_selectedVendor == null && _selectedCategory == null)
                  ? null
                  : _submit,
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// DEBIT — Link Expense (multi-pick unmatched expenses)
// ──────────────────────────────────────────────────────────────────────

class _DebitLinkTab extends StatefulWidget {
  const _DebitLinkTab({required this.transaction});
  final BankTransaction transaction;

  @override
  State<_DebitLinkTab> createState() => _DebitLinkTabState();
}

class _DebitLinkTabState extends State<_DebitLinkTab> {
  Set<String> _selectedExpenseIds = <String>{};
  bool _submitting = false;

  Future<void> _pickExpenses(BuildContext context) async {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    // Watch one page of active expenses; filter to rows that aren't
    // already linked to an invoice (a rough "unmatched" proxy until the
    // server exposes a dedicated filter).
    final expenses = await services.expenses
        .watchPage(
          companyId: companyId,
          loadedPages: 4,
          states: const {EntityState.active},
        )
        .first;
    final candidates = expenses
        .where((e) => e.invoiceId.isEmpty && !e.isDeleted)
        .toList(growable: false);
    if (!context.mounted) return;
    final picked = await showMultiPickSheet<Expense>(
      context: context,
      title: context.tr('select_expenses'),
      items: candidates,
      idOf: (e) => e.id,
      displayString: (e) => e.number.isEmpty ? e.id : '#${e.number}',
      subtitleOf: (e) =>
          '${e.amount.toStringAsFixed(2)} ${e.currencyId.isEmpty ? '' : '(${e.currencyId})'}',
      amountOf: (e) => e.amount,
      currencyOf: (e) => e.currencyId,
      initialSelected: _selectedExpenseIds.toList(),
      addSelectAllButton: true,
    );
    if (picked != null) {
      setState(() => _selectedExpenseIds = picked.toSet());
    }
  }

  Future<void> _submit() async {
    if (_selectedExpenseIds.isEmpty) return;
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    setState(() => _submitting = true);
    try {
      // The `match` endpoint takes one expense_id per `transactions`
      // entry, so we loop and enqueue N mutations rather than a single
      // bulk call. Each row hits the same outbox pipeline.
      for (final id in _selectedExpenseIds) {
        await services.bankTransactions.linkToExpense(
          companyId: companyId,
          transactionId: widget.transaction.id,
          expenseId: id,
        );
      }
      unawaited(services.bankTransactions.refreshAll(companyId: companyId));
      if (!mounted) return;
      Notify.success(context, context.tr('linked_expense'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 44),
          ),
          icon: const Icon(Icons.checklist, size: 18),
          label: Text(
            _selectedExpenseIds.isEmpty
                ? context.tr('select_expenses')
                : context.tr('n_selected', {
                    'count': _selectedExpenseIds.length.toString(),
                  }),
          ),
          onPressed: () => _pickExpenses(context),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
              icon: const Icon(Icons.link, size: 18),
              label: Text(context.tr('link_expense')),
              onPressed: _submitting || _selectedExpenseIds.isEmpty
                  ? null
                  : _submit,
            ),
          ],
        ),
      ],
    );
  }
}
