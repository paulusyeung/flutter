import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';
import 'package:admin/ui/features/clients/widgets/detail/add_comment_dialog.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';

/// Full action set surfaced for a vendor. Mirrors the actions exposed in
/// admin-portal's `vendor_model.dart#getActions`. Consumed by both the
/// detail-screen header and the list-row popup so the two surfaces stay
/// in sync — see [VendorActions.itemsFor].
enum VendorAction {
  edit,
  addComment,
  clone,
  newExpense,
  archive,
  restore,
  delete,
  purge,
}

/// Single source of truth for what vendor actions exist and what they do.
class VendorActions {
  VendorActions._();

  /// Item list shown by both the detail header row and the list-row popup.
  /// [onTap] receives the action; the caller wires it to [dispatch] (or
  /// any other handler).
  static List<EntityActionItem<VendorAction>> itemsFor(
    BuildContext context,
    Vendor vendor,
    void Function(VendorAction) onTap,
  ) {
    final canArchive = vendor.archivedAt == null && !vendor.isDeleted;
    final canRestore = vendor.archivedAt != null || vendor.isDeleted;
    // Purge is admin/owner-only — matches React's `isAdmin || isOwner` gate.
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canPurge = (me?.isAdmin ?? false) || (me?.isOwner ?? false);

    return [
      editActionItem(
        context: context,
        kind: VendorAction.edit,
        onTap: () => onTap(VendorAction.edit),
      ),
      EntityActionItem(
        kind: VendorAction.addComment,
        icon: Icons.add_comment_outlined,
        label: context.tr('add_comment'),
        enabled: true,
        onTap: () => onTap(VendorAction.addComment),
      ),
      EntityActionItem(
        kind: VendorAction.clone,
        icon: Icons.copy_outlined,
        label: context.tr('clone'),
        enabled: true,
        onTap: () => onTap(VendorAction.clone),
      ),
      EntityActionItem(
        kind: VendorAction.newExpense,
        icon: Icons.attach_money,
        label: context.tr('new_expense'),
        enabled: true,
        onTap: () => onTap(VendorAction.newExpense),
      ),
      ?archiveActionItem(
        context: context,
        kind: VendorAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(VendorAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: VendorAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(VendorAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: VendorAction.delete,
        canDelete: !vendor.isDeleted,
        onTap: () => onTap(VendorAction.delete),
      ),
      ?purgeActionItem(
        context: context,
        kind: VendorAction.purge,
        canPurge: canPurge,
        onTap: () => onTap(VendorAction.purge),
      ),
    ];
  }

  /// Runs [action] for [vendor]. Single dispatch path for both the
  /// detail-screen header and the list-row popup. Mirrors
  /// `ClientActions.dispatch`.
  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    Vendor vendor,
    VendorAction action,
  ) async {
    switch (action) {
      case VendorAction.edit:
        context.go('/vendors/${vendor.id}/edit');
      case VendorAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'vendor',
          op: () =>
              services.vendors.archive(companyId: companyId, id: vendor.id),
        );
      case VendorAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'vendor',
          op: () =>
              services.vendors.restore(companyId: companyId, id: vendor.id),
        );
      case VendorAction.addComment:
        // `tmp_` vendors only exist locally — the server has no row to
        // attach a comment to yet. Block instead of enqueuing a comment
        // that the dispatcher would 404 once the create round-trips.
        if (vendor.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        final text = await showAddCommentDialog(context);
        if (text == null || text.isEmpty || !context.mounted) return;
        await runMutationWithNotify(
          context,
          () => services.vendors.addComment(
            companyId: companyId,
            vendorId: vendor.id,
            text: text,
          ),
          successMsg: context.tr('added_comment'),
        );
      case VendorAction.clone:
        final draft = vendor.copyWith(
          id: '',
          number: '',
          balance: Decimal.zero,
          paidToDate: Decimal.zero,
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          contacts: [
            for (final c in vendor.contacts)
              c.copyWith(
                id: '',
                updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
                isDeleted: false,
              ),
          ],
        );
        context.go('/vendors/new', extra: draft);
      case VendorAction.newExpense:
        if (vendor.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/expenses/new',
          extra: emptyExpense().copyWith(vendorId: vendor.id),
        );
      case VendorAction.delete:
        if (vendor.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.delete(
          context: context,
          wireName: 'vendor',
          op: () =>
              services.vendors.delete(companyId: companyId, id: vendor.id),
        );
      case VendorAction.purge:
        if (vendor.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.purge(
          context: context,
          wireName: 'vendor',
          op: () => services.vendors.purge(companyId: companyId, id: vendor.id),
        );
        // Leave the detail screen before the dispatcher hard-deletes the
        // local row; mirror of `ClientActions.dispatch`.
        if (context.mounted) context.go('/vendors');
    }
  }
}
