import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// `/settings/integrations` — landing menu listing the three integration
/// destinations (API Tokens, API Webhooks, Analytics). The actual list /
/// edit screens live one level deeper under `/settings/integrations/...`.
class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      titleKey: 'integrations',
      body: SettingsFormShell(
        sections: [
          FormSection(
            title: context.tr('integrations'),
            spacing: 0,
            children: [
              _IntegrationTile(
                icon: Icons.lock_outline,
                labelKey: 'api_tokens',
                onTap: () => context.go('/settings/integrations/api_tokens'),
              ),
              _IntegrationTile(
                icon: Icons.webhook_outlined,
                labelKey: 'api_webhooks',
                onTap: () => context.go('/settings/integrations/api_webhooks'),
              ),
              _IntegrationTile(
                icon: Icons.analytics_outlined,
                labelKey: 'analytics',
                onTap: () => context.go('/settings/integrations/analytics'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({
    required this.icon,
    required this.labelKey,
    required this.onTap,
  });

  final IconData icon;
  final String labelKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: tokens.ink2),
      title: Text(context.tr(labelKey)),
      trailing: Icon(Icons.chevron_right, color: tokens.ink3),
      onTap: onTap,
    );
  }
}
