import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/quote.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/billing_shared/actions/add_comment_prompt.dart';
import 'package:admin/ui/features/invoices/widgets/detail/run_template_dialog.dart';

/// Quote action set. Mirrors `InvoiceAction` but drops `markPaid` /
/// `autoBill` (payment-side, invoice-only) and adds `approve` /
/// `convertToInvoice` / `convertToProject`.
enum QuoteAction {
  edit,
  pdfGroup,
  viewPdf,
  downloadPdf,
  printPdf,
  sendEmail,
  scheduleEmail,
  markSent,
  approve,
  convertToInvoice,
  convertToProject,
  cloneGroup,
  clone,
  cloneToInvoice,
  cloneToCredit,
  cloneToRecurring,
  cloneToPurchaseOrder,
  cancel,
  runTemplate,
  addComment,
  archive,
  restore,
  delete,
}

class QuoteActions {
  QuoteActions._();

  /// SAVE-PARAM classifier (edit-screen action bar). Non-null => the
  /// action is performed *by* the create/update request via these query
  /// params (server creates/updates and acts atomically — no temp-id
  /// gap). Keys are quote-specific (verified against admin-portal
  /// `quote_repository.saveData`: `convert` / `mark_sent` / `approve`).
  /// `sendEmail` is intentionally **not** here — it is an after-save
  /// separate request.
  static Map<String, String>? saveParamFor(QuoteAction action) {
    switch (action) {
      case QuoteAction.convertToInvoice:
        return const {'convert': 'true'};
      case QuoteAction.markSent:
        return const {'mark_sent': 'true'};
      case QuoteAction.approve:
        return const {'approve': 'true'};
      default:
        return null;
    }
  }

  /// Actions the old admin-portal hid on a brand-new (unsaved) record.
  /// Fed to `filterForEditScreen` so the create screen drops clone /
  /// archive / restore / delete (the clone group collapses as a whole).
  static bool isLifecycle(QuoteAction action) {
    switch (action) {
      case QuoteAction.cloneGroup:
      case QuoteAction.clone:
      case QuoteAction.cloneToInvoice:
      case QuoteAction.cloneToCredit:
      case QuoteAction.cloneToRecurring:
      case QuoteAction.cloneToPurchaseOrder:
      case QuoteAction.archive:
      case QuoteAction.restore:
      case QuoteAction.delete:
        return true;
      default:
        return false;
    }
  }

  static List<EntityActionItem<QuoteAction>> itemsFor(
    BuildContext context,
    Quote quote,
    void Function(QuoteAction) onTap,
  ) {
    final canArchive = quote.archivedAt == null && !quote.isDeleted;
    final canRestore = quote.archivedAt != null || quote.isDeleted;
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canEdit = me?.can('edit_quote') ?? false;
    final canCreate = me?.can('create_quote') ?? false;
    final canDelete = me?.can('delete_quote') ?? false;
    final canMarkSent = canEdit && quote.isDraft;
    final canApprove = canEdit && quote.isSent;
    final canConvert =
        canEdit && (quote.isApproved || quote.isSent) && !quote.isConverted;
    // Cancel is server-allowed for Sent quotes (rarely used in practice
    // but available — mirrors the Invoice rule). Converted quotes can't
    // be cancelled since their downstream invoice has its own lifecycle.
    final canCancel = canEdit && quote.isSent && !quote.isConverted;

    return [
      if (canEdit)
        editActionItem(
          context: context,
          kind: QuoteAction.edit,
          onTap: () => onTap(QuoteAction.edit),
        ),
      pdfGroupActionItem(
        context: context,
        kind: QuoteAction.pdfGroup,
        children: [
          EntityActionItem(
            kind: QuoteAction.viewPdf,
            icon: Icons.picture_as_pdf_outlined,
            label: context.tr('view_pdf'),
            enabled: true,
            onTap: () => onTap(QuoteAction.viewPdf),
          ),
          EntityActionItem(
            kind: QuoteAction.downloadPdf,
            icon: Icons.download_outlined,
            label: context.tr('download_pdf'),
            enabled: true,
            onTap: () => onTap(QuoteAction.downloadPdf),
          ),
          EntityActionItem(
            kind: QuoteAction.printPdf,
            icon: Icons.print_outlined,
            label: context.tr('print_pdf'),
            enabled: true,
            onTap: () => onTap(QuoteAction.printPdf),
          ),
        ],
      ),
      EntityActionItem(
        kind: QuoteAction.sendEmail,
        icon: Icons.mail_outline,
        label: context.tr('send_email'),
        enabled: canEdit,
        onTap: () => onTap(QuoteAction.sendEmail),
      ),
      EntityActionItem(
        kind: QuoteAction.markSent,
        icon: Icons.send_outlined,
        label: context.tr('mark_sent'),
        enabled: canMarkSent,
        onTap: () => onTap(QuoteAction.markSent),
      ),
      EntityActionItem(
        kind: QuoteAction.approve,
        icon: Icons.thumb_up_alt_outlined,
        label: context.tr('approve'),
        enabled: canApprove,
        onTap: () => onTap(QuoteAction.approve),
      ),
      if (me?.moduleEnabled(EntityType.invoice) ?? false)
        EntityActionItem(
          kind: QuoteAction.convertToInvoice,
          icon: Icons.receipt_long_outlined,
          label: context.tr('convert_to_invoice'),
          enabled: canConvert,
          onTap: () => onTap(QuoteAction.convertToInvoice),
        ),
      if (me?.moduleEnabled(EntityType.project) ?? false)
        EntityActionItem(
          kind: QuoteAction.convertToProject,
          icon: Icons.work_outline,
          label: context.tr('convert_to_project'),
          enabled: canEdit && !quote.isConverted,
          onTap: () => onTap(QuoteAction.convertToProject),
        ),
      EntityActionItem(
        kind: QuoteAction.cancel,
        icon: Icons.cancel_outlined,
        label: context.tr('cancel_quote'),
        enabled: canCancel,
        onTap: () => onTap(QuoteAction.cancel),
      ),
      if (canCreate)
        cloneGroupActionItem(
          context: context,
          kind: QuoteAction.cloneGroup,
          children: [
            EntityActionItem(
              kind: QuoteAction.clone,
              icon: Icons.copy_outlined,
              label: context.tr('clone_quote'),
              enabled: true,
              onTap: () => onTap(QuoteAction.clone),
            ),
            if (me?.moduleEnabled(EntityType.invoice) ?? false)
              EntityActionItem(
                kind: QuoteAction.cloneToInvoice,
                icon: Icons.receipt_long_outlined,
                label: context.tr('clone_to_invoice'),
                enabled: true,
                onTap: () => onTap(QuoteAction.cloneToInvoice),
              ),
            if (me?.moduleEnabled(EntityType.credit) ?? false)
              EntityActionItem(
                kind: QuoteAction.cloneToCredit,
                icon: Icons.assignment_return_outlined,
                label: context.tr('clone_to_credit'),
                enabled: true,
                onTap: () => onTap(QuoteAction.cloneToCredit),
              ),
            if (me?.moduleEnabled(EntityType.recurringInvoice) ?? false)
              EntityActionItem(
                kind: QuoteAction.cloneToRecurring,
                icon: Icons.event_repeat_outlined,
                label: context.tr('clone_to_recurring'),
                enabled: true,
                onTap: () => onTap(QuoteAction.cloneToRecurring),
              ),
            if (me?.moduleEnabled(EntityType.purchaseOrder) ?? false)
              EntityActionItem(
                kind: QuoteAction.cloneToPurchaseOrder,
                icon: Icons.shopping_bag_outlined,
                label: context.tr('clone_to_purchase_order'),
                enabled: true,
                onTap: () => onTap(QuoteAction.cloneToPurchaseOrder),
              ),
          ],
        ),
      if (canEdit) ...[
        EntityActionItem(
          kind: QuoteAction.runTemplate,
          icon: Icons.auto_awesome_outlined,
          label: context.tr('run_template'),
          enabled: true,
          onTap: () => onTap(QuoteAction.runTemplate),
        ),
        EntityActionItem(
          kind: QuoteAction.addComment,
          icon: Icons.chat_bubble_outline,
          label: context.tr('add_comment'),
          enabled: true,
          onTap: () => onTap(QuoteAction.addComment),
        ),
      ],
      if (canEdit)
        ?archiveActionItem(
          context: context,
          kind: QuoteAction.archive,
          canArchive: canArchive,
          onTap: () => onTap(QuoteAction.archive),
        ),
      if (canEdit)
        ?restoreActionItem(
          context: context,
          kind: QuoteAction.restore,
          canRestore: canRestore,
          onTap: () => onTap(QuoteAction.restore),
        ),
      if (canDelete)
        ?deleteActionItem(
          context: context,
          kind: QuoteAction.delete,
          canDelete: !quote.isDeleted,
          onTap: () => onTap(QuoteAction.delete),
        ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    Quote quote,
    QuoteAction action,
  ) async {
    bool tmpGate() {
      if (quote.id.startsWith('tmp_')) {
        Notify.error(context, context.tr('sync_first'));
        return true;
      }
      return false;
    }

    switch (action) {
      case QuoteAction.edit:
        goEntityEdit(context, '/quotes', quote.id);

      case QuoteAction.pdfGroup:
        break; // Submenu parent — never dispatched; children carry the action.

      case QuoteAction.viewPdf:
        if (tmpGate()) return;
        // `go` (not `push`): see client_actions.dart#viewStatement.
        context.go('/quotes/${quote.id}/pdf');

      case QuoteAction.downloadPdf:
      case QuoteAction.printPdf:
        if (tmpGate()) return;
        try {
          final bytes = await services.quotes.api.downloadPdf(
            entityJson: quote.toApiJson(),
            designId: quote.designId.isEmpty ? null : quote.designId,
          );
          if (!context.mounted) return;
          if (action == QuoteAction.downloadPdf) {
            final fileName =
                'quote_${quote.number.isEmpty ? quote.id : quote.number}.pdf';
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          } else {
            await Printing.layoutPdf(onLayout: (_) async => bytes);
          }
        } catch (e) {
          if (!context.mounted) return;
          Notify.error(context, '$e');
        }

      case QuoteAction.sendEmail:
      case QuoteAction.scheduleEmail:
        if (tmpGate()) return;
        // Full-screen Send Email surface; bulk multi-select still uses the
        // showBillingDocEmailSheet bottom sheet.
        context.go('/quotes/${quote.id}/email');

      case QuoteAction.markSent:
        if (tmpGate()) return;
        await services.quotes.markSent(companyId: companyId, id: quote.id);
        if (!context.mounted) return;
        Notify.success(context, context.tr('marked_quote_as_sent'));

      case QuoteAction.approve:
        if (tmpGate()) return;
        await services.quotes.approve(companyId: companyId, id: quote.id);
        if (!context.mounted) return;
        Notify.success(context, context.tr('approved_quote'));

      case QuoteAction.convertToInvoice:
        if (tmpGate()) return;
        await services.quotes.convertToInvoice(
          companyId: companyId,
          id: quote.id,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('converted_to_invoice'));

      case QuoteAction.convertToProject:
        if (tmpGate()) return;
        await services.quotes.convertToProject(
          companyId: companyId,
          id: quote.id,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('converted_to_project'));

      case QuoteAction.cancel:
        if (tmpGate()) return;
        await services.quotes.cancel(companyId: companyId, id: quote.id);
        if (!context.mounted) return;
        Notify.success(context, context.tr('cancelled_quote'));

      case QuoteAction.cloneGroup:
        break; // Submenu parent — never dispatched; children carry the action.
      case QuoteAction.clone:
        final draft = quote.copyWith(
          id: '',
          number: '',
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          invoiceId: '',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        goEntityCreateFullWidth(context, '/quotes', extra: draft);

      case QuoteAction.cloneToInvoice:
        if (tmpGate()) return;
        await services.quotes.cloneTo(
          companyId: companyId,
          id: quote.id,
          targetType: 'invoice',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_invoice'));

      case QuoteAction.cloneToCredit:
        if (tmpGate()) return;
        await services.quotes.cloneTo(
          companyId: companyId,
          id: quote.id,
          targetType: 'credit',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_credit'));

      case QuoteAction.cloneToRecurring:
        if (tmpGate()) return;
        await services.quotes.cloneTo(
          companyId: companyId,
          id: quote.id,
          targetType: 'recurring_invoice',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_recurring'));

      case QuoteAction.cloneToPurchaseOrder:
        if (tmpGate()) return;
        await services.quotes.cloneTo(
          companyId: companyId,
          id: quote.id,
          targetType: 'purchase_order',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_purchase_order'));

      case QuoteAction.addComment:
        if (tmpGate()) return;
        final text = await showAddCommentPrompt(context);
        if (text == null || !context.mounted) return;
        await services.quotes.addComment(
          companyId: companyId,
          quoteId: quote.id,
          text: text,
        );

      case QuoteAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'quote',
          op: () => services.quotes.archive(companyId: companyId, id: quote.id),
        );

      case QuoteAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'quote',
          op: () => services.quotes.restore(companyId: companyId, id: quote.id),
        );

      case QuoteAction.delete:
        if (tmpGate()) return;
        await StandardEntityActions.delete(
          context: context,
          wireName: 'quote',
          op: () => services.quotes.delete(companyId: companyId, id: quote.id),
        );

      case QuoteAction.runTemplate:
        if (tmpGate()) return;
        final templateId = await showRunTemplateDialog(context);
        if (templateId == null || !context.mounted) return;
        await services.quotes.runTemplate(
          companyId: companyId,
          id: quote.id,
          templateId: templateId,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('template_queued'));
    }
  }
}
