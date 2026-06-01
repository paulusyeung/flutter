import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart' show OutboxRow;
import 'package:admin/data/models/domain/billing/invitation.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/notify_async.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/ui/features/billing_shared/activity/activity_list_card.dart';
import 'package:admin/utils/formatting.dart';

/// Shared "Sends" tab for billing-doc detail screens (invoice, quote,
/// credit, purchase order, recurring invoice). Lists each invitation —
/// the contact it went to, the sent/opened/viewed lifecycle, and any
/// delivery error — and offers a Postmark-gated "Reactivate email" action
/// for bounced/errored sends. Mirrors the legacy admin-portal
/// invoice-view-contacts surface.
///
/// `clientId` (invoices/quotes/credits/recurring) or `vendorId`
/// (purchase orders) names the entity whose contacts label each row;
/// exactly one is non-empty. Reactivation rides the outbox through
/// [onReactivate] (the owning repo's `reactivateInvitationEmail`), so it
/// retries offline and the in-flight row shows a spinner until it drains.
class BillingDocSendsTab extends StatefulWidget {
  const BillingDocSendsTab({
    super.key,
    required this.services,
    required this.companyId,
    required this.entityWireName,
    required this.entityId,
    required this.invitations,
    required this.isHosted,
    required this.onReactivate,
    this.clientId = '',
    this.vendorId = '',
  });

  final Services services;
  final String companyId;

  /// Outbox entity-type key ('invoice', 'quote', …) — scopes the pending
  /// reactivate watch so the right rows show as in-flight.
  final String entityWireName;
  final String entityId;
  final List<Invitation> invitations;

  /// Reactivation is a Postmark-only server feature (legacy gated on
  /// `isUsingPostmark`); on self-hosted SMTP the button is hidden.
  final bool isHosted;

  /// Enqueues the reactivate mutation for a message id (the owning repo's
  /// `reactivateInvitationEmail`).
  final Future<void> Function(String messageId) onReactivate;

  final String clientId;
  final String vendorId;

  @override
  State<BillingDocSendsTab> createState() => _BillingDocSendsTabState();
}

class _BillingDocSendsTabState extends State<BillingDocSendsTab> {
  Formatter? _formatter;

  @override
  void initState() {
    super.initState();
    // Resolve the company formatter once (same pattern as
    // FormatterHostMixin) so timestamps honor the company date format;
    // until it lands, rows render raw ISO.
    widget.services.formatterFor(widget.companyId).then((f) {
      if (mounted) setState(() => _formatter = f);
    });
    // List-sourced rows prefetch only page 1, so the doc's client/vendor
    // (hence its contacts) may not be in Drift yet. Deduped + safe to fire
    // unconditionally, same as the invoice actions row's `_ensureClient`.
    if (widget.clientId.isNotEmpty) {
      widget.services.clients.ensureLoaded(
        companyId: widget.companyId,
        id: widget.clientId,
      );
    } else if (widget.vendorId.isNotEmpty) {
      widget.services.vendors.ensureLoaded(
        companyId: widget.companyId,
        id: widget.vendorId,
      );
    }
  }

  Future<void> _reactivate(String messageId) => runMutationWithNotify(
    context,
    () => widget.onReactivate(messageId),
    successMsg: context.tr('email_reactivated'),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.lg(context)),
      child: StreamBuilder<Map<String, ({String label, String email})>>(
        stream: _contactsLookup(),
        builder: (context, contactsSnap) {
          final contacts =
              contactsSnap.data ??
              const <String, ({String label, String email})>{};
          return StreamBuilder<List<OutboxRow>>(
            stream: widget.services.db.outboxDao.watchPendingForEntity(
              companyId: widget.companyId,
              entityType: widget.entityWireName,
              entityId: widget.entityId,
              kind: MutationKind.reactivateEmail,
            ),
            builder: (context, pendingSnap) {
              final pendingIds = _pendingMessageIds(
                pendingSnap.data ?? const <OutboxRow>[],
              );
              return ActivityListCard(
                child: _buildList(context, contacts, pendingIds),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    Map<String, ({String label, String email})> contacts,
    Set<String> pendingIds,
  ) {
    final invitations = widget.invitations;
    if (invitations.isEmpty) {
      return EmptyState(
        icon: Icons.outgoing_mail,
        title: context.tr('no_records_found'),
      );
    }
    final children = <Widget>[];
    for (var i = 0; i < invitations.length; i++) {
      final inv = invitations[i];
      final contactId = inv.clientContactId.isNotEmpty
          ? inv.clientContactId
          : inv.vendorContactId;
      children.add(
        _InvitationRow(
          invitation: inv,
          contact: contacts[contactId],
          formatter: _formatter,
          isHosted: widget.isHosted,
          isReactivating: pendingIds.contains(inv.messageId),
          onReactivate: () => _reactivate(inv.messageId),
          isLast: i == invitations.length - 1,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Builds a `contactId → (label, email)` map from the doc's client or
  /// vendor. Falls back to an empty map until the entity loads.
  Stream<Map<String, ({String label, String email})>> _contactsLookup() {
    if (widget.clientId.isNotEmpty) {
      return widget.services.clients
          .watch(companyId: widget.companyId, id: widget.clientId)
          .map((client) => _fromClient(client));
    }
    if (widget.vendorId.isNotEmpty) {
      return widget.services.vendors
          .watch(companyId: widget.companyId, id: widget.vendorId)
          .map((vendor) => _fromVendor(vendor));
    }
    return Stream.value(const {});
  }

  static Map<String, ({String label, String email})> _fromClient(
    Client? client,
  ) {
    if (client == null) return const {};
    return {
      for (final c in client.contacts)
        c.id: (label: '${c.firstName} ${c.lastName}'.trim(), email: c.email),
    };
  }

  static Map<String, ({String label, String email})> _fromVendor(
    Vendor? vendor,
  ) {
    if (vendor == null) return const {};
    return {
      for (final c in vendor.contacts)
        c.id: (label: '${c.firstName} ${c.lastName}'.trim(), email: c.email),
    };
  }

  static Set<String> _pendingMessageIds(List<OutboxRow> rows) {
    final ids = <String>{};
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row.payload);
        if (decoded is Map && decoded['message_id'] is String) {
          ids.add(decoded['message_id'] as String);
        }
      } catch (_) {}
    }
    return ids;
  }
}

class _InvitationRow extends StatelessWidget {
  const _InvitationRow({
    required this.invitation,
    required this.contact,
    required this.formatter,
    required this.isHosted,
    required this.isReactivating,
    required this.onReactivate,
    required this.isLast,
  });

  final Invitation invitation;
  final ({String label, String email})? contact;
  final Formatter? formatter;
  final bool isHosted;
  final bool isReactivating;
  final VoidCallback onReactivate;
  final bool isLast;

  String _fmt(BuildContext context, String iso) {
    if (iso.isEmpty) return '';
    return formatter?.date(iso, showTime: true, showSeconds: false) ?? iso;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final bounced = invitation.hasBounced;
    final errored = invitation.hasError;
    final name = (contact?.label.isNotEmpty ?? false)
        ? contact!.label
        : (contact?.email.isNotEmpty ?? false)
        ? contact!.email
        : context.tr('contact');
    final lifecycle = <String>[
      if (invitation.hasBeenSent)
        '${context.tr('sent')}: ${_fmt(context, invitation.sentDate)}',
      if (invitation.hasBeenOpened)
        '${context.tr('opened')}: ${_fmt(context, invitation.openedDate)}',
      if (invitation.hasBeenViewed)
        '${context.tr('viewed')}: ${_fmt(context, invitation.viewedDate)}',
    ].join('  •  ');
    final showReactivate =
        isHosted && (bounced || errored) && invitation.messageId.isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kEntityListRowHeight),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast ? BorderSide.none : BorderSide(color: tokens.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                        ),
                      ),
                      if (contact?.email.isNotEmpty ?? false)
                        Text(
                          contact!.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.ink3,
                          ),
                        ),
                      if (lifecycle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          lifecycle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.ink3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (bounced || errored) ...[
                  SizedBox(width: InSpacing.md(context)),
                  StatusPill(
                    label: context.tr(bounced ? 'bounced' : 'error'),
                    fgColor: tokens.overdue,
                    bgColor: tokens.overdueSoft,
                    tooltip: context.tr('email_bounced'),
                  ),
                ],
              ],
            ),
            if (invitation.emailError.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                invitation.emailError,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.overdue,
                ),
              ),
            ],
            if (showReactivate) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                  ),
                  onPressed: isReactivating ? null : onReactivate,
                  icon: isReactivating
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.ink3,
                          ),
                        )
                      : const Icon(Icons.mark_email_read_outlined, size: 18),
                  label: Text(
                    context.tr(
                      isReactivating ? 'in_flight' : 'reactivate_email',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
