import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/widgets/portal_url_display.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/widgets/registration_fields_configurator.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Searchable label keys rendered by the Registration tab. Mirrors the field
/// list below; aggregated into `kSettingsSearchCatalog['client_portal']`.
const kClientPortalRegistrationSearchKeys = <String>[
  'client_registration',
  'registration_url',
];

/// Registration tab — only rendered at company scope (per-client / per-group
/// scope shows an empty state). Holds the Client Registration toggle, the
/// Registration URL, and the twenty-field hide/optional/require matrix.
class ClientPortalRegistrationScreen extends StatelessWidget {
  const ClientPortalRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final level = context.watch<SettingsLevelController>().level;
    if (level != SettingsLevel.company) {
      return EmptyState(
        icon: Icons.lock_outline,
        title: context.tr('registration'),
        subtitle: context.tr('company_settings_only'),
      );
    }
    final host = context.watch<SettingsDraftHost>();
    final canRegister = host.settings.clientCanRegister ?? false;
    final draft = host.draft;
    final companyKey = draft?.companyKey ?? '';
    final portalDomain = draft?.portalDomain ?? '';
    final subdomain = draft?.subdomain ?? '';
    final registrationUrl = _registrationUrl(
      subdomain: subdomain,
      portalDomain: portalDomain,
      companyKey: companyKey,
    );

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('registration'),
          children: [
            OverridableSwitchField(
              label: context.tr('client_registration'),
              apiKey: 'client_can_register',
              subtitle: context.trIfDefined('client_registration_help'),
            ),
            if (canRegister && registrationUrl.isNotEmpty) ...[
              SizedBox(height: InSpacing.md(context)),
              PortalUrlDisplay(
                label: context.tr('registration_url'),
                url: registrationUrl,
              ),
            ],
          ],
        ),
        FormSection(
          title: context.tr('registration_fields'),
          children: const [RegistrationFieldsConfigurator()],
        ),
      ],
    );
  }

  String _registrationUrl({
    required String subdomain,
    required String portalDomain,
    required String companyKey,
  }) {
    if (portalDomain.isNotEmpty && companyKey.isNotEmpty) {
      final trimmed = portalDomain.endsWith('/')
          ? portalDomain.substring(0, portalDomain.length - 1)
          : portalDomain;
      return '$trimmed/client/register/$companyKey';
    }
    if (subdomain.isNotEmpty) {
      return 'https://$subdomain.invoicing.co/client/register';
    }
    return '';
  }
}
