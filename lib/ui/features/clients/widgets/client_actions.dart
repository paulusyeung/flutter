import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';
import 'package:admin/ui/features/clients/widgets/detail/add_comment_dialog.dart';
import 'package:admin/ui/features/clients/widgets/detail/assign_group_dialog.dart';
import 'package:admin/ui/features/clients/widgets/detail/purge_client_dialog.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_edit_view_model.dart';
import 'package:admin/ui/features/payments/view_models/payment_edit_view_model.dart';
import 'package:admin/ui/features/quotes/view_models/quote_edit_view_model.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/tasks/view_models/task_edit_view_model.dart';

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
  clone,
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
    // Purge is admin/owner-only — matches React's `isAdmin || isOwner`
    // gate. Reading via `context.read` from inside the action builder
    // keeps the gate centralized here instead of plumbing the flag
    // through ClientListTile and EntityDetailActionsRow.
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canPurge = (me?.isAdmin ?? false) || (me?.isOwner ?? false);

    return [
      editActionItem(
        context: context,
        kind: ClientAction.edit,
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
      EntityActionItem(
        kind: ClientAction.assignGroup,
        icon: Icons.group_outlined,
        label: context.tr('assign_group'),
        enabled: true,
        onTap: () => onTap(ClientAction.assignGroup),
      ),
      EntityActionItem(
        kind: ClientAction.addComment,
        icon: Icons.add_comment_outlined,
        label: context.tr('add_comment'),
        enabled: true,
        onTap: () => onTap(ClientAction.addComment),
      ),
      EntityActionItem(
        kind: ClientAction.clone,
        icon: Icons.copy_outlined,
        label: context.tr('clone'),
        enabled: true,
        onTap: () => onTap(ClientAction.clone),
      ),
      EntityActionItem(
        kind: ClientAction.newInvoice,
        icon: Icons.receipt_long_outlined,
        label: context.tr('new_invoice'),
        enabled: true,
        onTap: () => onTap(ClientAction.newInvoice),
      ),
      EntityActionItem(
        kind: ClientAction.newQuote,
        icon: Icons.request_quote_outlined,
        label: context.tr('new_quote'),
        enabled: true,
        onTap: () => onTap(ClientAction.newQuote),
      ),
      EntityActionItem(
        kind: ClientAction.newPayment,
        icon: Icons.payments_outlined,
        label: context.tr('new_payment'),
        enabled: true,
        onTap: () => onTap(ClientAction.newPayment),
      ),
      EntityActionItem(
        kind: ClientAction.newTask,
        icon: Icons.check_circle_outline,
        label: context.tr('new_task'),
        enabled: true,
        onTap: () => onTap(ClientAction.newTask),
      ),
      EntityActionItem(
        kind: ClientAction.newExpense,
        icon: Icons.attach_money,
        label: context.tr('new_expense'),
        enabled: true,
        onTap: () => onTap(ClientAction.newExpense),
      ),
      EntityActionItem.disabled(
        kind: ClientAction.merge,
        icon: Icons.merge_type,
        label: context.tr('merge'),
      ),
      ?archiveActionItem(
        context: context,
        kind: ClientAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(ClientAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: ClientAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(ClientAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: ClientAction.delete,
        canDelete: !client.isDeleted,
        onTap: () => onTap(ClientAction.delete),
      ),
      ?purgeActionItem(
        context: context,
        kind: ClientAction.purge,
        canPurge: canPurge,
        onTap: () => onTap(ClientAction.purge),
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
        goEntityEdit(context, '/clients', client.id);
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
        await StandardEntityActions.archive(
          context: context,
          wireName: 'client',
          op: () =>
              services.clients.archive(companyId: companyId, id: client.id),
        );
      case ClientAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'client',
          op: () =>
              services.clients.restore(companyId: companyId, id: client.id),
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
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        // Best-effort cache warm — a user opening this action from a fresh
        // login may never have visited Group Settings, so the local Drift
        // table can be empty even when the server has groups. The dialog's
        // empty-list state covers offline / failed-refresh cases.
        unawaited(services.groupSettings.refreshAll(companyId: companyId));
        if (!context.mounted) return;
        final result = await showAssignGroupDialog(
          context,
          client: client,
          services: services,
          companyId: companyId,
        );
        if (!result.changed || !context.mounted) return;
        try {
          await services.clients.save(
            companyId: companyId,
            client: client.copyWith(groupSettingsId: result.groupId ?? ''),
          );
          if (context.mounted) {
            Notify.success(context, context.tr('updated_client'));
          }
        } catch (e) {
          if (context.mounted) {
            Notify.error(context, context.tr('could_not_save'), error: e);
          }
        }
      case ClientAction.addComment:
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        final text = await showAddCommentDialog(context);
        if (text == null || text.isEmpty || !context.mounted) return;
        await runMutationWithNotify(
          context,
          () => services.clients.addComment(
            companyId: companyId,
            clientId: client.id,
            text: text,
          ),
          successMsg: context.tr('added_comment'),
        );
      case ClientAction.delete:
        // `tmp_` ids only exist locally — the server has no row to delete
        // yet. Block instead of enqueuing a delete that the dispatcher
        // would 404 once the create round-trips. Matches the gate on
        // viewStatement / settings / addComment.
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.delete(
          context: context,
          wireName: 'client',
          op: () =>
              services.clients.delete(companyId: companyId, id: client.id),
        );
      case ClientAction.purge:
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        final ok = await showPurgeClientDialog(
          context,
          displayName: client.displayName,
        );
        if (!ok || !context.mounted) return;
        await StandardEntityActions.purge(
          context: context,
          wireName: 'client',
          op: () => services.clients.purge(companyId: companyId, id: client.id),
        );
        // Leave the detail screen before the dispatcher hard-deletes the
        // local row; without this, EntityDetailScaffold flips to the
        // "client not found" empty state right after the user confirms
        // purge — reads as an error rather than as confirmation. Going
        // to the list from the list popup is a no-op.
        if (context.mounted) context.go('/clients');
      case ClientAction.clone:
        final draft = client.copyWith(
          id: '',
          number: '',
          balance: Decimal.zero,
          paidToDate: Decimal.zero,
          creditBalance: Decimal.zero,
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          contacts: [
            for (final c in client.contacts)
              c.copyWith(
                id: '',
                updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
                isDeleted: false,
              ),
          ],
        );
        context.go('/clients/new', extra: draft);
      case ClientAction.newInvoice:
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/invoices/new',
          extra: emptyInvoice().copyWith(clientId: client.id),
        );
      case ClientAction.newQuote:
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/quotes/new',
          extra: emptyQuote().copyWith(clientId: client.id),
        );
      case ClientAction.newPayment:
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/payments/new',
          extra: emptyPayment().copyWith(clientId: client.id),
        );
      case ClientAction.newTask:
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/tasks/new',
          extra: emptyTask().copyWith(clientId: client.id),
        );
      case ClientAction.newExpense:
        if (client.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/expenses/new',
          extra: emptyExpense().copyWith(clientId: client.id),
        );
      case ClientAction.merge:
        break;
    }
  }
}
