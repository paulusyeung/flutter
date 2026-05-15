import 'package:admin/ui/features/settings/views/advanced/client_portal/authorization_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/client_portal_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/client_portal_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/customize_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/messages_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/registration_screen.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/cascade_tabbed_settings_shell.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';
import 'package:flutter/material.dart';

/// Client Portal settings page — five tabs hosted by the cascade-aware
/// [CascadeTabbedSettingsShell]. The Settings, Authorization, Messages tabs
/// bind to `company.settings.*` (cascade-aware); Registration and Customize
/// also write top-level `Company` fields and so render their bodies only at
/// company scope (the bodies themselves drop in a scope-aware `EmptyState`
/// at group / client scope).
class ClientPortalShell extends StatelessWidget {
  const ClientPortalShell({super.key, this.initialTab});

  /// The `:tab` path parameter from the route, or null when on the parent
  /// `/settings/client_portal` URL (defaults to the Settings tab).
  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return CascadeTabbedSettingsShell(
      titleKey: 'client_portal',
      basePath: '/settings/client_portal',
      initialTab: initialTab,
      companyVmFactory: ({required repo, required companyId}) =>
          ClientPortalViewModel(repo: repo, companyId: companyId),
      resolveErrorTabSlug: _resolveErrorTabSlug,
      tabs: const [
        TabbedSettingsTab(
          slug: '',
          labelKey: 'settings',
          body: ClientPortalScreen(),
        ),
        TabbedSettingsTab(
          slug: 'authorization',
          labelKey: 'authorization',
          body: ClientPortalAuthorizationScreen(),
        ),
        TabbedSettingsTab(
          slug: 'registration',
          labelKey: 'registration',
          body: ClientPortalRegistrationScreen(),
        ),
        TabbedSettingsTab(
          slug: 'messages',
          labelKey: 'messages',
          body: ClientPortalMessagesScreen(),
        ),
        TabbedSettingsTab(
          slug: 'customize',
          labelKey: 'customize',
          body: ClientPortalCustomizeScreen(),
        ),
      ],
    );
  }

  /// 422 → tab-jump resolver. When a save returns a per-field error, jump
  /// the user to the tab that owns the offending field so the inline error
  /// is visible without manual hunting.
  static String? _resolveErrorTabSlug(SettingsDraftHost host) {
    final errors = host.fieldErrors;
    if (errors.isEmpty) return null;
    bool any(Iterable<String> keys) => keys.any(errors.containsKey);
    if (any(_kAuthorizationKeys)) return 'authorization';
    if (any(_kRegistrationKeys)) return 'registration';
    if (any(_kMessagesKeys)) return 'messages';
    if (any(_kCustomizeKeys)) return 'customize';
    return '';
  }
}

const _kAuthorizationKeys = <String>{
  'enable_client_portal_password',
  'show_accept_invoice_terms',
  'show_accept_quote_terms',
  'require_invoice_signature',
  'require_quote_signature',
  'require_purchase_order_signature',
  'signature_on_pdf',
};

const _kRegistrationKeys = <String>{
  'client_can_register',
  'client_registration_fields',
};

const _kMessagesKeys = <String>{
  'custom_message_dashboard',
  'custom_message_unpaid_invoice',
  'custom_message_paid_invoice',
  'custom_message_unapproved_quote',
};

const _kCustomizeKeys = <String>{
  'portal_custom_head',
  'portal_custom_footer',
  'portal_custom_css',
  'portal_custom_js',
};
