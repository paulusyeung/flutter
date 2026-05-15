import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/invoice_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/email/billing_doc_email_sheet.dart';
import 'package:admin/ui/features/invoices/widgets/detail/mark_paid_confirm_dialog.dart';

/// Action set surfaced for an invoice.
///
/// M1 wired edit / clone / archive / restore / delete / purge.
/// M2 wires viewPdf / downloadPdf / printPdf / sendEmail / scheduleEmail /
/// markSent / markPaid / autoBill / cancel (all enqueue outbox rows).
/// M3 adds clone-to-quote/credit/recurring/po + runTemplate.
enum InvoiceAction {
  edit,
  viewPdf,
  downloadPdf,
  printPdf,
  sendEmail,
  scheduleEmail,
  markSent,
  markPaid,
  autoBill,
  enterPayment,
  clone,
  cloneToQuote,
  cloneToCredit,
  cloneToRecurring,
  cloneToPurchaseOrder,
  runTemplate,
  cancel,
  addComment,
  archive,
  restore,
  delete,
  purge,
}

class InvoiceActions {
  InvoiceActions._();

  static List<EntityActionItem<InvoiceAction>> itemsFor(
    BuildContext context,
    Invoice invoice,
    void Function(InvoiceAction) onTap,
  ) {
    final canArchive = invoice.archivedAt == null && !invoice.isDeleted;
    final canRestore = invoice.archivedAt != null || invoice.isDeleted;
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canPurge = (me?.isAdmin ?? false) || (me?.isOwner ?? false);
    final isLocked = invoice.isLocked;
    // Send → only meaningful for non-cancelled/non-reversed invoices.
    final canEmail = !invoice.isCancelled && !invoice.isReversed;
    // Mark sent → only from Draft.
    final canMarkSent = invoice.isDraft && !isLocked;
    // Mark paid → only when there's still a balance.
    final canMarkPaid = !invoice.isPaid && !invoice.isCancelled &&
        !invoice.isReversed;
    // Auto-bill → invoice must be payable + not already paid.
    final canAutoBill = canMarkPaid &&
        invoice.statusId != InvoiceStatus.draft;
    // Cancel → server-side rule: sent invoices only.
    final canCancel = invoice.isSent && !invoice.isCancelled &&
        !invoice.isReversed;

    return [
      editActionItem(
        context: context,
        kind: InvoiceAction.edit,
        onTap: () => onTap(InvoiceAction.edit),
      ),
      EntityActionItem(
        kind: InvoiceAction.viewPdf,
        icon: Icons.picture_as_pdf_outlined,
        label: context.tr('view_pdf'),
        enabled: true,
        onTap: () => onTap(InvoiceAction.viewPdf),
      ),
      EntityActionItem(
        kind: InvoiceAction.downloadPdf,
        icon: Icons.download_outlined,
        label: context.tr('download_pdf'),
        enabled: true,
        onTap: () => onTap(InvoiceAction.downloadPdf),
      ),
      EntityActionItem(
        kind: InvoiceAction.printPdf,
        icon: Icons.print_outlined,
        label: context.tr('print_pdf'),
        enabled: true,
        onTap: () => onTap(InvoiceAction.printPdf),
      ),
      EntityActionItem(
        kind: InvoiceAction.sendEmail,
        icon: Icons.mail_outline,
        label: context.tr('send_email'),
        enabled: canEmail,
        onTap: () => onTap(InvoiceAction.sendEmail),
      ),
      EntityActionItem(
        kind: InvoiceAction.markSent,
        icon: Icons.send_outlined,
        label: context.tr('mark_sent'),
        enabled: canMarkSent,
        onTap: () => onTap(InvoiceAction.markSent),
      ),
      EntityActionItem(
        kind: InvoiceAction.markPaid,
        icon: Icons.payments_outlined,
        label: context.tr('mark_paid'),
        enabled: canMarkPaid && !isLocked,
        onTap: () => onTap(InvoiceAction.markPaid),
      ),
      EntityActionItem(
        kind: InvoiceAction.autoBill,
        icon: Icons.credit_card_outlined,
        label: context.tr('auto_bill'),
        enabled: canAutoBill && !isLocked,
        onTap: () => onTap(InvoiceAction.autoBill),
      ),
      EntityActionItem(
        kind: InvoiceAction.cancel,
        icon: Icons.cancel_outlined,
        label: context.tr('cancel_invoice'),
        enabled: canCancel,
        onTap: () => onTap(InvoiceAction.cancel),
      ),
      EntityActionItem(
        kind: InvoiceAction.clone,
        icon: Icons.copy_outlined,
        label: context.tr('clone_invoice'),
        enabled: true,
        onTap: () => onTap(InvoiceAction.clone),
      ),
      EntityActionItem(
        kind: InvoiceAction.addComment,
        icon: Icons.chat_bubble_outline,
        label: context.tr('add_comment'),
        enabled: true,
        onTap: () => onTap(InvoiceAction.addComment),
      ),
      ?archiveActionItem(
        context: context,
        kind: InvoiceAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(InvoiceAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: InvoiceAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(InvoiceAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: InvoiceAction.delete,
        canDelete: !invoice.isDeleted,
        onTap: () => onTap(InvoiceAction.delete),
      ),
      ?purgeActionItem(
        context: context,
        kind: InvoiceAction.purge,
        canPurge: canPurge,
        onTap: () => onTap(InvoiceAction.purge),
      ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    Invoice invoice,
    InvoiceAction action,
  ) async {
    // Most server-bound actions require a real id. tmp_ rows live only in
    // the outbox until the create round-trips.
    bool tmpGate() {
      if (invoice.id.startsWith('tmp_')) {
        Notify.error(context, context.tr('sync_first'));
        return true;
      }
      return false;
    }

    switch (action) {
      case InvoiceAction.edit:
        context.go('/invoices/${invoice.id}/edit');

      case InvoiceAction.viewPdf:
        if (tmpGate()) return;
        unawaited(context.push('/invoices/${invoice.id}/pdf'));

      case InvoiceAction.downloadPdf:
      case InvoiceAction.printPdf:
        if (tmpGate()) return;
        try {
          final bytes = await services.invoices.api.downloadPdf(
            id: invoice.id,
            designId: invoice.designId.isEmpty ? null : invoice.designId,
          );
          if (!context.mounted) return;
          if (action == InvoiceAction.downloadPdf) {
            final fileName = 'invoice_${invoice.number.isEmpty ? invoice.id : invoice.number}.pdf';
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          } else {
            await Printing.layoutPdf(onLayout: (_) async => bytes);
          }
        } catch (e) {
          if (!context.mounted) return;
          Notify.error(context, '$e');
        }

      case InvoiceAction.sendEmail:
      case InvoiceAction.scheduleEmail:
        if (tmpGate()) return;
        // Formatter wiring lands in M3 alongside the edit screen's
        // per-screen FormatterHostMixin. For M2 the sheet falls back to
        // ISO display in the schedule picker, which is acceptable.
        final result = await showBillingDocEmailSheet(
          context,
          entity: BillingDocType.invoice,
          entityNumber: invoice.number,
          formatter: null,
        );
        if (result == null) return;
        if (result.scheduledFor != null) {
          await services.invoices.scheduleEmail(
            companyId: companyId,
            id: invoice.id,
            template: result.template,
            sendAt: result.scheduledFor!.toUtc().toIso8601String(),
            subject: result.subject.isEmpty ? null : result.subject,
            body: result.body.isEmpty ? null : result.body,
          );
        } else {
          await services.invoices.email(
            companyId: companyId,
            id: invoice.id,
            template: result.template,
            subject: result.subject.isEmpty ? null : result.subject,
            body: result.body.isEmpty ? null : result.body,
            ccEmail: result.ccEmail.isEmpty ? null : result.ccEmail,
          );
        }

      case InvoiceAction.markSent:
        if (tmpGate()) return;
        await services.invoices.markSent(
          companyId: companyId,
          id: invoice.id,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('marked_invoice_as_sent'));

      case InvoiceAction.markPaid:
        if (tmpGate()) return;
        final confirmed = await showMarkPaidConfirmDialog(context);
        if (!confirmed) return;
        await services.invoices.markPaid(
          companyId: companyId,
          id: invoice.id,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('marked_invoice_as_paid'));

      case InvoiceAction.autoBill:
        if (tmpGate()) return;
        await services.invoices.autoBill(
          companyId: companyId,
          id: invoice.id,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('auto_bill_queued'));

      case InvoiceAction.cancel:
        if (tmpGate()) return;
        await services.invoices.cancel(
          companyId: companyId,
          id: invoice.id,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cancelled_invoice'));

      case InvoiceAction.enterPayment:
        if (tmpGate()) return;
        // Defer to the Payments module port. Until then, surface a hint
        // pointing at the existing "Mark paid" affordance.
        Notify.info(context, context.tr('coming_soon'));

      case InvoiceAction.clone:
        final draft = invoice.copyWith(
          id: '',
          number: '',
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          balance: invoice.amount,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        context.go('/invoices/new', extra: draft);

      case InvoiceAction.addComment:
        await _promptAddComment(context, services, companyId, invoice);

      case InvoiceAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'invoice',
          op: () => services.invoices.archive(
            companyId: companyId,
            id: invoice.id,
          ),
        );

      case InvoiceAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'invoice',
          op: () => services.invoices.restore(
            companyId: companyId,
            id: invoice.id,
          ),
        );

      case InvoiceAction.delete:
        if (tmpGate()) return;
        await StandardEntityActions.delete(
          context: context,
          wireName: 'invoice',
          op: () => services.invoices.delete(
            companyId: companyId,
            id: invoice.id,
          ),
        );

      case InvoiceAction.purge:
        if (tmpGate()) return;
        await StandardEntityActions.purge(
          context: context,
          wireName: 'invoice',
          op: () => services.invoices.purge(
            companyId: companyId,
            id: invoice.id,
          ),
        );
        if (context.mounted) context.go('/invoices');

      // M3 destinations — server-side clone endpoints exist but the UI
      // chrome (CloneOptionsSheet) lands later. Render disabled today.
      case InvoiceAction.cloneToQuote:
      case InvoiceAction.cloneToCredit:
      case InvoiceAction.cloneToRecurring:
      case InvoiceAction.cloneToPurchaseOrder:
      case InvoiceAction.runTemplate:
        Notify.info(context, context.tr('coming_soon'));
    }
  }
}

Future<void> _promptAddComment(
  BuildContext context,
  Services services,
  String companyId,
  Invoice invoice,
) async {
  final controller = TextEditingController();
  final text = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(ctx.tr('add_comment')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: ctx.tr('notes')),
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
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(ctx.tr('cancel')),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                onPressed: () =>
                    Navigator.of(ctx).pop(controller.text.trim()),
                child: Text(ctx.tr('save')),
              ),
            ],
          ),
        ],
      );
    },
  );
  if (text == null || text.isEmpty) return;
  await services.invoices.addComment(
    companyId: companyId,
    invoiceId: invoice.id,
    text: text,
  );
}
