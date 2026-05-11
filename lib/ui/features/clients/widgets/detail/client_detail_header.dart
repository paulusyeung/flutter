import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';

/// Top-of-page identity row for the client detail screen: tinted-initials
/// avatar + display name + client number + optional "Unsynced" chip + edit
/// IconButton. Uses the same square avatar styling as the list tile so the
/// row reads as the same entity, just larger.
class ClientDetailHeader extends StatelessWidget {
  const ClientDetailHeader({super.key, required this.client});

  final Client client;

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
              Text(
                displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tokens.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (client.number.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  client.number,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.ink3,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (client.isDirty) ...[
          const SizedBox(width: InSpacing.md),
          _UnsyncedChip(tokens: tokens, label: context.tr('unsynced')),
        ],
        const SizedBox(width: InSpacing.xs),
        IconButton(
          tooltip: context.tr('edit'),
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('/clients/${client.id}/edit'),
        ),
      ],
    );
  }
}

class _UnsyncedChip extends StatelessWidget {
  const _UnsyncedChip({required this.tokens, required this.label});
  final InTheme tokens;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.sentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tokens.sent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tokens.sent,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed, required this.label});
  final String seed;
  final String label;

  // Matches the palette in `client_list_tile.dart` so the avatar's tint is
  // identical to the list row the user just tapped on.
  static const _palette = <Color>[
    Color(0xFF1F8A5B),
    Color(0xFF2A6FDB),
    Color(0xFFB07A1F),
    Color(0xFF7A3FB0),
    Color(0xFFC0392B),
    Color(0xFF0E7C8C),
    Color(0xFF3F8B2F),
    Color(0xFFD04A7A),
  ];

  @override
  Widget build(BuildContext context) {
    final tint = _palette[seed.hashCode.abs() % _palette.length];
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint,
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
