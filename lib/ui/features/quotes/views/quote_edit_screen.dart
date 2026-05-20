import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/quote.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/quotes/view_models/quote_edit_view_model.dart';
import 'package:admin/ui/features/quotes/widgets/edit/quote_edit_layout.dart';
import 'package:admin/ui/features/quotes/widgets/quote_actions.dart';

class QuoteEditScreen extends StatelessWidget {
  const QuoteEditScreen({
    this.existingId,
    this.cloneFrom,
    this.prefillProjectId,
    this.prefillProductId,
    super.key,
  });

  final String? existingId;
  final Quote? cloneFrom;

  /// Optional project id seed (`?project=<id>`). In create mode the VM
  /// resolves the project and seeds the quote's projectId + clientId so
  /// "New Quote" from a Project's Quotes tab opens a submittable form.
  final String? prefillProjectId;

  /// Optional product id seed (`?product=<id>`). In create mode the VM
  /// resolves the product and appends one line item built from it. Drives
  /// the Product kebab → "New Quote" flow. URL params survive cross-branch
  /// nav reliably, where `extra:` payloads are not.
  final String? prefillProductId;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Quote, QuoteEditViewModel>(
      existingId: existingId,
      entityTypeName: 'quote',
      fetchExisting: (ctx, services, companyId, id) =>
          services.quotes.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        final vm = QuoteEditViewModel(
          repo: services.quotes,
          companyId: companyId,
          clientRequiredMessage: ctx.tr('please_select_a_client'),
          existing: existing,
          cloneFrom: cloneFrom,
        );
        // Seed project + client from `?project=<id>` on first build (create
        // mode only). Wrapped in postFrame so listeners are attached before
        // notifyListeners fires — see InvoiceEditScreen for the full trace.
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
        // mode only). See InvoiceEditScreen for the rationale — URL params
        // are the only reliable seed channel across cross-branch nav,
        // and postFrame deferral ensures listeners are attached before
        // notifyListeners fires.
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
        return vm;
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_quote') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_quote')
          : (vm.draft.number.isNotEmpty
                ? '${ctx.tr('edit')} · #${vm.draft.number}'
                : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => QuoteEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (q) => q.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<QuoteAction>(
            leading: saveButton,
            items: filterForEditScreen(
              QuoteActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: QuoteActions.isLifecycle,
            ),
          ),
      saveParamFor: (a) => QuoteActions.saveParamFor(a as QuoteAction),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return QuoteActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as QuoteAction,
        );
      },
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/quotes/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
