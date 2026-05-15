import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/billing_shared/actions/add_comment_prompt.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';
import 'package:admin/ui/features/billing_shared/email/billing_doc_email_sheet.dart';
import 'package:admin/ui/features/invoices/widgets/detail/run_template_dialog.dart';

/// Credit action set. Mirrors `QuoteAction` but drops the conversion
/// actions (`approve` / `convertToInvoice` / `convertToProject`) — credits
/// have no convert lifecycle — and trims `cloneToRecurring` since recurring
/// credits don't exist.
enum CreditAction {
  edit,
  viewPdf,
  downloadPdf,
  printPdf,
  sendEmail,
  scheduleEmail,
  markSent,
  clone,
  cloneToInvoice,
  cloneToQuote,
  cloneToPurchaseOrder,
  runTemplate,
  addComment,
  archive,
  restore,
  delete,
  purge,
}

class CreditActions {
  CreditActions._();

  static List<EntityActionItem<CreditAction>> itemsFor(
    BuildContext context,
    Credit credit,
    void Function(CreditAction) onTap,
  ) {
    final canArchive = credit.archivedAt == null && !credit.isDeleted;
    final canRestore = credit.archivedAt != null || credit.isDeleted;
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canPurge = (me?.isAdmin ?? false) || (me?.isOwner ?? false);
    final canEdit = me?.can('edit_credit') ?? false;
    final canCreate = me?.can('create_credit') ?? false;
    final canDelete = me?.can('delete_credit') ?? false;
    final canMarkSent = canEdit && credit.isDraft;

    return [
      if (canEdit)
        editActionItem(
          context: context,
          kind: CreditAction.edit,
          onTap: () => onTap(CreditAction.edit),
        ),
      EntityActionItem(
        kind: CreditAction.viewPdf,
        icon: Icons.picture_as_pdf_outlined,
        label: context.tr('view_pdf'),
        enabled: true,
        onTap: () => onTap(CreditAction.viewPdf),
      ),
      EntityActionItem(
        kind: CreditAction.downloadPdf,
        icon: Icons.download_outlined,
        label: context.tr('download_pdf'),
        enabled: true,
        onTap: () => onTap(CreditAction.downloadPdf),
      ),
      EntityActionItem(
        kind: CreditAction.printPdf,
        icon: Icons.print_outlined,
        label: context.tr('print_pdf'),
        enabled: true,
        onTap: () => onTap(CreditAction.printPdf),
      ),
      EntityActionItem(
        kind: CreditAction.sendEmail,
        icon: Icons.mail_outline,
        label: context.tr('send_email'),
        enabled: canEdit,
        onTap: () => onTap(CreditAction.sendEmail),
      ),
      EntityActionItem(
        kind: CreditAction.markSent,
        icon: Icons.send_outlined,
        label: context.tr('mark_sent'),
        enabled: canMarkSent,
        onTap: () => onTap(CreditAction.markSent),
      ),
      if (canCreate) ...[
        EntityActionItem(
          kind: CreditAction.clone,
          icon: Icons.copy_outlined,
          label: context.tr('clone_credit'),
          enabled: true,
          onTap: () => onTap(CreditAction.clone),
        ),
        EntityActionItem(
          kind: CreditAction.cloneToInvoice,
          icon: Icons.receipt_long_outlined,
          label: context.tr('clone_to_invoice'),
          enabled: true,
          onTap: () => onTap(CreditAction.cloneToInvoice),
        ),
        EntityActionItem(
          kind: CreditAction.cloneToQuote,
          icon: Icons.request_quote_outlined,
          label: context.tr('clone_to_quote'),
          enabled: true,
          onTap: () => onTap(CreditAction.cloneToQuote),
        ),
        EntityActionItem(
          kind: CreditAction.cloneToPurchaseOrder,
          icon: Icons.shopping_bag_outlined,
          label: context.tr('clone_to_purchase_order'),
          enabled: true,
          onTap: () => onTap(CreditAction.cloneToPurchaseOrder),
        ),
      ],
      if (canEdit) ...[
        EntityActionItem(
          kind: CreditAction.runTemplate,
          icon: Icons.auto_awesome_outlined,
          label: context.tr('run_template'),
          enabled: true,
          onTap: () => onTap(CreditAction.runTemplate),
        ),
        EntityActionItem(
          kind: CreditAction.addComment,
          icon: Icons.chat_bubble_outline,
          label: context.tr('add_comment'),
          enabled: true,
          onTap: () => onTap(CreditAction.addComment),
        ),
      ],
      if (canEdit)
        ?archiveActionItem(
          context: context,
          kind: CreditAction.archive,
          canArchive: canArchive,
          onTap: () => onTap(CreditAction.archive),
        ),
      if (canEdit)
        ?restoreActionItem(
          context: context,
          kind: CreditAction.restore,
          canRestore: canRestore,
          onTap: () => onTap(CreditAction.restore),
        ),
      if (canDelete)
        ?deleteActionItem(
          context: context,
          kind: CreditAction.delete,
          canDelete: !credit.isDeleted,
          onTap: () => onTap(CreditAction.delete),
        ),
      if (canDelete)
        ?purgeActionItem(
          context: context,
          kind: CreditAction.purge,
          canPurge: canPurge,
          onTap: () => onTap(CreditAction.purge),
        ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    Credit credit,
    CreditAction action,
  ) async {
    bool tmpGate() {
      if (credit.id.startsWith('tmp_')) {
        Notify.error(context, context.tr('sync_first'));
        return true;
      }
      return false;
    }

    switch (action) {
      case CreditAction.edit:
        context.go('/credits/${credit.id}/edit');

      case CreditAction.viewPdf:
        if (tmpGate()) return;
        unawaited(context.push('/credits/${credit.id}/pdf'));

      case CreditAction.downloadPdf:
      case CreditAction.printPdf:
        if (tmpGate()) return;
        try {
          final bytes = await services.credits.api.downloadPdf(
            id: credit.id,
            designId: credit.designId.isEmpty ? null : credit.designId,
          );
          if (!context.mounted) return;
          if (action == CreditAction.downloadPdf) {
            final fileName =
                'credit_${credit.number.isEmpty ? credit.id : credit.number}.pdf';
            await Printing.sharePdf(bytes: bytes, filename: fileName);
          } else {
            await Printing.layoutPdf(onLayout: (_) async => bytes);
          }
        } catch (e) {
          if (!context.mounted) return;
          Notify.error(context, '$e');
        }

      case CreditAction.sendEmail:
      case CreditAction.scheduleEmail:
        if (tmpGate()) return;
        final result = await showBillingDocEmailSheet(
          context,
          entity: BillingDocType.credit,
          entityNumber: credit.number,
          formatter: null,
        );
        if (result == null) return;
        if (result.scheduledFor != null) {
          await services.credits.scheduleEmail(
            companyId: companyId,
            id: credit.id,
            template: result.template,
            sendAt: result.scheduledFor!.toUtc().toIso8601String(),
            subject: result.subject.isEmpty ? null : result.subject,
            body: result.body.isEmpty ? null : result.body,
          );
          if (!context.mounted) return;
          Notify.success(context, context.tr('email_queued'));
        } else {
          await services.credits.email(
            companyId: companyId,
            id: credit.id,
            template: result.template,
            subject: result.subject.isEmpty ? null : result.subject,
            body: result.body.isEmpty ? null : result.body,
            ccEmail: result.ccEmail.isEmpty ? null : result.ccEmail,
          );
          if (!context.mounted) return;
          Notify.success(context, context.tr('email_queued'));
        }

      case CreditAction.markSent:
        if (tmpGate()) return;
        await services.credits.markSent(companyId: companyId, id: credit.id);
        if (!context.mounted) return;
        Notify.success(context, context.tr('marked_credit_as_sent'));

      case CreditAction.clone:
        final draft = credit.copyWith(
          id: '',
          number: '',
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        context.go('/credits/new', extra: draft);

      case CreditAction.cloneToInvoice:
        if (tmpGate()) return;
        await services.credits.cloneTo(
          companyId: companyId,
          id: credit.id,
          targetType: 'invoice',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_invoice'));

      case CreditAction.cloneToQuote:
        if (tmpGate()) return;
        await services.credits.cloneTo(
          companyId: companyId,
          id: credit.id,
          targetType: 'quote',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_quote'));

      case CreditAction.cloneToPurchaseOrder:
        if (tmpGate()) return;
        await services.credits.cloneTo(
          companyId: companyId,
          id: credit.id,
          targetType: 'purchase_order',
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('cloned_to_purchase_order'));

      case CreditAction.addComment:
        if (tmpGate()) return;
        final text = await showAddCommentPrompt(context);
        if (text == null || !context.mounted) return;
        await services.credits.addComment(
          companyId: companyId,
          creditId: credit.id,
          text: text,
        );

      case CreditAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'credit',
          op: () => services.credits.archive(
            companyId: companyId,
            id: credit.id,
          ),
        );

      case CreditAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'credit',
          op: () => services.credits.restore(
            companyId: companyId,
            id: credit.id,
          ),
        );

      case CreditAction.delete:
        if (tmpGate()) return;
        await StandardEntityActions.delete(
          context: context,
          wireName: 'credit',
          op: () => services.credits.delete(
            companyId: companyId,
            id: credit.id,
          ),
        );

      case CreditAction.purge:
        if (tmpGate()) return;
        await StandardEntityActions.purge(
          context: context,
          wireName: 'credit',
          op: () => services.credits.purge(
            companyId: companyId,
            id: credit.id,
          ),
        );
        if (context.mounted) context.go('/credits');

      case CreditAction.runTemplate:
        if (tmpGate()) return;
        final templateId = await showRunTemplateDialog(context);
        if (templateId == null || !context.mounted) return;
        await services.credits.runTemplate(
          companyId: companyId,
          id: credit.id,
          templateId: templateId,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('template_queued'));
    }
  }
}
