import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/gateways/view_models/company_gateway_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Required Fields tab — grouped subsections (Customer info / Address /
/// Security / Custom fields / Behavior). The per-company custom-field toggles
/// (`require_custom_value1-4`) render one row per *defined* client custom
/// field, read from the active company.
class GatewayRequiredFieldsTab extends StatelessWidget {
  const GatewayRequiredFieldsTab({super.key, required this.vm});

  final CompanyGatewayEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final draft = vm.draft;
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(vm.companyId),
      builder: (context, snap) {
        final customToggles = _customFieldToggles(context, snap.data, draft);
        return SettingsFormShell(
          sections: [
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
            // Only shown when the company defines client custom fields — there's
            // nothing to require otherwise.
            if (customToggles.isNotEmpty)
              FormSection(
                title: context.tr('custom_fields'),
                children: customToggles,
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
                  onChanged: (v) =>
                      vm.mutate((g) => g.copyWith(updateDetails: v)),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// One toggle per defined client custom field. Empty when the company has
  /// none — the caller drops the whole section in that case.
  List<Widget> _customFieldToggles(
    BuildContext context,
    Company? company,
    CompanyGateway draft,
  ) {
    if (company == null) return const [];
    final rows = <Widget>[];
    for (var i = 1; i <= 4; i++) {
      final label = company.customFieldLabel('client$i');
      if (label.isEmpty) continue;
      rows.add(
        SwitchListTile(
          title: Text(label),
          value: _requireCustom(draft, i),
          onChanged: (v) => vm.mutate((g) => _setRequireCustom(g, i, v)),
          contentPadding: EdgeInsets.zero,
        ),
      );
    }
    return rows;
  }

  bool _requireCustom(CompanyGateway g, int i) => switch (i) {
    1 => g.requireCustomValue1,
    2 => g.requireCustomValue2,
    3 => g.requireCustomValue3,
    _ => g.requireCustomValue4,
  };

  CompanyGateway _setRequireCustom(CompanyGateway g, int i, bool v) =>
      switch (i) {
        1 => g.copyWith(requireCustomValue1: v),
        2 => g.copyWith(requireCustomValue2: v),
        3 => g.copyWith(requireCustomValue3: v),
        _ => g.copyWith(requireCustomValue4: v),
      };
}
