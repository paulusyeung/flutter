import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/billing_shared/ledger/ledger_entry.dart';
import 'package:admin/utils/formatting.dart';

/// Whether this is a client receivables ledger or a vendor spend ledger —
/// picks the data sources, filter chips, and tap-through targets.
enum LedgerScope { client, vendor }

/// Chronological account statement for a client or vendor with a running
/// balance column + per-kind filter chips. Composes the per-entity Drift
/// watch streams (no new endpoint, offline-capable) through the pure
/// [buildClientLedger] / [buildVendorLedger] reducers.
///
/// Renders as a plain `Column` (no inner scroll) so it grows with the detail
/// page's [DetailScrollScope], matching the other custom detail tabs.
class LedgerTab extends StatefulWidget {
  const LedgerTab({
    super.key,
    required this.scope,
    required this.companyId,
    required this.entityId,
    required this.formatter,
  });

  final LedgerScope scope;
  final String companyId;
  final String entityId;
  final Formatter? formatter;

  @override
  State<LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends State<LedgerTab> {
  /// Empty = show every kind. A non-empty set narrows the visible rows;
  /// running balances are unaffected (computed over the full ledger).
  final Set<LedgerKind> _active = <LedgerKind>{};

  List<LedgerKind> get _kinds => widget.scope == LedgerScope.client
      ? const [LedgerKind.invoice, LedgerKind.payment, LedgerKind.credit]
      : const [LedgerKind.expense, LedgerKind.purchaseOrder];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.lg(context)),
      child: _LedgerStreams(
        scope: widget.scope,
        companyId: widget.companyId,
        entityId: widget.entityId,
        builder: (context, entries, loading) =>
            _content(context, entries, loading),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    List<LedgerEntry> entries,
    bool loading,
  ) {
    final tokens = context.inTheme;
    final visible = _active.isEmpty
        ? entries
        : entries.where((e) => _active.contains(e.kind)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: InSpacing.sm,
          runSpacing: InSpacing.sm,
          children: [
            for (final k in _kinds)
              FilterChip(
                label: Text(context.tr(_kindLabelKey(k))),
                selected: _active.contains(k),
                onSelected: (sel) => setState(() {
                  if (sel) {
                    _active.add(k);
                  } else {
                    _active.remove(k);
                  }
                }),
              ),
          ],
        ),
        SizedBox(height: InSpacing.md(context)),
        if (loading && entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (visible.isEmpty)
          EmptyState(
            icon: Icons.account_balance_outlined,
            title: context.tr('no_records_found'),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < visible.length; i++)
                _LedgerRow(
                  entry: visible[i],
                  formatter: widget.formatter,
                  tokens: tokens,
                  isLast: i == visible.length - 1,
                ),
            ],
          ),
      ],
    );
  }
}

String _kindLabelKey(LedgerKind k) => switch (k) {
      LedgerKind.invoice => 'invoices',
      LedgerKind.payment => 'payments',
      LedgerKind.credit => 'credits',
      LedgerKind.expense => 'expenses',
      LedgerKind.purchaseOrder => 'purchase_orders',
    };

IconData _kindIcon(LedgerKind k) => switch (k) {
      LedgerKind.invoice => Icons.receipt_long_outlined,
      LedgerKind.payment => Icons.payments_outlined,
      LedgerKind.credit => Icons.credit_card_outlined,
      LedgerKind.expense => Icons.account_balance_wallet_outlined,
      LedgerKind.purchaseOrder => Icons.shopping_bag_outlined,
    };

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.entry,
    required this.formatter,
    required this.tokens,
    required this.isLast,
  });

  final LedgerEntry entry;
  final Formatter? formatter;
  final InTheme tokens;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final f = formatter;
    final isDebit = entry.adjustment > Decimal.zero;
    final amountColor = isDebit ? tokens.overdue : tokens.paid;
    final dateStr =
        entry.date == null ? '' : (f?.date(entry.date!.toIso()) ?? '');
    final label = entry.number.isEmpty
        ? context.tr(_kindLabelKey(entry.kind))
        : '${context.tr(entry.kind.name)} #${entry.number}';
    return InkWell(
      onTap: () => goEntityRecord(context, entry.kind.entityType, entry.id),
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: tokens.border)),
        ),
        padding: EdgeInsets.symmetric(
          vertical: InSpacing.md(context),
          horizontal: 4,
        ),
        child: Row(
          children: [
            Icon(_kindIcon(entry.kind), size: 20, color: tokens.ink3),
            SizedBox(width: InSpacing.md(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (dateStr.isNotEmpty)
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 12, color: tokens.ink3),
                    ),
                ],
              ),
            ),
            SizedBox(width: InSpacing.md(context)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  f == null ? '' : f.money(entry.adjustment),
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  f == null ? '' : f.money(entry.runningBalance),
                  style: TextStyle(fontSize: 12, color: tokens.ink3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Subscribes to the per-entity Drift watch streams for the scope and feeds
/// the latest snapshot through the pure ledger reducers. Nested
/// `StreamBuilder`s (no rxdart in the project); the reducers are cheap and
/// the lists are entity-scoped (small).
///
/// Stateful so the watch streams are created **once** (and only re-created
/// when scope/company/entity actually change) — otherwise every parent
/// `setState` (a filter-chip tap) would rebuild the `StreamBuilder`s with
/// fresh stream objects and needlessly re-subscribe 2–3 Drift queries.
class _LedgerStreams extends StatefulWidget {
  const _LedgerStreams({
    required this.scope,
    required this.companyId,
    required this.entityId,
    required this.builder,
  });

  final LedgerScope scope;
  final String companyId;
  final String entityId;
  final Widget Function(
    BuildContext context,
    List<LedgerEntry> entries,
    bool loading,
  ) builder;

  @override
  State<_LedgerStreams> createState() => _LedgerStreamsState();
}

class _LedgerStreamsState extends State<_LedgerStreams> {
  Stream<List<Invoice>>? _invoices;
  Stream<List<Payment>>? _payments;
  Stream<List<Credit>>? _credits;
  Stream<List<Expense>>? _expenses;
  Stream<List<PurchaseOrder>>? _purchaseOrders;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(_LedgerStreams old) {
    super.didUpdateWidget(old);
    if (old.scope != widget.scope ||
        old.companyId != widget.companyId ||
        old.entityId != widget.entityId) {
      _bind();
    }
  }

  void _bind() {
    final s = context.read<Services>();
    if (widget.scope == LedgerScope.client) {
      _invoices = s.invoices.watchForClient(
        companyId: widget.companyId,
        clientId: widget.entityId,
      );
      _payments = s.payments.watchForClient(
        companyId: widget.companyId,
        clientId: widget.entityId,
      );
      _credits = s.credits.watchForClient(
        companyId: widget.companyId,
        clientId: widget.entityId,
      );
      _expenses = null;
      _purchaseOrders = null;
    } else {
      _expenses = s.expenses.watchForVendor(
        companyId: widget.companyId,
        vendorId: widget.entityId,
      );
      _purchaseOrders = s.purchaseOrders.watchForVendor(
        companyId: widget.companyId,
        vendorId: widget.entityId,
      );
      _invoices = null;
      _payments = null;
      _credits = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scope == LedgerScope.client) {
      return StreamBuilder<List<Invoice>>(
        stream: _invoices,
        builder: (context, inv) => StreamBuilder<List<Payment>>(
          stream: _payments,
          builder: (context, pay) => StreamBuilder<List<Credit>>(
            stream: _credits,
            builder: (context, cred) {
              final loading = !inv.hasData || !pay.hasData || !cred.hasData;
              final entries = buildClientLedger(
                invoices: inv.data ?? const [],
                payments: pay.data ?? const [],
                credits: cred.data ?? const [],
              );
              return widget.builder(context, entries, loading);
            },
          ),
        ),
      );
    }
    return StreamBuilder<List<Expense>>(
      stream: _expenses,
      builder: (context, exp) => StreamBuilder<List<PurchaseOrder>>(
        stream: _purchaseOrders,
        builder: (context, po) {
          final loading = !exp.hasData || !po.hasData;
          final entries = buildVendorLedger(
            expenses: exp.data ?? const [],
            purchaseOrders: po.data ?? const [],
          );
          return widget.builder(context, entries, loading);
        },
      ),
    );
  }
}
