import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/gateways/view_models/company_gateway_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';

/// Required Fields tab — grouped subsections (Customer info / Address /
/// Security / Behavior) per the UX-refinements list in the plan. Per-
/// company custom-field toggles will land in a follow-up once the edit
/// flow can read `Company.customFields` synchronously.
class GatewayRequiredFieldsTab extends StatelessWidget {
  const GatewayRequiredFieldsTab({super.key, required this.vm});

  final CompanyGatewayEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final draft = vm.draft;
    return ListView(
      padding: const EdgeInsets.all(InSpacing.lg),
      children: [
        FormSection(
          title: context.tr('customer_information'),
          children: [
            SwitchListTile(
              title: Text(context.tr('client_name')),
              value: draft.requireClientName,
              onChanged: (v) =>
                  vm.mutate((g) => g.copyWith(requireClientName: v)),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(context.tr('phone')),
              value: draft.requireClientPhone,
              onChanged: (v) =>
                  vm.mutate((g) => g.copyWith(requireClientPhone: v)),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(context.tr('contact_name')),
              value: draft.requireContactName,
              onChanged: (v) =>
                  vm.mutate((g) => g.copyWith(requireContactName: v)),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(context.tr('email')),
              value: draft.requireContactEmail,
              onChanged: (v) =>
                  vm.mutate((g) => g.copyWith(requireContactEmail: v)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        FormSection(
          title: context.tr('address'),
          children: [
            SwitchListTile(
              title: Text(context.tr('billing_address')),
              value: draft.requireBillingAddress,
              onChanged: (v) =>
                  vm.mutate((g) => g.copyWith(requireBillingAddress: v)),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(context.tr('shipping_address')),
              value: draft.requireShippingAddress,
              onChanged: (v) =>
                  vm.mutate((g) => g.copyWith(requireShippingAddress: v)),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(context.tr('postal_code')),
              value: draft.requirePostalCode,
              onChanged: (v) =>
                  vm.mutate((g) => g.copyWith(requirePostalCode: v)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        FormSection(
          title: context.tr('security'),
          children: [
            SwitchListTile(
              title: Text(context.tr('cvv')),
              value: draft.requireCvv,
              onChanged: (v) => vm.mutate((g) => g.copyWith(requireCvv: v)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        FormSection(
          title: context.tr('behavior'),
          children: [
            SwitchListTile(
              title: Text(context.tr('always_show_required_fields')),
              subtitle: Text(
                context.tr('behavior_always_show_required_fields'),
              ),
              value: draft.alwaysShowRequiredFields,
              onChanged: (v) =>
                  vm.mutate((g) => g.copyWith(alwaysShowRequiredFields: v)),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(context.tr('update_address')),
              subtitle: Text(context.tr('behavior_update_details')),
              value: draft.updateDetails,
              onChanged: (v) => vm.mutate((g) => g.copyWith(updateDetails: v)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }
}
