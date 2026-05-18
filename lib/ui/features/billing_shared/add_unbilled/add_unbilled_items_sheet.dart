import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/billing_shared/add_unbilled/unbilled_line_items.dart';
import 'package:admin/utils/formatting.dart';

/// Bottom sheet listing the selected client's not-yet-invoiced tasks +
/// expenses, every row pre-selected with a live running total — the common
/// case ("bill everything") is one tap. Returns the chosen rows already
/// converted to [LineItem]s for the caller to append; `null` on cancel /
/// empty dismiss.
///
/// Fetch path honours the project rule "network writes Drift, UI watches
/// Drift": a one-shot filtered `ensurePageLoaded`
/// (`client_id` + `client_status=uninvoiced`, `ignoreCursor:true` so the
/// browsable list's keyset cursor is untouched) upserts into Drift, then we
/// read the rows back out of Drift and gate locally on `!isInvoiced`.
Future<List<LineItem>?> showAddUnbilledItemsSheet(
  BuildContext context, {
  required String companyId,
  required String clientId,
  Formatter? formatter,
}) {
  return showModalBottomSheet<List<LineItem>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AddUnbilledItemsSheet(
      companyId: companyId,
      clientId: clientId,
      formatter: formatter,
    ),
  );
}

class _AddUnbilledItemsSheet extends StatefulWidget {
  const _AddUnbilledItemsSheet({
    required this.companyId,
    required this.clientId,
    required this.formatter,
  });

  final String companyId;
  final String clientId;
  final Formatter? formatter;

  @override
  State<_AddUnbilledItemsSheet> createState() => _AddUnbilledItemsSheetState();
}

class _AddUnbilledItemsSheetState extends State<_AddUnbilledItemsSheet> {
  bool _loading = true;
  bool _failed = false;
  List<Task> _tasks = const [];
  List<Expense> _expenses = const [];
  final Set<String> _selTasks = <String>{};
  final Set<String> _selExpenses = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = context.read<Services>();
    final filters = <String, Set<String>>{
      'client_id': {widget.clientId},
      'client_status': {'uninvoiced'},
    };
    try {
      await Future.wait([
        services.tasks.ensurePageLoaded(
          companyId: widget.companyId,
          page: 1,
          states: const {EntityState.active},
          extraFilters: filters,
          ignoreCursor: true,
        ),
        services.expenses.ensurePageLoaded(
          companyId: widget.companyId,
          page: 1,
          states: const {EntityState.active},
          extraFilters: filters,
          ignoreCursor: true,
        ),
      ]);
      final tasks = (await services.tasks
              .watchPage(
                companyId: widget.companyId,
                clientId: widget.clientId,
                states: const {EntityState.active},
              )
              .first)
          .where((t) => !t.isInvoiced)
          .toList();
      final expenses = (await services.expenses
              .watchForClient(
                companyId: widget.companyId,
                clientId: widget.clientId,
              )
              .first)
          .where((e) => !e.isInvoiced && !e.isDeleted)
          .toList();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _expenses = expenses;
        _selTasks.addAll(tasks.map((t) => t.id));
        _selExpenses.addAll(expenses.map((e) => e.id));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  List<LineItem> _selectedLineItems() => [
        for (final t in _tasks)
          if (_selTasks.contains(t.id)) taskToLineItem(t),
        for (final e in _expenses)
          if (_selExpenses.contains(e.id)) expenseToLineItem(e),
      ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final selected = _selectedLineItems();
    final count = selected.length;
    final total = selected.fold(
      Decimal.zero,
      (sum, li) => sum + li.gross,
    );
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(InRadii.r3)),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  InSpacing.lg(context),
                  InSpacing.md(context),
                  InSpacing.md(context),
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('add_unbilled_items'),
                        style: TextStyle(
                          color: tokens.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.border),
              Flexible(child: _body(context, tokens)),
              if (!_loading && !_failed && (_tasks.isNotEmpty ||
                  _expenses.isNotEmpty)) ...[
                Divider(height: 1, color: tokens.border),
                Padding(
                  padding: EdgeInsets.all(InSpacing.lg(context)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.formatter == null
                              ? '$count'
                              : '$count · ${widget.formatter!.money(total)}',
                          style: TextStyle(
                            color: tokens.ink2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(64, 40),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.tr('cancel')),
                      ),
                      SizedBox(width: InSpacing.md(context)),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(64, 44),
                        ),
                        onPressed: count == 0
                            ? null
                            : () => Navigator.of(context).pop(selected),
                        child: Text(context.tr('add')),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, InTheme tokens) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Text(
            context.tr('an_error_occurred'),
            style: TextStyle(color: tokens.ink3),
          ),
        ),
      );
    }
    if (_tasks.isEmpty && _expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Text(
            context.tr('no_records_found'),
            style: TextStyle(color: tokens.ink3),
          ),
        ),
      );
    }
    final f = widget.formatter;
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: InSpacing.sm),
      children: [
        if (_tasks.isNotEmpty) ...[
          _SectionHeader(label: context.tr('tasks'), tokens: tokens),
          for (final t in _tasks)
            CheckboxListTile(
              dense: true,
              value: _selTasks.contains(t.id),
              onChanged: (v) => setState(() {
                if (v ?? false) {
                  _selTasks.add(t.id);
                } else {
                  _selTasks.remove(t.id);
                }
              }),
              title: Text(
                t.description.trim().isNotEmpty
                    ? t.description.trim()
                    : (t.number.isNotEmpty
                        ? '#${t.number}'
                        : context.tr('task')),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${taskBillableHours(t)} · '
                '${f == null ? '' : f.money(t.rate)}',
              ),
            ),
        ],
        if (_expenses.isNotEmpty) ...[
          _SectionHeader(label: context.tr('expenses'), tokens: tokens),
          for (final e in _expenses)
            CheckboxListTile(
              dense: true,
              value: _selExpenses.contains(e.id),
              onChanged: (v) => setState(() {
                if (v ?? false) {
                  _selExpenses.add(e.id);
                } else {
                  _selExpenses.remove(e.id);
                }
              }),
              title: Text(
                e.publicNotes.trim().isNotEmpty
                    ? e.publicNotes.trim()
                    : (e.number.isNotEmpty
                        ? '#${e.number}'
                        : context.tr('expense')),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(f == null ? '' : f.money(e.amount)),
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.tokens});
  final String label;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        InSpacing.lg(context),
        InSpacing.md(context),
        InSpacing.lg(context),
        4,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: tokens.ink3,
        ),
      ),
    );
  }
}
