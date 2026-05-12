import 'package:flutter/material.dart';
import 'package:overflow_view/overflow_view.dart';

import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';

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

class _ActionItem {
  const _ActionItem({
    required this.kind,
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  final ClientAction kind;
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
}

/// Overflow-aware action row rendered at the top of the client detail screen.
///
/// Layout mirrors admin-portal's `EntityTopFilterHeader`: each action is an
/// `OutlinedButton.icon`; whatever doesn't fit collapses into a trailing
/// "More" `PopupMenuButton`.
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
    final items = _buildItems(context);
    // The AppBar's title slot passes loose constraints (minWidth: 0), so the
    // title widget hugs its content by default — Align has no room to work
    // with. SizedBox(width: infinity) forces it to fill the slot's maxWidth;
    // Align then pushes the cluster to the right edge, which matches the
    // body's right padding via the scaffold's titleSpacing: InSpacing.lg.
    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerRight,
        child: OverflowView.flexible(
          spacing: 8,
          children: [for (final item in items) _ActionButton(item: item)],
          builder: (context, remaining) {
            final hidden = items.sublist(items.length - remaining);
            return _MoreMenu(items: hidden);
          },
        ),
      ),
    );
  }

  List<_ActionItem> _buildItems(BuildContext context) {
    final canArchive = client.archivedAt == null && !client.isDeleted;
    final canRestore = client.archivedAt != null || client.isDeleted;

    _ActionItem disabled(ClientAction kind, IconData icon, String labelKey) =>
        _ActionItem(
          kind: kind,
          icon: icon,
          label: context.tr(labelKey),
          enabled: false,
        );

    return [
      _ActionItem(
        kind: ClientAction.edit,
        icon: Icons.edit_outlined,
        label: context.tr('edit'),
        enabled: true,
        onTap: () => onAction(ClientAction.edit),
      ),
      _ActionItem(
        kind: ClientAction.viewStatement,
        icon: Icons.picture_as_pdf,
        label: context.tr('view_statement'),
        enabled: true,
        onTap: () => onAction(ClientAction.viewStatement),
      ),
      disabled(ClientAction.settings, Icons.settings, 'settings'),
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
        _ActionItem(
          kind: ClientAction.archive,
          icon: Icons.archive_outlined,
          label: context.tr('archive'),
          enabled: true,
          onTap: () => onAction(ClientAction.archive),
        ),
      if (canRestore)
        _ActionItem(
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.item});
  final _ActionItem item;

  @override
  Widget build(BuildContext context) {
    // The primary "Edit" action mirrors the wide-mode "New client" button on
    // the list screen — FilledButton with the same minimumSize / padding
    // override. Other actions stay as OutlinedButtons.
    final isPrimary = item.kind == ClientAction.edit;
    final Widget button = isPrimary
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: Icon(item.icon, size: 18),
            label: Text(item.label),
            onPressed: item.enabled ? item.onTap : null,
          )
        : OutlinedButton.icon(
            // CLAUDE.md: OutlinedButton inside a Row must override the theme's
            // Size.fromHeight(40) default, otherwise the infinite minWidth
            // crashes the surrounding Row layout.
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            icon: Icon(item.icon, size: 18),
            label: Text(item.label),
            onPressed: item.enabled ? item.onTap : null,
          );
    if (item.enabled) return button;
    return Tooltip(message: context.tr('coming_soon'), child: button);
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.items});
  final List<_ActionItem> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ClientAction>(
      tooltip: context.tr('more'),
      onSelected: (kind) {
        final item = items.firstWhere((i) => i.kind == kind);
        item.onTap?.call();
      },
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<ClientAction>(
            value: item.kind,
            enabled: item.enabled,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 18),
                const SizedBox(width: 12),
                Text(item.label),
              ],
            ),
          ),
      ],
      // Wrap the trigger as an OutlinedButton so it sits flush with the
      // other action buttons (same height, border, padding). AbsorbPointer
      // lets the parent PopupMenuButton handle the tap.
      child: AbsorbPointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          icon: const Icon(Icons.more_horiz, size: 18),
          label: Text(context.tr('more')),
        ),
      ),
    );
  }
}
