import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/outbox_dao.dart';
import 'package:admin/data/models/domain/activity.dart';
import 'package:admin/data/services/activities_api.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/billing_shared/activity/billing_doc_activity_view_model.dart';

/// Shared Activity tab body for billing-doc detail screens (invoice,
/// quote, credit, purchase order, recurring invoice). Mirrors the client
/// activity tab — renders pending outbox `addComment` rows above the
/// synced activity stream. `onAddComment` is optional; pass null to hide
/// the add-comment affordance (the action is also reachable via the
/// per-entity actions menu).
class BillingDocActivityTab extends StatefulWidget {
  const BillingDocActivityTab({
    super.key,
    required this.entityWireName,
    required this.entityId,
    required this.companyId,
    required this.activitiesApi,
    required this.outboxDao,
    this.formatter,
    this.onAddComment,
  });

  final String entityWireName;
  final String entityId;
  final String companyId;
  final ActivitiesApi activitiesApi;
  final OutboxDao outboxDao;

  /// Pre-resolved formatter from the parent screen. Pass null while the
  /// host's `loadFormatter` is still in flight; timestamps render as raw
  /// ISO until it arrives.
  final Formatter? formatter;

  /// Callback that opens the add-comment prompt + enqueues the mutation.
  /// When null, the add-comment button is hidden — comments still flow
  /// through the entity's actions menu.
  final Future<void> Function()? onAddComment;

  @override
  State<BillingDocActivityTab> createState() => _BillingDocActivityTabState();
}

class _BillingDocActivityTabState extends State<BillingDocActivityTab> {
  late final BillingDocActivityViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = BillingDocActivityViewModel(
      api: widget.activitiesApi,
      outbox: widget.outboxDao,
      companyId: widget.companyId,
      entityWireName: widget.entityWireName,
      entityId: widget.entityId,
    );
    unawaited(_vm.ensureLoaded());
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.lg(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onAddComment != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                onPressed: widget.onAddComment,
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                label: Text(context.tr('add_comment')),
              ),
            ),
            SizedBox(height: InSpacing.md(context)),
          ],
          AnimatedBuilder(
            animation: _vm,
            builder: (context, _) => StreamBuilder<List<OutboxRow>>(
              stream: _vm.pending,
              builder: (context, snapshot) {
                final pending = snapshot.data ?? const <OutboxRow>[];
                return _buildList(context, pending);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<OutboxRow> pending) {
    if (_vm.error != null && _vm.activities.isEmpty && pending.isEmpty) {
      return ErrorView(
        message: context
            .tr('failed_to_load_with_error')
            .replaceAll(':error', '${_vm.error}'),
        onRetry: _vm.refresh,
      );
    }
    if (_vm.isLoading && _vm.activities.isEmpty && pending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (pending.isEmpty && _vm.activities.isEmpty) {
      return EmptyState(
        icon: Icons.history_toggle_off_outlined,
        title: context.tr('no_records_found'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in pending) _PendingCommentRow(row: row),
        for (final activity in _vm.activities)
          _ActivityRow(activity: activity, formatter: widget.formatter),
      ],
    );
  }
}

class _PendingCommentRow extends StatelessWidget {
  const _PendingCommentRow({required this.row});

  final OutboxRow row;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final notes = _extractNotes(row.payload);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.ink3,
              ),
            ),
          ),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notes.isNotEmpty)
                  Text(notes, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  context.tr('in_flight'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.ink3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _extractNotes(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded['notes'] is String) {
        return decoded['notes'] as String;
      }
    } catch (_) {}
    return '';
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.formatter});

  final Activity activity;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final timestamp = formatter?.date(
          activity.createdAt.toIso8601String(),
          showTime: true,
          showSeconds: false,
        ) ??
        activity.createdAt.toIso8601String();
    final author = activity.userLabel?.isNotEmpty ?? false
        ? activity.userLabel!
        : '—';
    final body = activity.isComment
        ? activity.notes
        : context
            .tr('activity_unknown')
            .replaceAll(':id', '${activity.activityTypeId}');
    final relatedInvoice =
        !activity.isComment && activity.invoiceLabel != null
            ? '${context.tr('invoice')}: ${activity.invoiceLabel}'
            : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              activity.isComment ? Icons.comment_outlined : Icons.history,
              size: 16,
              color: tokens.ink3,
            ),
          ),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        author,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: InSpacing.md(context)),
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.ink3,
                      ),
                    ),
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
                if (relatedInvoice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    relatedInvoice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.ink2,
                    ),
                  ),
                ],
                if (activity.ip.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity.ip,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.ink3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
