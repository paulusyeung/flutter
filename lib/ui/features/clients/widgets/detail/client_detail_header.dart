import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/avatar_tint.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/utils/formatting.dart';

/// Possible actions surfaced in the header's `…` menu.
enum ClientHeaderAction { archive, restore, delete, newInvoice, merge }

/// Top-of-page identity row for the client detail screen.
///
/// Layout: tinted-initials avatar | name + number + created/updated subtitle
/// | status pills stack | edit button | action menu.
///
/// The avatar's tint mirrors the list-tile palette so a user tapping a list
/// row sees "the same" entity here, just larger.
class ClientDetailHeader extends StatelessWidget {
  const ClientDetailHeader({
    super.key,
    required this.client,
    this.formatter,
    this.onAction,
  });

  final Client client;
  final Formatter? formatter;

  /// Called when the user picks an entry from the `…` menu. Null hides the
  /// menu entirely (e.g. while still loading).
  final ValueChanged<ClientHeaderAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final displayName = _displayName(context, client);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(seed: client.id, label: _initials(displayName)),
        const SizedBox(width: InSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (client.number.isNotEmpty) ...[
                    const SizedBox(width: InSpacing.sm),
                    Text(
                      '#${client.number}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.ink3,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              _Timestamps(client: client, formatter: formatter, tokens: tokens),
            ],
          ),
        ),
        _HeaderPills(client: client, tokens: tokens),
        const SizedBox(width: InSpacing.sm),
        IconButton(
          tooltip: context.tr('edit'),
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('/clients/${client.id}/edit'),
        ),
        if (onAction != null) _ActionMenu(client: client, onAction: onAction!),
      ],
    );
  }
}

class _Timestamps extends StatelessWidget {
  const _Timestamps({
    required this.client,
    required this.formatter,
    required this.tokens,
  });
  final Client client;
  final Formatter? formatter;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = _format(client.createdAt);
    final updated = _format(client.updatedAt);
    final parts = <String>[
      if (created.isNotEmpty) context.tr('created_short', {'date': created}),
      if (updated.isNotEmpty) context.tr('updated_short', {'date': updated}),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
    );
  }

  String _format(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '';
    final f = formatter;
    if (f == null) return '';
    // `Formatter.date` takes the ISO string the server uses; our domain
    // model already stores a real DateTime, so re-encode.
    return f.date(dt.toIso8601String().split('T').first);
  }
}

class _HeaderPills extends StatelessWidget {
  const _HeaderPills({required this.client, required this.tokens});
  final Client client;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[];
    if (client.isDeleted) {
      pills.add(
        StatusPill(
          label: context.tr('deleted'),
          fgColor: tokens.overdue,
          bgColor: tokens.overdueSoft,
          tooltip: context.tr('deleted_soft_delete_tooltip'),
        ),
      );
    } else if (client.archivedAt != null) {
      pills.add(
        StatusPill(
          label: context.tr('archived'),
          fgColor: tokens.draft,
          bgColor: tokens.draftSoft,
          tooltip: context.tr('archived'),
        ),
      );
    }
    if (client.isDirty) {
      pills.add(
        StatusPill(
          label: context.tr('unsynced'),
          fgColor: tokens.sent,
          bgColor: tokens.sentSoft,
          tooltip: context.tr('unsynced_pending_outbox_tooltip'),
        ),
      );
    }
    if (pills.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, children: pills);
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.client, required this.onAction});
  final Client client;
  final ValueChanged<ClientHeaderAction> onAction;

  @override
  Widget build(BuildContext context) {
    final canArchive = client.archivedAt == null && !client.isDeleted;
    final canRestore = client.archivedAt != null || client.isDeleted;
    return PopupMenuButton<ClientHeaderAction>(
      tooltip: context.tr('actions'),
      icon: const Icon(Icons.more_vert),
      onSelected: onAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ClientHeaderAction.newInvoice,
          enabled: false,
          child: _MenuItem(
            icon: Icons.receipt_long_outlined,
            label: context.tr('new_invoice'),
            subtitle: context.tr('coming_soon_subtitle'),
          ),
        ),
        const PopupMenuDivider(),
        if (canArchive)
          PopupMenuItem(
            value: ClientHeaderAction.archive,
            child: _MenuItem(
              icon: Icons.archive_outlined,
              label: context.tr('archive'),
            ),
          ),
        if (canRestore)
          PopupMenuItem(
            value: ClientHeaderAction.restore,
            child: _MenuItem(
              icon: Icons.unarchive_outlined,
              label: context.tr('restore'),
            ),
          ),
        PopupMenuItem(
          value: ClientHeaderAction.delete,
          enabled: false,
          child: _MenuItem(
            icon: Icons.delete_outline,
            label: context.tr('delete'),
            subtitle: context.tr('coming_soon_subtitle'),
            destructive: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: ClientHeaderAction.merge,
          enabled: false,
          child: _MenuItem(
            icon: Icons.merge_type,
            label: context.tr('merge'),
            subtitle: context.tr('coming_soon_subtitle'),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final color = destructive ? tokens.overdue : tokens.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: InSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: color)),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: tokens.ink3),
              ),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed, required this.label});
  final String seed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: avatarTintFor(seed),
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          height: 1,
        ),
      ),
    );
  }
}

String _displayName(BuildContext context, Client c) {
  if (c.displayName.isNotEmpty) return c.displayName;
  if (c.name.isNotEmpty) return c.name;
  return context.tr('no_name_fallback');
}

String _initials(String name) {
  final nonLetter = RegExp(r'\P{L}', unicode: true);
  final words = name
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll(nonLetter, ''))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.characters.first.toUpperCase();
  return (words.first.characters.first + words.last.characters.first)
      .toUpperCase();
}
