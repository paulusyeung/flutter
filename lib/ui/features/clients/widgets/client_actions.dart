import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';

/// Full action set surfaced for a client. Mirrors the actions exposed in
/// admin-portal's `client_model.dart#getActions`, minus a few multiselect-
/// only / role-gated ones we don't have analogues for yet. Consumed by
/// both the detail-screen header and the list-row popup so the two
/// surfaces stay in sync — see [ClientActions.itemsFor].
enum ClientAction {
  edit,
  viewStatement,
  settings,
  assignGroup,
  addComment,
  newInvoice,
  newQuote,
  newPayment,
  newTask,
  newExpense,
  merge,
  archive,
  restore,
  delete,
  purge,
}

/// Single source of truth for what client actions exist and what they do.
/// The list-row popup (`ClientListTile`) and the detail header
/// (`ClientDetailScreen`) both consume this — mirrors admin-portal's
/// `entity.getActions(...)` pattern.
class ClientActions {
  ClientActions._();

  /// Item list shown by both the detail header row and the list-row popup.
  /// [onTap] receives the action; the caller wires it to [dispatch] (or
  /// any other handler).
  static List<EntityActionItem<ClientAction>> itemsFor(
    BuildContext context,
    Client client,
    void Function(ClientAction) onTap,
  ) {
    final canArchive = client.archivedAt == null && !client.isDeleted;
    final canRestore = client.archivedAt != null || client.isDeleted;

    return [
      EntityActionItem(
        kind: ClientAction.edit,
        icon: Icons.edit_outlined,
        label: context.tr('edit'),
        enabled: true,
        isPrimary: true,
        onTap: () => onTap(ClientAction.edit),
      ),
      EntityActionItem(
        kind: ClientAction.viewStatement,
        icon: Icons.picture_as_pdf,
        label: context.tr('view_statement'),
        enabled: true,
        onTap: () => onTap(ClientAction.viewStatement),
      ),
      EntityActionItem(
        kind: ClientAction.settings,
        icon: Icons.settings_outlined,
        label: context.tr('settings'),
        enabled: true,
        onTap: () => onTap(ClientAction.settings),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.assignGroup,
        icon: Icons.group_outlined,
        label: context.tr('assign_group'),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.addComment,
        icon: Icons.add_comment_outlined,
        label: context.tr('add_comment'),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.newInvoice,
        icon: Icons.receipt_long_outlined,
        label: context.tr('new_invoice'),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.newQuote,
        icon: Icons.request_quote_outlined,
        label: context.tr('new_quote'),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.newPayment,
        icon: Icons.payments_outlined,
        label: context.tr('new_payment'),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.newTask,
        icon: Icons.check_circle_outline,
        label: context.tr('new_task'),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.newExpense,
        icon: Icons.attach_money,
        label: context.tr('new_expense'),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.merge,
        icon: Icons.merge_type,
        label: context.tr('merge'),
      ),
      if (canArchive)
        EntityActionItem(
          kind: ClientAction.archive,
          icon: Icons.archive_outlined,
          label: context.tr('archive'),
          enabled: true,
          onTap: () => onTap(ClientAction.archive),
        ),
      if (canRestore)
        EntityActionItem(
          kind: ClientAction.restore,
          icon: Icons.unarchive_outlined,
          label: context.tr('restore'),
          enabled: true,
          onTap: () => onTap(ClientAction.restore),
        ),
      EntityActionItem.disabled(
        kind: ClientAction.delete,
        icon: Icons.delete_outline,
        label: context.tr('delete'),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.purge,
        icon: Icons.delete_forever_outlined,
        label: context.tr('purge'),
      ),
    ];
  }

  /// Runs [action] for [client]. Single dispatch path for both the
  /// detail-screen header and the list-row popup. Placeholder branches
  /// `break;` so the enum stays exhaustive and future wiring is grep-able.
  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    Client client,
    ClientAction action,
  ) async {
    switch (action) {
      case ClientAction.edit:
        context.go('/clients/${client.id}/edit');
      case ClientAction.viewStatement:
        // A `tmp_` client lives only in the local outbox — the server doesn't
        // know it yet, so a statement POST would 404. Tell the user to sync.
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        // Statement generation is server-only — no point opening the screen
        // just to render a network error. Gate at the action site.
        final online = await services.connectivity.isOnline;
        if (!context.mounted) return;
        if (!online) {
          Notify.error(context, context.tr('statement_offline'));
          return;
        }
        // Push (not go) so the back arrow returns to the previous screen.
        await context.push('/clients/${client.id}/statement');
      case ClientAction.archive:
        await runMutationWithNotify(
          context,
          () => services.clients.archive(companyId: companyId, id: client.id),
          successMsg: context.tr('archived_client'),
        );
      case ClientAction.restore:
        await runMutationWithNotify(
          context,
          () => services.clients.restore(companyId: companyId, id: client.id),
          successMsg: context.tr('restored_client'),
        );
      case ClientAction.settings:
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        services.settingsLevel.setLevel(
          SettingsLevel.client,
          targetId: client.id,
          targetName: client.displayName,
        );
        // Localization mirrors admin-portal's default landing for client
        // scope and is the first non-company-only entry in the filtered
        // sidebar — picking it explicitly keeps the two heuristics in
        // agreement.
        context.go('/settings/localization');
      case ClientAction.assignGroup:
      case ClientAction.addComment:
      case ClientAction.newInvoice:
      case ClientAction.newQuote:
      case ClientAction.newPayment:
      case ClientAction.newTask:
      case ClientAction.newExpense:
      case ClientAction.merge:
      case ClientAction.delete:
      case ClientAction.purge:
        break;
    }
  }
}
