import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/avatar_tint.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/utils/formatting.dart';

/// Top-of-page identity row for the client detail screen.
///
/// Layout: tinted-initials avatar | name + number + created/updated subtitle
/// | status pills stack. Action buttons (Edit + `…` overflow) live in the
/// screen's AppBar, not here.
///
/// The avatar's tint mirrors the list-tile palette so a user tapping a list
/// row sees "the same" entity here, just larger.
class ClientDetailHeader extends StatelessWidget {
  const ClientDetailHeader({super.key, required this.client, this.formatter});

  final Client client;
  final Formatter? formatter;

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
