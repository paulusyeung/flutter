import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/vendors/view_models/vendor_edit_view_model.dart';
import 'package:admin/ui/features/vendors/widgets/edit/vendor_edit_layout.dart';
import 'package:admin/ui/features/vendors/widgets/vendor_actions.dart';

/// Edit + Create form for a Vendor. Mirror of `ClientEditScreen` — the
/// outer scaffold owns VM lifecycle, the loading-state Scaffold, dead-
/// outbox-row 422 recovery, and post-save cleanup. This widget only
/// contributes the per-entity wiring: how to fetch the existing row, how
/// to build the VM, the title, and the form body.
class VendorEditScreen extends StatelessWidget {
  const VendorEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;

  /// When non-null and [existingId] is null, the create form opens
  /// pre-filled with this vendor's fields. Identity-bearing fields (id,
  /// number, balances, timestamps, contact ids) are stripped by the
  /// caller before navigating.
  final Vendor? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Vendor, VendorEditViewModel>(
      existingId: existingId,
      entityTypeName: 'vendor',
      fetchExisting: (ctx, services, companyId, id) =>
          services.vendors.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) => VendorEditViewModel(
        repo: services.vendors,
        companyId: companyId,
        nameRequiredMessage: ctx.tr('please_enter_a_name'),
        existing: existing,
        cloneFrom: cloneFrom,
        sync: services.sync,
        connectivity: services.connectivity,
      ),
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_vendor') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) {
        if (vm.isCreate) return ctx.tr('new_vendor');
        final name = vm.draft.name;
        return name.isNotEmpty ? '${ctx.tr('edit')} · $name' : ctx.tr('edit');
      },
      bodyBuilder: (ctx, vm) => VendorEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (v) => v.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<VendorAction>(
            leading: saveButton,
            items: filterForEditScreen(
              VendorActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: VendorActions.isLifecycle,
            ),
          ),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return VendorActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as VendorAction,
        );
      },
      onSaved: (ctx, vm, saved) => goAfterEntitySave(
        ctx,
        isCreate: vm.isCreate,
        basePath: '/vendors',
        savedId: saved.id,
      ),
    );
  }
}
