import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/vendors/view_models/vendor_edit_view_model.dart';
import 'package:admin/ui/features/vendors/widgets/edit/vendor_edit_layout.dart';

/// Edit + Create form for a Vendor. Mirror of `ClientEditScreen` — the
/// outer scaffold owns VM lifecycle, the loading-state Scaffold, dead-
/// outbox-row 422 recovery, and post-save cleanup. This widget only
/// contributes the per-entity wiring: how to fetch the existing row, how
/// to build the VM, the title, and the form body.
class VendorEditScreen extends StatelessWidget {
  const VendorEditScreen({this.existingId, super.key});

  final String? existingId;

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
        existing: existing,
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
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/vendors/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
