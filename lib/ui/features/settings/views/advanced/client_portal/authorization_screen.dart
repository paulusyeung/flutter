import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Searchable label keys rendered by the Authorization tab. Mirrors the field
/// list below; aggregated into `kSettingsSearchCatalog['client_portal']`.
const kClientPortalAuthorizationSearchKeys = <String>[
  'enable_portal_password',
  'show_accept_invoice_terms',
  'show_accept_quote_terms',
  'require_invoice_signature',
  'require_quote_signature',
  'require_purchase_order_signature',
  'signature_on_pdf',
];

/// Authorization tab — portal password requirement, accept-terms checkboxes,
/// and the signature requirements.
class ClientPortalAuthorizationScreen extends StatelessWidget {
  const ClientPortalAuthorizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final modules = host.draft?.enabledModules ?? 0;
    final quotesOn = isModuleEnabled(modules, EnabledModule.quotes);
    final purchaseOrdersOn = isModuleEnabled(
      modules,
      EnabledModule.purchaseOrders,
    );

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('authentication'),
          children: [
            OverridableSwitchField(
              label: context.tr('enable_portal_password'),
              apiKey: 'enable_client_portal_password',
              subtitle: context.trIfDefined('enable_portal_password_help'),
            ),
            OverridableSwitchField(
              label: context.tr('show_accept_invoice_terms'),
              apiKey: 'show_accept_invoice_terms',
              subtitle: context.trIfDefined('show_accept_invoice_terms_help'),
            ),
            OverridableSwitchField(
              label: context.tr('show_accept_quote_terms'),
              apiKey: 'show_accept_quote_terms',
              subtitle: context.trIfDefined('show_accept_quote_terms_help'),
            ),
          ],
        ),
        FormSection(
          title: context.tr('signature_requirements'),
          children: [
            OverridableSwitchField(
              label: context.tr('require_invoice_signature'),
              apiKey: 'require_invoice_signature',
              subtitle: context.trIfDefined('require_invoice_signature_help'),
            ),
            if (quotesOn)
              OverridableSwitchField(
                label: context.tr('require_quote_signature'),
                apiKey: 'require_quote_signature',
                subtitle: context.trIfDefined('require_quote_signature_help'),
              ),
            if (purchaseOrdersOn)
              OverridableSwitchField(
                label: context.tr('require_purchase_order_signature'),
                apiKey: 'require_purchase_order_signature',
                subtitle: context.trIfDefined(
                  'require_purchase_order_signature_help',
                ),
              ),
            OverridableSwitchField(
              label: context.tr('signature_on_pdf'),
              apiKey: 'signature_on_pdf',
              subtitle: context.trIfDefined('signature_on_pdf_help'),
            ),
          ],
        ),
      ],
    );
  }
}
