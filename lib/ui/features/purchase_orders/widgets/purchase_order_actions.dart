import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/billing_shared/actions/add_comment_prompt.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/email/billing_doc_email_sheet.dart';
import 'package:admin/ui/features/invoices/widgets/detail/run_template_dialog.dart';

/// PurchaseOrder action set. Mirrors Quote/Credit actions plus the two
/// PO-specific actions (`accept`, `convertToExpense`); drops conversion
/// actions and the cloneToRecurring target (no recurring POs).
enum PurchaseOrderAction {
  edit,
  pdfGroup,
  viewPdf,
  downloadPdf,
  printPdf,
  sendEmail,
  scheduleEmail,
  markSent,
  accept,
  cancel,
  convertToExpense,
  cloneGroup,
  clone,
  cloneToInvoice,
  cloneToQuote,
  cloneToCredit,
  runTemplate,
  addComment,
  archive,
  restore,
  delete,
}

class PurchaseOrderActions {
  PurchaseOrderActions._();

  /// SAVE-PARAM classifier (edit-screen action bar). Non-null => the
  /// action is performed *by* the create/update request via these query
  /// params (server creates/updates and acts atomically — no temp-id
  /// gap). Keys are purchase-order-specific (verified against admin-portal
  /// `purchase_order_repository.saveData`: `mark_sent` / `accept`).
  /// `sendEmail` is intentionally **not** here — it is an after-save
  /// separate request.
  static Map<String, String>? saveParamFor(PurchaseOrderAction action) {
    switch (action) {
      case PurchaseOrderAction.markSent:
        return const {'mark_sent': 'true'};
      case PurchaseOrderAction.accept:
        return const {'accept': 'true'};
      default:
        return null;
    }
  }

  /// Actions the old admin-portal hid on a brand-new (unsaved) record.
  /// Fed to `filterForEditScreen` so the create screen drops clone /
  /// archive / restore / delete (the clone group collapses as a whole).
  static bool isLifecycle(PurchaseOrderAction action) {
    switch (action) {
      case PurchaseOrderAction.cloneGroup:
      case PurchaseOrderAction.clone:
      case PurchaseOrderAction.cloneToInvoice:
      case PurchaseOrderAction.cloneToQuote:
      case PurchaseOrderAction.cloneToCredit:
      case PurchaseOrderAction.archive:
      case PurchaseOrderAction.restore:
      case PurchaseOrderAction.delete:
        return true;
      default:
        return false;
    }
  }

  static List<EntityActionItem<PurchaseOrderAction>> itemsFor(
    BuildContext context,
    PurchaseOrder po,
    void Function(PurchaseOrderAction) onTap,
  ) {
    final canArchive = po.archivedAt == null && !po.isDeleted;
    final canRestore = po.archivedAt != null || po.isDeleted;
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canEdit = me?.can('edit_purchase_order') ?? false;
    final canCreate = me?.can('create_purchase_order') ?? false;
    final canDelete = me?.can('delete_purchase_order') ?? false;
    final canMarkSent = canEdit && po.isDraft;
    final canAccept = canEdit && po.isSent;
    final canCancel =
        canEdit && (po.isSent || po.isAccepted) && !po.isCancelled;
    final canConvertToExpense = canEdit && po.isAccepted;

    return [
      if (canEdit)
        editActionItem(
          context: context,
          kind: PurchaseOrderAction.edit,
          onTap: () => onTap(PurchaseOrderAction.edit),
        ),
      pdfGroupActionItem(
        context: context,
        kind: PurchaseOrderAction.pdfGroup,
        children: [
          EntityActionItem(
            kind: PurchaseOrderAction.viewPdf,
            icon: Icons.picture_as_pdf_outlined,
            label: context.tr('view_pdf'),
            enabled: true,
            onTap: () => onTap(PurchaseOrderAction.viewPdf),
          ),
          EntityActionItem(
            kind: PurchaseOrderAction.downloadPdf,
            icon: Icons.download_outlined,
            label: context.tr('download_pdf'),
            enabled: true,
            onTap: () => onTap(PurchaseOrderAction.downloadPdf),
          ),
          EntityActionItem(
            kind: PurchaseOrderAction.printPdf,
            icon: Icons.print_outlined,
            label: context.tr('print_pdf'),
            enabled: true,
            onTap: () => onTap(PurchaseOrderAction.printPdf),
          ),
        ],
      ),
      EntityActionItem(
        kind: PurchaseOrderAction.sendEmail,
        icon: Icons.mail_outline,
        label: context.tr('send_email'),
        enabled: canEdit,
        onTap: () => onTap(PurchaseOrderAction.sendEmail),
      ),
      EntityActionItem(
        kind: PurchaseOrderAction.markSent,
        icon: Icons.send_outlined,
        label: context.tr('mark_sent'),
        enabled: canMarkSent,
        onTap: () => onTap(PurchaseOrderAction.markSent),
      ),
      EntityActionItem(
        kind: PurchaseOrderAction.accept,
        icon: Icons.thumb_up_alt_outlined,
        label: context.tr('accept'),
        enabled: canAccept,
        onTap: () => onTap(PurchaseOrderAction.accept),
      ),
      if (me?.moduleEnabled(EntityType.expense) ?? false)
        EntityActionItem(
          kind: PurchaseOrderAction.convertToExpense,
          icon: Icons.receipt_outlined,
          label: context.tr('convert_to_expense'),
          enabled: canConvertToExpense,
          onTap: () => onTap(PurchaseOrderAction.convertToExpense),
        ),
      EntityActionItem(
        kind: PurchaseOrderAction.cancel,
        icon: Icons.cancel_outlined,
        label: context.tr('cancel_purchase_order'),
        enabled: canCancel,
        onTap: () => onTap(PurchaseOrderAction.cancel),
      ),
      if (canCreate)
        cloneGroupActionItem(
          context: context,
          kind: PurchaseOrderAction.cloneGroup,
          children: [
            EntityActionItem(
              kind: PurchaseOrderAction.clone,
              icon: Icons.copy_outlined,
              label: context.tr('clone_purchase_order'),
              enabled: true,
              onTap: () => onTap(PurchaseOrderAction.clone),
            ),
            if (me?.moduleEnabled(EntityType.invoice) ?? false)
              EntityActionItem(
                kind: PurchaseOrderAction.cloneToInvoice,
                icon: Icons.receipt_long_outlined,
                label: context.tr('clone_to_invoice'),
                enabled: true,
                onTap: () => onTap(PurchaseOrderAction.cloneToInvoice),
              ),
            if (me?.moduleEnabled(EntityType.quote) ?? false)
              EntityActionItem(
                kind: PurchaseOrderAction.cloneToQuote,
                icon: Icons.request_quote_outlined,
                label: context.tr('clone_to_quote'),
                enabled: true,
                onTap: () => onTap(PurchaseOrderAction.cloneToQuote),
              ),
            if (me?.moduleEnabled(EntityType.credit) ?? false)
              EntityActionItem(
                kind: PurchaseOrderAction.cloneToCredit,
                icon: Icons.assignment_return_outlined,
                label: context.tr('clone_to_credit'),
                enabled: true,
                onTap: () => onTap(PurchaseOrderAction.cloneToCredit),
              ),
          ],
        ),
      if (canEdit) ...[
        EntityActionItem(
          kind: PurchaseOrderAction.runTemplate,
          icon: Icons.auto_awesome_outlined,
          label: context.tr('run_template'),
          enabled: true,
          onTap: () => onTap(PurchaseOrderAction.runTemplate),
        ),
        EntityActionItem(
          kind: PurchaseOrderAction.addComment,
          icon: Icons.chat_bubble_outline,
          label: context.tr('add_comment'),
          enabled: true,
          onTap: () => onTap(PurchaseOrderAction.addComment),
        ),
      ],
      if (canEdit)
        ?archiveActionItem(
          context: context,
          kind: PurchaseOrderAction.archive,
          canArchive: canArchive,
          onTap: () => onTap(PurchaseOrderAction.archive),
        ),
      if (canEdit)
        ?restoreActionItem(
          context: context,
          kind: PurchaseOrderAction.restore,
          canRestore: canRestore,
          onTap: () => onTap(PurchaseOrderAction.restore),
        ),
      if (canDelete)
        ?deleteActionItem(
          context: context,
          kind: PurchaseOrderAction.delete,
          canDelete: !po.isDeleted,
          onTap: () => onTap(PurchaseOrderAction.delete),
        ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    PurchaseOrder po,
    PurchaseOrderAction action,
  ) async {
    bool tmpGate() {
      if (po.id.startsWith('tmp_')) {
        Notify.error(context, context.tr('sync_first'));
        return true;
      }
      return false;
    }

    switch (action) {
      case PurchaseOrderAction.edit:
        goEntityEdit(context, '/purchase_orders', po.id);

      case PurchaseOrderAction.pdfGroup:
        break; // Submenu parent — never dispatched; children carry the action.

      case PurchaseOrderAction.viewPdf:
        if (tmpGate()) return;
        unawaited(context.push('/purchase_orders/${po.id}/pdf'));

      case PurchaseOrderAction.downloadPdf:
      case PurchaseOrderAction.printPdf:
        if (tmpGate()) return;
        try {
          final bytes = await services.purchaseOrders.api.downloadPdf(
            id: po.id,
            designId: po.designId.isEmpty ? null : po.designId,
          );
          if (!context.mounted) return;
          if (action == PurchaseOrderAction.downloadPdf) {
            final fileName =
                'purchase_order_${po.number.isEmpty ? po.id : po.number}.pdf';
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          } else {
            await Printing.layoutPdf(onLayout: (_) async => bytes);
          }
        } catch (e) {
          if (!context.mounted) return;
          Notify.error(context, '$e');
        }

      case PurchaseOrderAction.sendEmail:
      case PurchaseOrderAction.scheduleEmail:
        if (tmpGate()) return;
        final result = await showBillingDocEmailSheet(
          context,
          entity: BillingDocType.purchaseOrder,
          entityNumber: po.number,
          formatter: null,
        );
        if (result == null) return;
        if (result.scheduledFor != null) {
          await services.purchaseOrders.scheduleEmail(
            companyId: companyId,
            id: po.id,
            template: result.template,
            sendAt: result.scheduledFor!.toUtc().toIso8601String(),
            subject: result.subject.isEmpty ? null : result.subject,
            body: result.body.isEmpty ? null : result.body,
          );
          if (!context.mounted) return;
          Notify.success(context, context.tr('email_queued'));
        } else {
          await services.purchaseOrders.email(
            companyId: companyId,
            id: po.id,
            template: result.template,
            subject: result.subject.isEmpty ? null : result.subject,
            body: result.body.isEmpty ? null : result.body,
            ccEmail: result.ccEmail.isEmpty ? null : result.ccEmail,
          );
          if (!context.mounted) return;
          Notify.success(context, context.tr('email_queued'));
        }

      case PurchaseOrderAction.markSent:
        if (tmpGate()) return;
        await services.purchaseOrders.markSent(companyId: companyId, id: po.id);
        if (!context.mounted) return;
        Notify.success(context, context.tr('marked_purchase_order_as_sent'));

      case PurchaseOrderAction.accept:
        if (tmpGate()) return;
        await services.purchaseOrders.accept(companyId: companyId, id: po.id);
        if (!context.mounted) return;
        Notify.success(context, context.tr('accepted_purchase_order'));

      case PurchaseOrderAction.cancel:
        if (tmpGate()) return;
        await services.purchaseOrders.cancel(companyId: companyId, id: po.id);
        if (!context.mounted) return;
        Notify.success(context, context.tr('cancelled_purchase_order'));

      case PurchaseOrderAction.convertToExpense:
        if (tmpGate()) return;
        await services.purchaseOrders.convertToExpense(
          companyId: companyId,
          id: po.id,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('converted_to_expense'));

      case PurchaseOrderAction.cloneGroup:
        break; // Submenu parent — never dispatched; children carry the action.
      case PurchaseOrderAction.clone:
        final draft = po.copyWith(
          id: '',
          number: '',
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          expenseId: '',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        context.go('/purchase_orders/new', extra: draft);

      case PurchaseOrderAction.cloneToInvoice:
        if (tmpGate()) return;
        await services.purchaseOrders.cloneTo(
          companyId: companyId,
          id: po.id,
          targetType: 'invoice',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_invoice'));

      case PurchaseOrderAction.cloneToQuote:
        if (tmpGate()) return;
        await services.purchaseOrders.cloneTo(
          companyId: companyId,
          id: po.id,
          targetType: 'quote',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_quote'));

      case PurchaseOrderAction.cloneToCredit:
        if (tmpGate()) return;
        await services.purchaseOrders.cloneTo(
          companyId: companyId,
          id: po.id,
          targetType: 'credit',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_credit'));

      case PurchaseOrderAction.addComment:
        if (tmpGate()) return;
        final text = await showAddCommentPrompt(context);
        if (text == null || !context.mounted) return;
        await services.purchaseOrders.addComment(
          companyId: companyId,
          purchaseOrderId: po.id,
          text: text,
        );

      case PurchaseOrderAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'purchase_order',
          op: () =>
              services.purchaseOrders.archive(companyId: companyId, id: po.id),
        );

      case PurchaseOrderAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'purchase_order',
          op: () =>
              services.purchaseOrders.restore(companyId: companyId, id: po.id),
        );

      case PurchaseOrderAction.delete:
        if (tmpGate()) return;
        await StandardEntityActions.delete(
          context: context,
          wireName: 'purchase_order',
          op: () =>
              services.purchaseOrders.delete(companyId: companyId, id: po.id),
        );

      case PurchaseOrderAction.runTemplate:
        if (tmpGate()) return;
        final templateId = await showRunTemplateDialog(context);
        if (templateId == null || !context.mounted) return;
        await services.purchaseOrders.runTemplate(
          companyId: companyId,
          id: po.id,
          templateId: templateId,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('template_queued'));
    }
  }
}
