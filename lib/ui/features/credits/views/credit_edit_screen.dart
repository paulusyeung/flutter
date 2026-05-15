import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/credits/view_models/credit_edit_view_model.dart';
import 'package:admin/ui/features/credits/widgets/edit/credit_edit_layout.dart';

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
          existing: existing,
          cloneFrom: cloneFrom,
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
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/credits/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
