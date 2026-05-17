import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/invoice_status.dart';
import 'package:admin/data/models/domain/schedule_constants.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';

/// Invoice detail → Payment Schedule tab. Mirrors React: the schedule is a
/// read-only projection embedded on the invoice (`invoice.schedule[]`,
/// populated only by a `?show_schedule=true` fetch — handled by
/// `InvoiceRepository.ensureLoaded`). Create/remove go through the outbox
/// to React's bespoke `/invoices/:id/payment_schedule` endpoints; the
/// dispatcher re-fetches the invoice so this list refreshes.

/// React `useTabs.tsx`: tab available on Draft / Sent, or Partial when the
/// user can view/edit the invoice. (`canViewOrEdit` resolved at the call
/// site from company permissions.)
bool invoiceSupportsPaymentSchedule(
  Invoice i, {
  required bool canViewOrEdit,
}) {
  if (i.isDeleted) return false;
  return i.statusId == InvoiceStatus.draft ||
      i.statusId == InvoiceStatus.sent ||
      (i.statusId == InvoiceStatus.partial && canViewOrEdit);
}

class InvoicePaymentScheduleTab extends StatelessWidget {
  const InvoicePaymentScheduleTab({required this.invoice, super.key});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final isTmp = invoice.id.startsWith('tmp_');
    final rows = invoice.schedule;

    if (rows.isEmpty) {
      return EmptyState(
        icon: Icons.event_repeat_outlined,
        title: context.tr('no_payment_schedule'),
        subtitle: isTmp ? context.tr('sync_first') : null,
        action: isTmp
            ? null
            : FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 44),
                ),
                icon: const Icon(Icons.add),
                label: Text(context.tr('create_payment_schedule')),
                onPressed: () => _showCreateDialog(context, invoice),
              ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('payment_schedule'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                icon: Icon(Icons.delete_outline, color: tokens.overdue),
                label: Text(
                  context.tr('remove'),
                  style: TextStyle(color: tokens.overdue),
                ),
                onPressed: () => _remove(context, invoice),
              ),
            ],
          ),
          SizedBox(height: InSpacing.md(context)),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(r.date)),
                  Text(
                    r.amount,
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(width: InSpacing.md(context)),
                  Icon(
                    r.autoBill
                        ? Icons.bolt
                        : Icons.bolt_outlined,
                    size: 16,
                    color: r.autoBill ? tokens.accent : tokens.ink3,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, Invoice invoice) async {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('remove')),
        content: Text(ctx.tr('are_you_sure')),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(ctx.tr('cancel')),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 44),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(ctx.tr('remove')),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await runMutationWithNotify(
      context,
      () => services.invoices.deletePaymentSchedule(
        companyId: companyId,
        id: invoice.id,
      ),
      successMsg: context.tr('deleted_schedule'),
    );
  }
}

Future<void> _showCreateDialog(BuildContext context, Invoice invoice) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CreatePaymentScheduleDialog(invoice: invoice),
  );
}

/// Number-of-payments flow (React's primary path): count + frequency +
/// first-payment date + auto-bill → `POST /invoices/:id/payment_schedule`.
class _CreatePaymentScheduleDialog extends StatefulWidget {
  const _CreatePaymentScheduleDialog({required this.invoice});

  final Invoice invoice;

  @override
  State<_CreatePaymentScheduleDialog> createState() =>
      _CreatePaymentScheduleDialogState();
}

class _CreatePaymentScheduleDialogState
    extends State<_CreatePaymentScheduleDialog> {
  final _count = TextEditingController(text: '2');
  String _frequencyId = '5'; // monthly
  DateTime? _firstPayment;
  bool _autoBill = false;
  bool _busy = false;

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  bool get _valid =>
      (int.tryParse(_count.text.trim()) ?? 0) >= 1 && _firstPayment != null;

  Future<void> _submit() async {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final first = _firstPayment!;
    final body = <String, dynamic>{
      'template': kScheduleTemplatePaymentSchedule,
      'next_run': Date(first.year, first.month, first.day).toIso(),
      'remaining_cycles': int.parse(_count.text.trim()),
      'frequency_id': _frequencyId,
      'parameters': <String, dynamic>{
        'invoice_id': widget.invoice.id,
        'auto_bill': _autoBill,
        'schedule': <dynamic>[],
      },
    };
    setState(() => _busy = true);
    await runMutationWithNotify(
      context,
      () => services.invoices.createPaymentSchedule(
        companyId: companyId,
        id: widget.invoice.id,
        body: body,
      ),
      successMsg: context.tr('created_schedule'),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('create_payment_schedule')),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _count,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr('number_of_payments'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequencyId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr('frequency'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _frequencyId = v ?? _frequencyId),
              items: [
                for (final e in kScheduleFrequencies.entries)
                  DropdownMenuItem(
                    value: e.key,
                    child: Text(context.tr(e.value)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            InDateField(
              value: _firstPayment,
              labelText: context.tr('first_payment_date'),
              onChanged: (d) => setState(() => _firstPayment = d),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _autoBill,
              onChanged: (v) => setState(() => _autoBill = v),
              title: Text(context.tr('auto_bill')),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 40),
              ),
              onPressed:
                  _busy ? null : () => Navigator.of(context).pop(),
              child: Text(context.tr('cancel')),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
              onPressed: (_busy || !_valid) ? null : _submit,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.tr('create_payment_schedule')),
            ),
          ],
        ),
      ],
    );
  }
}
