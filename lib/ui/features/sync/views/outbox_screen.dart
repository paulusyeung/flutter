import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';

/// Lists every outbox row for the current company so the user can inspect
/// queued mutations, retry dead ones, or discard them.
///
/// Driven by [OutboxDao.watchAll]. Rows render the entity icon (from
/// [EntityRegistry]), a state pill, the mutation kind, retry count, the
/// last server error, and — for 422s — the per-field validation messages
/// the dead row carries in `field_errors_json`.
class OutboxScreen extends StatelessWidget {
  const OutboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: services.auth.session,
      builder: (context, session, _) {
        if (session == null) return const SizedBox.shrink();
        final companyId = session.currentCompanyId;
        return Scaffold(
          backgroundColor: context.inTheme.bg,
          appBar: AppBar(title: Text(context.tr('outbox'))),
          body: StreamBuilder<List<OutboxRow>>(
            stream: services.db.outboxDao.watchAll(companyId),
            builder: (context, snap) {
              final rows = snap.data ?? const <OutboxRow>[];
              if (rows.isEmpty) {
                return EmptyState(
                  icon: Icons.outbox_outlined,
                  title: context.tr('sync_queue_empty'),
                  subtitle: context.tr('sync_queue_empty_subtitle'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: InSpacing.lg,
                  vertical: InSpacing.md,
                ),
                itemCount: rows.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: InSpacing.sm),
                itemBuilder: (context, i) => _OutboxTile(row: rows[i]),
              );
            },
          ),
        );
      },
    );
  }
}

class _OutboxTile extends StatelessWidget {
  const _OutboxTile({required this.row});

  final OutboxRow row;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final handlers = services.entityRegistry.byWireName(row.entityType);
    final icon = handlers?.icon ?? Icons.help_outline;
    final fieldErrors = _decodeFieldErrors(row.fieldErrorsJson);

    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(InRadii.r2),
      child: InkWell(
        borderRadius: BorderRadius.circular(InRadii.r2),
        onTap: handlers == null
            ? null
            : () => _openEntity(context, handlers, row),
        child: Padding(
          padding: const EdgeInsets.all(InSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: tokens.ink2),
                  const SizedBox(width: InSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _humanizeEntity(row.entityType),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: tokens.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.entityId,
                          style: TextStyle(color: tokens.ink3, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatePill(state: row.state),
                ],
              ),
              const SizedBox(height: InSpacing.sm),
              Row(
                children: [
                  Text(
                    _humanizeKind(context, row.mutationKind),
                    style: TextStyle(
                      color: tokens.ink2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (row.attempts > 0) ...[
                    const SizedBox(width: InSpacing.sm),
                    Text(
                      _attemptsLabel(context, row.attempts),
                      style: TextStyle(color: tokens.ink3, fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                  _RowMenu(row: row, handlers: handlers),
                ],
              ),
              if (row.lastError != null && row.lastError!.isNotEmpty) ...[
                const SizedBox(height: InSpacing.sm),
                Text(
                  row.lastError!,
                  style: TextStyle(color: tokens.overdue, fontSize: 12),
                ),
              ],
              if (fieldErrors.isNotEmpty) ...[
                const SizedBox(height: InSpacing.sm),
                _FieldErrors(errors: fieldErrors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Map<String, List<String>> _decodeFieldErrors(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          k,
          (v as List).map((e) => e.toString()).toList(growable: false),
        ),
      );
    } catch (_) {
      return const {};
    }
  }

  static String _humanizeEntity(String wireName) => _titleCaseSnake(wireName);

  static String _humanizeKind(BuildContext context, String kind) {
    // Known kinds reuse localized labels; future `action:*` values pass
    // through as-is so we never block sync on a missing translation.
    const known = {'create', 'update', 'delete', 'archive', 'restore'};
    if (known.contains(kind)) return context.tr(kind);
    return kind;
  }

  static String _attemptsLabel(BuildContext context, int attempts) {
    final key = attempts == 1
        ? 'attempts_count_singular'
        : 'attempts_count_plural';
    return context.tr(key, {'count': attempts.toString()});
  }

  static void _openEntity(
    BuildContext context,
    EntityHandlers handlers,
    OutboxRow row,
  ) {
    context.go(_destinationFor(handlers, row));
  }
}

/// Route to navigate to when the user "Open"s an outbox row. Dead rows
/// land on the edit form so the user can fix the rejected fields directly;
/// pending / in-flight rows land on the detail screen since the local
/// state already reflects the in-progress mutation.
String _destinationFor(EntityHandlers handlers, OutboxRow row) {
  final isDead = row.state == 'dead';
  final suffix = isDead ? '/edit' : '';
  return '${handlers.routePath}/${row.entityId}$suffix';
}

/// Split a `snake_case` key into title-cased words. Used for both entity
/// wire names (`user_settings` → `User Settings`) and API field keys
/// (`vat_number` → `Vat Number`). Server keys are stable English, so no
/// localization is required.
String _titleCaseSnake(String key) {
  if (key.isEmpty) return key;
  return key
      .split('_')
      .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
      .join(' ');
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});
  final String state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final (label, fg, bg) = switch (state) {
      'pending' => (
        context.tr('pending_sync'),
        tokens.partial,
        tokens.partialSoft,
      ),
      'in_flight' => (context.tr('in_flight'), tokens.sent, tokens.sentSoft),
      'dead' => (context.tr('sync_failed'), tokens.overdue, tokens.overdueSoft),
      _ => (state, tokens.draft, tokens.draftSoft),
    };
    return StatusPill(label: label, fgColor: fg, bgColor: bg);
  }
}

class _FieldErrors extends StatelessWidget {
  const _FieldErrors({required this.errors});
  final Map<String, List<String>> errors;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final flat = <(String, String)>[];
    for (final entry in errors.entries) {
      for (final msg in entry.value) {
        flat.add((entry.key, msg));
      }
    }
    final visible = flat.take(3).toList();
    final overflow = flat.length - visible.length;
    return Container(
      padding: const EdgeInsets.all(InSpacing.sm),
      decoration: BoxDecoration(
        color: tokens.overdueSoft,
        borderRadius: BorderRadius.circular(InRadii.r1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (field, message) in visible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.ink2,
                  ),
                  children: [
                    TextSpan(
                      text: '${_humanizeFieldKey(field)}: ',
                      style: TextStyle(
                        color: tokens.overdue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: message),
                  ],
                ),
              ),
            ),
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                context.tr('plus_n_more', {'count': overflow.toString()}),
                style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
              ),
            ),
        ],
      ),
    );
  }

  static String _humanizeFieldKey(String key) => _titleCaseSnake(key);
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.row, required this.handlers});
  final OutboxRow row;
  final EntityHandlers? handlers;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return PopupMenuButton<String>(
      tooltip: '',
      iconSize: 18,
      onSelected: (action) async {
        switch (action) {
          case 'retry':
            await services.db.outboxDao.retryDead(
              id: row.id,
              now: DateTime.now().millisecondsSinceEpoch,
            );
            unawaited(services.sync.drainOnce(companyId: row.companyId));
          case 'discard':
            await services.db.outboxDao.deleteRow(row.id);
          case 'open':
            if (handlers != null && context.mounted) {
              context.go(_destinationFor(handlers!, row));
            }
        }
      },
      itemBuilder: (context) => [
        if (row.state == 'dead')
          PopupMenuItem<String>(
            value: 'retry',
            child: Row(
              children: [
                const Icon(Icons.refresh, size: 16),
                const SizedBox(width: InSpacing.sm),
                Text(context.tr('retry')),
              ],
            ),
          ),
        if (handlers != null)
          PopupMenuItem<String>(
            value: 'open',
            child: Row(
              children: [
                const Icon(Icons.open_in_new, size: 16),
                const SizedBox(width: InSpacing.sm),
                Text(context.tr('open_entity')),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'discard',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 16),
              const SizedBox(width: InSpacing.sm),
              Text(context.tr('discard')),
            ],
          ),
        ),
      ],
    );
  }
}
