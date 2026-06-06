import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/after_save_create_action.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/billing_shared/seed_client_invitations.dart';
import 'package:admin/ui/features/credits/view_models/credit_edit_view_model.dart';
import 'package:admin/ui/features/credits/widgets/edit/credit_edit_layout.dart';
import 'package:admin/ui/features/credits/widgets/credit_actions.dart';

class CreditEditScreen extends StatelessWidget {
  const CreditEditScreen({
    this.existingId,
    this.cloneFrom,
    this.prefillClientId,
    super.key,
  });

  final String? existingId;
  final Credit? cloneFrom;

  /// Optional client id seed (`?client=<id>`). In create mode the form opens
  /// with this client pre-selected (Clients list ⋮ → New Credit). Delivered
  /// via query param because `extra:` is dropped on the cross-branch hop.
  final String? prefillClientId;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Credit, CreditEditViewModel>(
      existingId: existingId,
      entityTypeName: 'credit',
      fetchExisting: (ctx, services, companyId, id) =>
          services.credits.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        // `?client=<id>` (Clients list ⋮ → New Credit): synthesize a draft
        // carrying just the clientId so the client is set from first build —
        // mirrors ProjectEditScreen; the contact seed below then fires.
        Credit? clone = cloneFrom;
        if (clone == null && prefillClientId != null && existing == null) {
          clone = emptyCredit().copyWith(clientId: prefillClientId!);
        }
        final vm = CreditEditViewModel(
          repo: services.credits,
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
        // Seed contact invitations when the draft arrived with a client
        // already set (New Credit from a Client's actions or embedded list)
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
          existingId == null ? ctx.tr('new_credit') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_credit')
          : (vm.draft.number.isNotEmpty
                ? '${ctx.tr('edit')} · #${vm.draft.number}'
                : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => CreditEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (c) => c.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<CreditAction>(
            leading: saveButton,
            items: filterForEditScreen(
              CreditActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: CreditActions.isLifecycle,
            ),
          ),
      saveParamFor: (a) => CreditActions.saveParamFor(a as CreditAction),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return CreditActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as CreditAction,
        );
      },
      // Create-mode: resolve the tmp id to the real one so navigating actions
      // (Send Email, View PDF, Apply to Invoice) keep their navigation.
      onAfterSaveActionOnCreate: (ctx, saved, a) {
        final services = ctx.read<Services>();
        final companyId = services.auth.session.value!.currentCompanyId;
        return dispatchAfterSaveOnCreate<Credit, CreditAction>(
          ctx,
          saved: saved,
          idOf: (credit) => credit.id,
          withId: (credit, id) => credit.copyWith(id: id),
          resolveId: services.credits.resolveId,
          action: a as CreditAction,
          navigatesOnCreate: CreditActions.navigatesOnCreate,
          dispatch: (c, resolved, act) =>
              CreditActions.dispatch(c, services, companyId, resolved, act),
        );
      },
      onSaved: (ctx, vm, saved) => goAfterEntitySave(
        ctx,
        isCreate: vm.isCreate,
        basePath: '/credits',
        savedId: saved.id,
      ),
    );
  }
}
