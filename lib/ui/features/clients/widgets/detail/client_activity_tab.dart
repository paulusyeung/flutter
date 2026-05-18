import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/billing_shared/activity/activity_list_card.dart';
import 'package:admin/ui/features/billing_shared/activity/activity_record_row.dart';
import 'package:admin/ui/features/clients/view_models/client_activity_view_model.dart';
import 'package:admin/ui/features/clients/widgets/detail/add_comment_dialog.dart';

/// Activity tab content rendered inside `ClientDetailTabs`. Owns its own
/// [ClientActivityViewModel] so the data fetch is scoped to this tab's
/// lifecycle — switching to a different tab doesn't tear it down (the
/// parent keeps the tab body alive via `IndexedStack`).
class ClientActivityTabBody extends StatefulWidget {
  const ClientActivityTabBody({
    required this.client,
    required this.formatter,
    super.key,
  });

  final Client client;

  /// Pre-resolved formatter from the parent screen. Pass null while the
  /// host's `loadFormatter` is still in flight; timestamps will render as
  /// raw ISO until it arrives.
  final Formatter? formatter;

  @override
  State<ClientActivityTabBody> createState() => _ClientActivityTabBodyState();
}

class _ClientActivityTabBodyState extends State<ClientActivityTabBody> {
  late final ClientActivityViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = ClientActivityViewModel(
      api: _services.activities,
      outbox: _services.db.outboxDao,
      companyId: _companyId,
      clientId: widget.client.id,
    );
    unawaited(_vm.ensureLoaded());
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _onAddComment() async {
    if (widget.client.id.startsWith('tmp_')) {
      Notify.error(context, context.tr('sync_first'));
      return;
    }
    final text = await showAddCommentDialog(context);
    if (text == null || text.isEmpty || !mounted) return;
    await runMutationWithNotify(
      context,
      () => _services.clients.addComment(
        companyId: _companyId,
        clientId: widget.client.id,
        text: text,
      ),
      successMsg: context.tr('added_comment'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: _onAddComment,
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: Text(context.tr('add_comment')),
            ),
          ),
          SizedBox(height: InSpacing.md(context)),
          AnimatedBuilder(
            animation: _vm,
            builder: (context, _) => StreamBuilder<List<OutboxRow>>(
              stream: _vm.pending,
              builder: (context, snapshot) {
                final pending = snapshot.data ?? const <OutboxRow>[];
                return ActivityListCard(child: _buildList(context, pending));
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
    final total = pending.length + _vm.activities.length;
    final children = <Widget>[];
    var i = 0;
    for (final row in pending) {
      children.add(_PendingCommentRow(row: row, isLast: i == total - 1));
      i++;
    }
    for (final activity in _vm.activities) {
      children.add(
        ActivityRecordRow(
          activity: activity,
          formatter: widget.formatter,
          isLast: i == total - 1,
        ),
      );
      i++;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _PendingCommentRow extends StatelessWidget {
  const _PendingCommentRow({required this.row, this.isLast = false});

  final OutboxRow row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final notes = _extractNotes(row.payload);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kEntityListRowHeight),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast ? BorderSide.none : BorderSide(color: tokens.border),
          ),
        ),
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
