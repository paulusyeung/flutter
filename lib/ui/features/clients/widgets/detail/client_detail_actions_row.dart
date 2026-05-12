import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';

/// Full action set surfaced for a client. Mirrors the actions exposed in
/// admin-portal's `client_model.dart#getActions`, minus a few multiselect-
/// only / role-gated ones we don't have analogues for yet.
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

/// Builds the per-client item list and delegates layout/overflow/tooltips
/// to the shared [EntityDetailActionsRow].
class ClientDetailActionsRow extends StatelessWidget {
  const ClientDetailActionsRow({
    super.key,
    required this.client,
    required this.onAction,
  });

  final Client client;
  final void Function(ClientAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return EntityDetailActionsRow<ClientAction>(items: _items(context));
  }

  List<EntityActionItem<ClientAction>> _items(BuildContext context) {
    final canArchive = client.archivedAt == null && !client.isDeleted;
    final canRestore = client.archivedAt != null || client.isDeleted;

    EntityActionItem<ClientAction> disabled(
      ClientAction kind,
      IconData icon,
      String labelKey,
    ) => EntityActionItem(
      kind: kind,
      icon: icon,
      label: context.tr(labelKey),
      enabled: false,
    );

    return [
      EntityActionItem(
        kind: ClientAction.edit,
        icon: Icons.edit_outlined,
        label: context.tr('edit'),
        enabled: true,
        isPrimary: true,
        onTap: () => onAction(ClientAction.edit),
      ),
      EntityActionItem(
        kind: ClientAction.viewStatement,
        icon: Icons.picture_as_pdf,
        label: context.tr('view_statement'),
        enabled: true,
        onTap: () => onAction(ClientAction.viewStatement),
      ),
      EntityActionItem(
        kind: ClientAction.settings,
        icon: Icons.settings_outlined,
        label: context.tr('settings'),
        enabled: true,
        onTap: () => onAction(ClientAction.settings),
      ),
      disabled(ClientAction.assignGroup, Icons.group_outlined, 'assign_group'),
      disabled(
        ClientAction.addComment,
        Icons.add_comment_outlined,
        'add_comment',
      ),
      disabled(
        ClientAction.newInvoice,
        Icons.receipt_long_outlined,
        'new_invoice',
      ),
      disabled(
        ClientAction.newQuote,
        Icons.request_quote_outlined,
        'new_quote',
      ),
      disabled(ClientAction.newPayment, Icons.payments_outlined, 'new_payment'),
      disabled(ClientAction.newTask, Icons.check_circle_outline, 'new_task'),
      disabled(ClientAction.newExpense, Icons.attach_money, 'new_expense'),
      disabled(ClientAction.merge, Icons.merge_type, 'merge'),
      if (canArchive)
        EntityActionItem(
          kind: ClientAction.archive,
          icon: Icons.archive_outlined,
          label: context.tr('archive'),
          enabled: true,
          onTap: () => onAction(ClientAction.archive),
        ),
      if (canRestore)
        EntityActionItem(
          kind: ClientAction.restore,
          icon: Icons.unarchive_outlined,
          label: context.tr('restore'),
          enabled: true,
          onTap: () => onAction(ClientAction.restore),
        ),
      disabled(ClientAction.delete, Icons.delete_outline, 'delete'),
      disabled(ClientAction.purge, Icons.delete_forever_outlined, 'purge'),
    ];
  }
}
