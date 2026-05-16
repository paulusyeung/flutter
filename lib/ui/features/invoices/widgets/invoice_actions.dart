import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/invoice_status.dart';
import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/billing_shared/actions/add_comment_prompt.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/email/billing_doc_email_sheet.dart';
import 'package:admin/ui/features/invoices/widgets/detail/mark_paid_confirm_dialog.dart';
import 'package:admin/ui/features/invoices/widgets/detail/run_template_dialog.dart';
import 'package:admin/ui/features/payments/view_models/payment_edit_view_model.dart';

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
    // Permission gates. Admin / owner bypass `can(...)`; otherwise check
    // the comma-separated `permissions` string. Server enforces too — UI
    // gates just hide affordances the user can't action.
    final canEditInvoice = me?.can('edit_invoice') ?? false;
    final canCreateInvoice = me?.can('create_invoice') ?? false;
    final canDeleteInvoice = me?.can('delete_invoice') ?? false;
    // `isLocked` (Verifactu) prevents *edits* but not status transitions —
    // marking sent / auto-billing a locked invoice is allowed; only
    // `markPaid` is gated because the synthetic payment it records is
    // itself an edit. (R4 fix.)
    final isLocked = invoice.isLocked;
    // Send → only meaningful for non-cancelled/non-reversed invoices.
    final canEmail =
        canEditInvoice && !invoice.isCancelled && !invoice.isReversed;
    // Mark sent → only from Draft.
    final canMarkSent = canEditInvoice && invoice.isDraft;
    // Mark paid → only when there's still a balance.
    final canMarkPaid = canEditInvoice &&
        !invoice.isPaid &&
        !invoice.isCancelled &&
        !invoice.isReversed;
    // Auto-bill → invoice must be payable + not already paid.
    final canAutoBill = canMarkPaid &&
        invoice.statusId != InvoiceStatus.draft;
    // Cancel → server-side rule: sent invoices only.
    final canCancel = canEditInvoice &&
        invoice.isSent &&
        !invoice.isCancelled &&
        !invoice.isReversed;

    return [
      if (canEditInvoice)
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
        enabled: canAutoBill,
        onTap: () => onTap(InvoiceAction.autoBill),
      ),
      EntityActionItem(
        kind: InvoiceAction.cancel,
        icon: Icons.cancel_outlined,
        label: context.tr('cancel_invoice'),
        enabled: canCancel,
        onTap: () => onTap(InvoiceAction.cancel),
      ),
      if (canCreateInvoice) ...[
        EntityActionItem(
          kind: InvoiceAction.clone,
          icon: Icons.copy_outlined,
          label: context.tr('clone_invoice'),
          enabled: true,
          onTap: () => onTap(InvoiceAction.clone),
        ),
        EntityActionItem(
          kind: InvoiceAction.cloneToQuote,
          icon: Icons.request_quote_outlined,
          label: context.tr('clone_to_quote'),
          enabled: true,
          onTap: () => onTap(InvoiceAction.cloneToQuote),
        ),
        EntityActionItem(
          kind: InvoiceAction.cloneToCredit,
          icon: Icons.assignment_return_outlined,
          label: context.tr('clone_to_credit'),
          enabled: true,
          onTap: () => onTap(InvoiceAction.cloneToCredit),
        ),
        EntityActionItem(
          kind: InvoiceAction.cloneToRecurring,
          icon: Icons.event_repeat_outlined,
          label: context.tr('clone_to_recurring'),
          enabled: true,
          onTap: () => onTap(InvoiceAction.cloneToRecurring),
        ),
        EntityActionItem(
          kind: InvoiceAction.cloneToPurchaseOrder,
          icon: Icons.shopping_bag_outlined,
          label: context.tr('clone_to_purchase_order'),
          enabled: true,
          onTap: () => onTap(InvoiceAction.cloneToPurchaseOrder),
        ),
      ],
      if (canEditInvoice) ...[
        EntityActionItem(
          kind: InvoiceAction.runTemplate,
          icon: Icons.auto_awesome_outlined,
          label: context.tr('run_template'),
          enabled: true,
          onTap: () => onTap(InvoiceAction.runTemplate),
        ),
        EntityActionItem(
          kind: InvoiceAction.addComment,
          icon: Icons.chat_bubble_outline,
          label: context.tr('add_comment'),
          enabled: true,
          onTap: () => onTap(InvoiceAction.addComment),
        ),
      ],
      if (canEditInvoice)
        ?archiveActionItem(
          context: context,
          kind: InvoiceAction.archive,
          canArchive: canArchive,
          onTap: () => onTap(InvoiceAction.archive),
        ),
      if (canEditInvoice)
        ?restoreActionItem(
          context: context,
          kind: InvoiceAction.restore,
          canRestore: canRestore,
          onTap: () => onTap(InvoiceAction.restore),
        ),
      if (canDeleteInvoice)
        ?deleteActionItem(
          context: context,
          kind: InvoiceAction.delete,
          canDelete: !invoice.isDeleted,
          onTap: () => onTap(InvoiceAction.delete),
        ),
      if (canDeleteInvoice)
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
        goEntityEdit(context, '/invoices', invoice.id);

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
          if (!context.mounted) return;
          Notify.success(context, context.tr('email_queued'));
        } else {
          await services.invoices.email(
            companyId: companyId,
            id: invoice.id,
            template: result.template,
            subject: result.subject.isEmpty ? null : result.subject,
            body: result.body.isEmpty ? null : result.body,
            ccEmail: result.ccEmail.isEmpty ? null : result.ccEmail,
          );
          if (!context.mounted) return;
          Notify.success(context, context.tr('email_queued'));
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
        // Open the payment editor prefilled with this client + an invoice
        // allocation seeded to the outstanding balance. The user can lower
        // the amount for a partial payment — the allocations section + VM
        // auto-sync `amount` from the paymentables.
        context.go(
          '/payments/new',
          extra: emptyPayment().copyWith(
            clientId: invoice.clientId,
            paymentables: [
              Paymentable(
                invoiceId: invoice.id,
                amount: invoice.balance,
                refunded: Decimal.zero,
              ),
            ],
          ),
        );

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
        if (tmpGate()) return;
        final text = await showAddCommentPrompt(context);
        if (text == null || !context.mounted) return;
        await services.invoices.addComment(
          companyId: companyId,
          invoiceId: invoice.id,
          text: text,
        );

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

      case InvoiceAction.cloneToQuote:
        if (tmpGate()) return;
        await services.invoices.cloneTo(
          companyId: companyId,
          id: invoice.id,
          targetType: 'quote',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_quote'));

      case InvoiceAction.cloneToCredit:
        if (tmpGate()) return;
        await services.invoices.cloneTo(
          companyId: companyId,
          id: invoice.id,
          targetType: 'credit',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_credit'));

      case InvoiceAction.cloneToRecurring:
        if (tmpGate()) return;
        await services.invoices.cloneTo(
          companyId: companyId,
          id: invoice.id,
          targetType: 'recurring_invoice',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_recurring'));

      case InvoiceAction.cloneToPurchaseOrder:
        if (tmpGate()) return;
        await services.invoices.cloneTo(
          companyId: companyId,
          id: invoice.id,
          targetType: 'purchase_order',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_purchase_order'));

      case InvoiceAction.runTemplate:
        if (tmpGate()) return;
        final templateId = await showRunTemplateDialog(context);
        if (templateId == null || !context.mounted) return;
        await services.invoices.runTemplate(
          companyId: companyId,
          id: invoice.id,
          templateId: templateId,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('template_queued'));
    }
  }
}

