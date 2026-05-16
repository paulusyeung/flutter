import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Action set surfaced for a Payment Link. Standard minimum surface —
/// edit / archive / restore / delete / purge — mirroring
/// [ExpenseCategoryAction]. No clone today.
enum PaymentLinkAction { edit, archive, restore, delete, purge }

/// Single source of truth for what PaymentLink actions exist and what
/// they do. Consumed by the list-row popup, detail header, and edit
/// screen's overflow menu.
class PaymentLinkActions {
  PaymentLinkActions._();

  static List<EntityActionItem<PaymentLinkAction>> itemsFor(
    BuildContext context,
    PaymentLink paymentLink,
    void Function(PaymentLinkAction) onTap,
  ) {
    final canArchive =
        paymentLink.archivedAt == null && !paymentLink.isDeleted;
    final canRestore =
        paymentLink.archivedAt != null || paymentLink.isDeleted;
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canPurge = (me?.isAdmin ?? false) || (me?.isOwner ?? false);

    return [
      editActionItem(
        context: context,
        kind: PaymentLinkAction.edit,
        onTap: () => onTap(PaymentLinkAction.edit),
      ),
      ?archiveActionItem(
        context: context,
        kind: PaymentLinkAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(PaymentLinkAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: PaymentLinkAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(PaymentLinkAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: PaymentLinkAction.delete,
        canDelete: !paymentLink.isDeleted,
        onTap: () => onTap(PaymentLinkAction.delete),
      ),
      ?purgeActionItem(
        context: context,
        kind: PaymentLinkAction.purge,
        canPurge: canPurge,
        onTap: () => onTap(PaymentLinkAction.purge),
      ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    PaymentLink paymentLink,
    PaymentLinkAction action,
  ) async {
    switch (action) {
      case PaymentLinkAction.edit:
        goEntityEdit(context, '/settings/payment_links', paymentLink.id);
      case PaymentLinkAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'payment_link',
          op: () => services.paymentLinks.archive(
            companyId: companyId,
            id: paymentLink.id,
          ),
        );
      case PaymentLinkAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'payment_link',
          op: () => services.paymentLinks.restore(
            companyId: companyId,
            id: paymentLink.id,
          ),
        );
      case PaymentLinkAction.delete:
        if (paymentLink.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.delete(
          context: context,
          wireName: 'payment_link',
          op: () => services.paymentLinks.delete(
            companyId: companyId,
            id: paymentLink.id,
          ),
        );
      case PaymentLinkAction.purge:
        if (paymentLink.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.purge(
          context: context,
          wireName: 'payment_link',
          op: () => services.paymentLinks.purge(
            companyId: companyId,
            id: paymentLink.id,
          ),
        );
        if (context.mounted) context.go('/settings/payment_links');
    }
  }
}
