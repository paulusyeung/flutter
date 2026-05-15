import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/base_entity_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';

/// Custom handler for an entity-specific mutation kind (e.g. `addComment`).
/// Returns the inner server-response DTO if the action produced an entity to
/// upsert, or null otherwise. The dispatcher routes the response through
/// `repo.applyUpdateResponse` when non-null, mirroring archive/restore.
typedef CustomMutationHandler<TInner> =
    Future<TInner?> Function({
      required OutboxRow row,
      required Map<String, dynamic> payload,
    });

/// Generic CRUD-list dispatcher. Drives every entity whose API extends
/// `BaseEntityApi<TList, TItem>` and whose repository extends
/// `BaseEntityRepository<TDomain, TInner>`. `TItem` is the envelope returned
/// by the server (`{ data: <entity> }`); `TInner` is the inner DTO the repo
/// upserts. The DI block passes `dataOf` as a one-liner tear-off, e.g.
/// `dataOf: (item) => item.data`.
///
/// Non-CRUD actions (e.g. `addComment` against `/api/v1/activities/notes`,
/// or future `send_email` / `mark_paid`) are wired via [customActions]: each
/// entity registers a `MutationKind -> handler` map that takes precedence
/// over the standard CRUD switch.
///
/// Non-standard flows (multipart uploads, settings-only PUT) keep their own
/// dispatcher — see `CompanySyncDispatcher` and `UserSettingsSyncDispatcher`.
class BaseEntitySyncDispatcher<TItem, TInner> implements SyncDispatcher {
  BaseEntitySyncDispatcher({
    required this.api,
    required this.repo,
    required this.dataOf,
    Map<MutationKind, CustomMutationHandler<TInner>>? customActions,
  }) : customActions = customActions ?? const {};

  final BaseEntityApi<dynamic, TItem> api;
  final BaseEntityRepository<dynamic, TInner> repo;
  final TInner Function(TItem item) dataOf;
  final Map<MutationKind, CustomMutationHandler<TInner>> customActions;

  @override
  Future<void> dispatch({
    required OutboxRow row,
    required MutationKind kind,
  }) async {
    final payload = jsonDecode(row.payload) as Map<String, dynamic>;
    final custom = customActions[kind];
    if (custom != null) {
      final response = await custom(row: row, payload: payload);
      if (response != null) {
        await repo.applyUpdateResponse(
          companyId: row.companyId,
          serverResponse: response,
        );
      }
      return;
    }
    switch (kind) {
      case MutationKind.create:
        final response = await api.create(
          payload: payload,
          idempotencyKey: row.idempotencyKey,
        );
        await repo.applyCreateResponse(
          companyId: row.companyId,
          tempId: row.entityId,
          serverResponse: dataOf(response),
        );
      case MutationKind.update:
        final response = await api.update(
          id: row.entityId,
          payload: payload,
          idempotencyKey: row.idempotencyKey,
        );
        await repo.applyUpdateResponse(
          companyId: row.companyId,
          serverResponse: dataOf(response),
        );
      case MutationKind.delete:
        await api.delete(
          id: row.entityId,
          idempotencyKey: row.idempotencyKey,
          requiresPassword: row.requiresPassword,
        );
        await repo.applyDeleteResponse(
          companyId: row.companyId,
          id: row.entityId,
        );
      case MutationKind.archive:
        final response = await api.action(
          id: row.entityId,
          action: 'archive',
          idempotencyKey: row.idempotencyKey,
        );
        if (response != null) {
          await repo.applyUpdateResponse(
            companyId: row.companyId,
            serverResponse: dataOf(response),
          );
        }
      case MutationKind.restore:
        final response = await api.action(
          id: row.entityId,
          action: 'restore',
          idempotencyKey: row.idempotencyKey,
        );
        if (response != null) {
          await repo.applyUpdateResponse(
            companyId: row.companyId,
            serverResponse: dataOf(response),
          );
        }
      case MutationKind.purge:
        // POST /<entity>/:id/purge — password-gated server-side, so the
        // outbox row's `requiresPassword` flag is honored. The server's
        // response (if any) is irrelevant: the entity is gone. We ignore
        // it and let `applyPurgeResponse` drop the local row.
        await api.action(
          id: row.entityId,
          action: 'purge',
          idempotencyKey: row.idempotencyKey,
          requiresPassword: row.requiresPassword,
        );
        await repo.applyPurgeResponse(
          companyId: row.companyId,
          id: row.entityId,
        );
      case MutationKind.addComment:
      case MutationKind.documentUpload:
      case MutationKind.documentDelete:
      case MutationKind.documentVisibility:
      case MutationKind.reorder:
      case MutationKind.start:
      case MutationKind.stop:
      case MutationKind.markSent:
      case MutationKind.markPaid:
      case MutationKind.emailEntity:
      case MutationKind.scheduleEmail:
      case MutationKind.cloneToInvoice:
      case MutationKind.cloneToQuote:
      case MutationKind.cloneToCredit:
      case MutationKind.cloneToRecurring:
      case MutationKind.cloneToPurchaseOrder:
      case MutationKind.autoBill:
      case MutationKind.cancelEntity:
      case MutationKind.runTemplate:
      case MutationKind.approve:
      case MutationKind.convertToInvoice:
      case MutationKind.convertToProject:
      // Bank-integration kinds — routed via custom dispatchers on the
      // BankAccount / BankTransaction repos (not this generic base).
      // Reaching here means a non-bank repo wired one of these by
      // mistake, same configuration-error story as the PEPPOL kinds.
      case MutationKind.refreshAccounts:
      case MutationKind.matchToPayment:
      case MutationKind.linkToPayment:
      case MutationKind.matchToExpense:
      case MutationKind.linkToExpense:
      case MutationKind.convertMatched:
      case MutationKind.unlinkTransaction:
      // E-Invoice / PEPPOL kinds are company-only — handled by
      // `CompanySyncDispatcher`, not this generic dispatcher. Reaching
      // here means a non-company repo wired one into its outbox, which
      // is always a configuration error.
      case MutationKind.uploadEInvoiceCertificate:
      case MutationKind.peppolSetup:
      case MutationKind.peppolUpdate:
      case MutationKind.peppolDisconnect:
      case MutationKind.peppolAddTaxIdentifier:
      case MutationKind.peppolRemoveTaxIdentifier:
      case MutationKind.eInvoicePaymentMeans:
      case MutationKind.regenerateEInvoiceToken:
        // Non-CRUD action. Reaching here means the entity wired this kind
        // into the outbox without registering a [customActions] handler —
        // a configuration error, not a runtime condition.
        throw StateError(
          'No customActions handler registered for ${kind.wireName} on '
          '${row.entityType}',
        );
    }
  }
}
