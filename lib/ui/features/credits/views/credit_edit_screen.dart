import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/credits/view_models/credit_edit_view_model.dart';
import 'package:admin/ui/features/credits/widgets/edit/credit_edit_layout.dart';
import 'package:admin/ui/features/credits/widgets/credit_actions.dart';

class CreditEditScreen extends StatelessWidget {
  const CreditEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;
  final Credit? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Credit, CreditEditViewModel>(
      existingId: existingId,
      entityTypeName: 'credit',
      fetchExisting: (ctx, services, companyId, id) =>
          services.credits.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        return CreditEditViewModel(
          repo: services.credits,
          companyId: companyId,
          clientRequiredMessage: ctx.tr('please_select_a_client'),
          crossClientLineItemsMessage: ctx.tr('cross_client_line_items'),
          existing: existing,
          cloneFrom: cloneFrom,
          sync: services.sync,
          connectivity: services.connectivity,
        );
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
      onSaved: (ctx, vm, saved) => goAfterEntitySave(
        ctx,
        isCreate: vm.isCreate,
        basePath: '/credits',
        savedId: saved.id,
      ),
    );
  }
}
