import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_edit_view_model.dart';
import 'package:admin/ui/features/invoices/widgets/edit/invoice_edit_layout.dart';

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
      fetchExisting: (ctx, services, companyId, id) =>
          services.invoices.watch(companyId: companyId, id: id).first,
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

