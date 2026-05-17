import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/invoice_status.dart';
import 'package:admin/data/models/domain/schedule.dart';
import 'package:admin/data/models/domain/schedule_constants.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';

/// Invoice detail → Payment Schedule tab. A payment schedule is a
/// `Schedule` resource (template `payment_schedule`) bound to the invoice
/// via `parameters.invoice_id`; the server auto-bills installments. v2
/// reuses the entire built Schedule stack (model / `/api/v1/task_schedulers`
/// API / outbox repo / settings editor) — this tab only *views* the
/// invoice-bound schedule and offers create (→ the shared schedule editor,
/// pre-seeded) + remove (delete the Schedule).

/// React parity (`useTabs.tsx`): the tab is available on Draft / Sent /
/// Partial invoices only (not paid / cancelled / reversed). Uses the
/// explicit status enum, NOT `Invoice.isSent` (which is broader).
bool invoiceSupportsPaymentSchedule(Invoice i) =>
    !i.isDeleted &&
    (i.statusId == InvoiceStatus.draft ||
        i.statusId == InvoiceStatus.sent ||
        i.statusId == InvoiceStatus.partial);

/// The (single) payment schedule bound to [invoiceId], or null.
Schedule? paymentScheduleForInvoice(
  List<Schedule> all,
  String invoiceId,
) {
  for (final s in all) {
    if (!s.isDeleted &&
        s.template == kScheduleTemplatePaymentSchedule &&
        s.paymentScheduleInvoiceId == invoiceId) {
      return s;
    }
  }
  return null;
}

class InvoicePaymentScheduleTab extends StatelessWidget {
  const InvoicePaymentScheduleTab({required this.invoice, super.key});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final isTmp = invoice.id.startsWith('tmp_');

    return StreamBuilder<List<Schedule>>(
      stream: services.schedules.watchAll(companyId: companyId),
      builder: (context, snap) {
        final all = snap.data ?? const <Schedule>[];
        final schedule = paymentScheduleForInvoice(all, invoice.id);
        if (schedule == null) {
          return EmptyState(
            icon: Icons.event_repeat_outlined,
            title: context.tr('no_payment_schedule'),
            action: isTmp
                ? null
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 44),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('create_payment_schedule')),
                    onPressed: () => context.go(
                      '/settings/schedules/new'
                      '?starter=$kScheduleTemplatePaymentSchedule'
                      '&invoice_id=${invoice.id}',
                    ),
                  ),
            subtitle: isTmp ? context.tr('sync_first') : null,
          );
        }
        return _ScheduleCard(invoice: invoice, schedule: schedule);
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.invoice, required this.schedule});

  final Invoice invoice;
  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final freqKey = kScheduleFrequencies[schedule.frequencyId];
    final rows = schedule.paymentScheduleRows;
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
                onPressed: () => _remove(context),
              ),
            ],
          ),
          SizedBox(height: InSpacing.md(context)),
          _kv(context, 'frequency',
              freqKey == null ? '—' : context.tr(freqKey)),
          _kv(context, 'auto_bill',
              context.tr(schedule.paymentScheduleAutoBill ? 'enabled' : 'off')),
          if (schedule.remainingCycles >= 0)
            _kv(context, 'remaining_cycles', '${schedule.remainingCycles}'),
          SizedBox(height: InSpacing.md(context)),
          Text(
            context.tr('installments'),
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
          ),
          const SizedBox(height: 4),
          if (rows.isEmpty)
            Text('—', style: TextStyle(color: tokens.ink3))
          else
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(r.date.toIso())),
                    Text(
                      r.isAmount
                          ? r.amount.toString()
                          : '${r.amount}%',
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String labelKey, String value) {
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              context.tr(labelKey),
              style: TextStyle(color: tokens.ink3),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context) async {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final confirmed = await showDialog<bool>(
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
    if (confirmed != true || !context.mounted) return;
    await runMutationWithNotify(
      context,
      () => services.schedules.delete(companyId: companyId, id: schedule.id),
      successMsg: context.tr('deleted_schedule'),
    );
  }
}
