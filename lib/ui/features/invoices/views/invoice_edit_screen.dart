import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/domain/billing/invoice_lock.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/after_save_create_action.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/billing_shared/seed_client_invitations.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_edit_view_model.dart';
import 'package:admin/ui/features/invoices/widgets/edit/invoice_edit_layout.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_actions.dart';
import 'package:admin/ui/features/invoices/widgets/invoice_locked_dialog.dart';

/// M1 stub of the Invoice edit + create screen. Renders a "coming soon"
/// body so the route compiles; the M3 milestone replaces this with the
/// full tabbed layout (Details / Contacts / Items / Notes / PDF / E-Invoice)
/// backed by [InvoiceEditViewModel]'s full setter surface.
class InvoiceEditScreen extends StatelessWidget {
  const InvoiceEditScreen({
    this.existingId,
    this.cloneFrom,
    this.prefillProjectId,
    this.prefillProductId,
    super.key,
  });

  final String? existingId;

  /// When non-null and [existingId] is null, the create form opens
  /// pre-filled with this invoice's fields. Identity-bearing fields (id,
  /// number, timestamps, locked flag, balance) are stripped by the caller.
  final Invoice? cloneFrom;

  /// Optional project id seed (`?project=<id>`). In create mode the VM
  /// resolves the project and seeds the invoice's projectId + clientId so
  /// "New Invoice" from a Project's Invoices tab opens a submittable form.
  final String? prefillProjectId;

  /// Optional product id seed (`?product=<id>`). In create mode the VM
  /// resolves the product and appends one line item built from it. Used
  /// by the Product kebab → "New Invoice" flow — URL params survive
  /// cross-StatefulShellRoute-branch nav reliably, where `extra:` doesn't.
  final String? prefillProductId;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Invoice, InvoiceEditViewModel>(
      existingId: existingId,
      entityTypeName: 'invoice',
      fetchExisting: (ctx, services, companyId, id) async {
        final invoice = await services.invoices
            .watch(companyId: companyId, id: id)
            .first;
        // Hard-block editing a locked invoice. The action-menu /
        // detail-button / list-menu paths are already blocked in
        // InvoiceActions.dispatch; gating here (the single fetch the
        // scaffold already does) additionally covers a direct deep link to
        // `/invoices/:id/edit`, which never goes through dispatch. tmp_ /
        // empty-id drafts are never locked. The scaffold still renders its
        // normal titled loading chrome — the post-frame dialog + nav fire
        // immediately, so there's no extra chrome-less spinner.
        if (invoice != null && id.isNotEmpty && !id.startsWith('tmp_')) {
          final reason = await resolveInvoiceLockReason(
            settings: services.settings,
            companyId: companyId,
            invoice: invoice,
          );
          if (reason != InvoiceLockReason.none) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!ctx.mounted) return;
              await showInvoiceLockedDialog(ctx, reason);
              if (!ctx.mounted) return;
              // Deep-link entry may have no back stack — land on the detail
              // screen (which shows the lock banner) instead of asserting.
              ctx.canPop() ? ctx.pop() : ctx.go('/invoices/$id');
            });
          }
        }
        return invoice;
      },
      buildVm: (ctx, services, companyId, existing) {
        // "New Invoice" from a Client's actions stages the clientId on
        // `Services` (go_router drops route `extra:`/query on the cross-branch
        // jump from the Clients list). Consume it and synthesize a draft
        // carrying just the clientId so the client is set from first build —
        // the contact seed below then fires. Mirrors ProjectEditScreen.
        final seedClientId = services.takeClientSeed('/invoices');
        Logger('seed').warning(
          'invoice.buildVm existing=${existing != null} '
          'cloneFrom=${cloneFrom != null} took=$seedClientId',
        ); // TEMP diagnostic
        Invoice? clone = cloneFrom;
        if (clone == null && existing == null && seedClientId != null) {
          clone = emptyInvoice().copyWith(clientId: seedClientId);
        }
        final vm = InvoiceEditViewModel(
          repo: services.invoices,
          companyId: companyId,
          clientRequiredMessage: ctx.tr('please_select_a_client'),
          crossClientLineItemsMessage: ctx.tr('cross_client_line_items'),
          partialInvalidMessage: ctx.tr('partial_value'),
          existing: existing,
          cloneFrom: clone,
          useCommaAsDecimalPlace:
              services
                  .formatterIfReady(companyId)
                  ?.settings
                  .useCommaAsDecimalPlace ??
              false,
          sync: services.sync,
          connectivity: services.connectivity,
        );
        // Seed project + client from `?project=<id>` on first build (create
        // mode only). Fire-and-forget; no-op if the project isn't cached.
        //
        // Wrapped in addPostFrameCallback so the watch starts AFTER the
        // scaffold's first paint has mounted the outer `ListenableBuilder`
        // and inner `AnimatedBuilder`. Without the deferral, a fast Drift
        // emission can land before any listener has subscribed to the vm
        // — `notifyListeners` fires into the void, and any subwidget that
        // caches state internally on first mount (e.g. LineItemTableDesktop's
        // _rows) never picks up the seed. Hot-reload's reassemble() then
        // becomes the only way to recover. See plan PR3 for the trace.
        final seedId = prefillProjectId;
        if (seedId != null && seedId.isNotEmpty && existing == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(
              services.projects
                  .watch(companyId: companyId, id: seedId)
                  .first
                  .then((project) async {
                    if (project == null) return;
                    vm.setProjectId(project.id);
                    // Resolve the client so its "add to invoices" contacts
                    // seed invitations, same as picking it in the dropdown.
                    final client = await services.clients
                        .watch(companyId: companyId, id: project.clientId)
                        .first;
                    if (client != null) {
                      vm.selectClient(client.id, client.contacts);
                    } else {
                      vm.setClientId(project.clientId);
                    }
                  })
                  .catchError((Object _) {}),
            );
          });
        }
        // Seed a line item from `?product=<id>` on first build (create
        // mode only). Watches the product from Drift and appends a line
        // item shaped like the line-item picker output once resolved.
        // Drives the Product kebab → "New Invoice" flow — URL params
        // survive cross-branch nav where `extra:` payloads are unreliable.
        // Deferred via postFrame for the same reason as prefillProjectId
        // above.
        final productSeedId = prefillProductId;
        if (productSeedId != null &&
            productSeedId.isNotEmpty &&
            existing == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(
              services.products
                  .watch(companyId: companyId, id: productSeedId)
                  .first
                  .then((product) {
                    if (product == null) return;
                    vm.addLineItem(lineItemForProduct(product));
                  })
                  .catchError((Object _) {}),
            );
          });
        }
        // Seed contact invitations when the draft arrived with a client
        // already set (New Invoice from a Client's actions or embedded list)
        // but no invitations yet — mirrors picking the client in the dropdown.
        if (existing == null) {
          seedClientInvitationsFromPrefill(
            services: services,
            companyId: companyId,
            vm: vm,
          );
        }
        return vm;
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_invoice') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_invoice')
          : (vm.draft.number.isNotEmpty
                ? '${ctx.tr('edit')} · #${vm.draft.number}'
                : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => InvoiceEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (i) => i.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<InvoiceAction>(
            leading: saveButton,
            items: filterForEditScreen(
              InvoiceActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: InvoiceActions.isLifecycle,
            ),
          ),
      saveParamFor: (a) => InvoiceActions.saveParamFor(a as InvoiceAction),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return InvoiceActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as InvoiceAction,
        );
      },
      // On create the save returns a tmp-id draft; resolve it to the real id
      // so server-bound actions work, and let navigating ones (Send Email, …)
      // own the post-save navigation instead of the detail redirect.
      onAfterSaveActionOnCreate: (ctx, saved, a) {
        final services = ctx.read<Services>();
        final companyId = services.auth.session.value!.currentCompanyId;
        return dispatchAfterSaveOnCreate<Invoice, InvoiceAction>(
          ctx,
          saved: saved,
          idOf: (i) => i.id,
          withId: (i, id) => i.copyWith(id: id),
          resolveId: services.invoices.resolveId,
          action: a as InvoiceAction,
          navigatesOnCreate: InvoiceActions.navigatesOnCreate,
          dispatch: (c, resolved, act) =>
              InvoiceActions.dispatch(c, services, companyId, resolved, act),
        );
      },
      onSaved: (ctx, vm, saved) => goAfterEntitySave(
        ctx,
        isCreate: vm.isCreate,
        basePath: '/invoices',
        savedId: saved.id,
      ),
    );
  }
}
