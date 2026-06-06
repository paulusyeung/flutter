import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/after_save_create_action.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/payments/view_models/payment_edit_view_model.dart';
import 'package:admin/ui/features/payments/widgets/edit/payment_edit_layout.dart';
import 'package:admin/ui/features/payments/widgets/payment_actions.dart';

class PaymentEditScreen extends StatelessWidget {
  const PaymentEditScreen({
    this.existingId,
    this.cloneFrom,
    this.prefillClientId,
    super.key,
  });

  final String? existingId;
  final Payment? cloneFrom;

  /// Optional client id seed (`?client=<id>`). In create mode the form opens
  /// with this client pre-selected (Clients list ⋮ → New Payment). Delivered
  /// via query param because `extra:` is dropped on the cross-branch hop.
  final String? prefillClientId;

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
        // `?client=<id>` (Clients list ⋮ → New Payment): synthesize a draft
        // carrying just the clientId so the client is set from first build —
        // mirrors ProjectEditScreen. The client's invoices then load for
        // applying the payment.
        Payment? clone = cloneFrom;
        if (clone == null && prefillClientId != null && existing == null) {
          clone = emptyPayment().copyWith(clientId: prefillClientId!);
        }
        return PaymentEditViewModel(
          repo: services.payments,
          companyId: companyId,
          existing: existing,
          cloneFrom: clone,
          translate: ctx.tr,
          useCommaAsDecimalPlace:
              services
                  .formatterIfReady(companyId)
                  ?.settings
                  .useCommaAsDecimalPlace ??
              false,
          sync: services.sync,
          connectivity: services.connectivity,
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
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<PaymentAction>(
            leading: saveButton,
            items: filterForEditScreen(
              PaymentActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: PaymentActions.isLifecycle,
            ),
          ),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return PaymentActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as PaymentAction,
        );
      },
      // Create-mode: resolve the tmp id to the real one so Refund keeps its
      // navigation instead of the detail redirect.
      onAfterSaveActionOnCreate: (ctx, saved, a) {
        final services = ctx.read<Services>();
        final companyId = services.auth.session.value!.currentCompanyId;
        return dispatchAfterSaveOnCreate<Payment, PaymentAction>(
          ctx,
          saved: saved,
          idOf: (p) => p.id,
          withId: (p, id) => p.copyWith(id: id),
          resolveId: services.payments.resolveId,
          action: a as PaymentAction,
          navigatesOnCreate: PaymentActions.navigatesOnCreate,
          dispatch: (c, resolved, act) =>
              PaymentActions.dispatch(c, services, companyId, resolved, act),
        );
      },
      onSaved: (ctx, vm, saved) => goAfterEntitySave(
        ctx,
        isCreate: vm.isCreate,
        basePath: '/payments',
        savedId: saved.id,
      ),
    );
  }
}
