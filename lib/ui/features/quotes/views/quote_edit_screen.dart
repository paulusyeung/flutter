import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
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
    super.key,
  });

  final String? existingId;
  final Quote? cloneFrom;

  /// Optional project id seed (`?project=<id>`). In create mode the VM
  /// resolves the project and seeds the quote's projectId + clientId so
  /// "New Quote" from a Project's Quotes tab opens a submittable form.
  final String? prefillProjectId;

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
