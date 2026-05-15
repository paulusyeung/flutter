import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/payments/view_models/payment_edit_view_model.dart';
import 'package:admin/ui/features/payments/widgets/edit/payment_edit_layout.dart';

class PaymentEditScreen extends StatelessWidget {
  const PaymentEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;
  final Payment? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Payment, PaymentEditViewModel>(
      existingId: existingId,
      entityTypeName: 'payment',
      fetchExisting: (ctx, services, companyId, id) =>
          services.payments.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        // Default send-email starts false; the form's switch lets the user
        // opt in. Honoring the company-wide
        // `client_manual_payment_notification` setting as the default is a
        // follow-up (the setting isn't lifted onto the auth session's
        // `AuthCompany`, and reading it from the company repo here would
        // be async — postponed until a single-shot accessor lands).
        // Capture `ctx` once so validation messages thrown from `performSave`
        // can be translated without dragging BuildContext through the VM
        // method signatures. Safe because the scaffold owns the ctx for
        // the VM's lifetime.
        return PaymentEditViewModel(
          repo: services.payments,
          companyId: companyId,
          existing: existing,
          cloneFrom: cloneFrom,
          translate: ctx.tr,
        );
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_payment') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_payment')
          : (vm.draft.number.isNotEmpty
              ? '${ctx.tr('edit')} · #${vm.draft.number}'
              : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => PaymentEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (p) => p.id,
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/payments/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
