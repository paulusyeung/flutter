import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/domain/billing/invoice_lock.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
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

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Invoice, InvoiceEditViewModel>(
      existingId: existingId,
      entityTypeName: 'invoice',
      fetchExisting: (ctx, services, companyId, id) async {
        final invoice =
            await services.invoices.watch(companyId: companyId, id: id).first;
        // Hard-block editing a locked invoice. The action-menu /
        // detail-button / list-menu paths are already blocked in
        // InvoiceActions.dispatch; gating here (the single fetch the
        // scaffold already does) additionally covers a direct deep link to
        // `/invoices/:id/edit`, which never goes through dispatch. tmp_ /
        // empty-id drafts are never locked. The scaffold still renders its
        // normal titled loading chrome — the post-frame dialog + nav fire
        // immediately, so there's no extra chrome-less spinner.
        if (invoice != null &&
            id.isNotEmpty &&
            !id.startsWith('tmp_')) {
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
        final vm = InvoiceEditViewModel(
          repo: services.invoices,
          companyId: companyId,
          existing: existing,
          cloneFrom: cloneFrom,
        );
        // Seed project + client from `?project=<id>` on first build (create
        // mode only). Fire-and-forget; no-op if the project isn't cached.
        final seedId = prefillProjectId;
        if (seedId != null && seedId.isNotEmpty && existing == null) {
          unawaited(
            services.projects
                .watch(companyId: companyId, id: seedId)
                .first
                .then((project) {
                  if (project != null) {
                    vm.setProjectId(project.id);
                    vm.setClientId(project.clientId);
                  }
                })
                .catchError((Object _) {}),
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
      actionsBuilder: (ctx, vm, onTap) => EntityOverflowActionBar<InvoiceAction>(
        items: filterForEditScreen(
          InvoiceActions.itemsFor(
            ctx,
            vm.draft,
            (a) => onTap(a),
          ),
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
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/invoices/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
