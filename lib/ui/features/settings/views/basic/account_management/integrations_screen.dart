import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// External URLs the Integrations tab opens. Matched against admin-portal's
/// `kApiDocsUrl` / `kZapierUrl` so the docs target stays consistent across
/// clients.
const String _kApiDocsUrl =
    'https://invoiceninja.github.io/docs/api-reference/invoice-ninja-api-reference/';
const String _kZapierUrl =
    'https://zapier.com/apps/invoice-ninja/integrations';

/// Account Management → Integrations. Three text fields (Google Analytics
/// tracking ID, Matomo ID, Matomo URL) plus link tiles to API Tokens / API
/// Webhooks / API Docs / Zapier / QuickBooks (Phase 4 placeholder).
///
/// Editor pattern: local draft + AppBar Save button. Stream-watches the
/// company so server-side changes (refresh, another device) repopulate the
/// controllers when the form isn't dirty.
class AccountManagementIntegrationsScreen extends StatefulWidget {
  const AccountManagementIntegrationsScreen({super.key});

  @override
  State<AccountManagementIntegrationsScreen> createState() =>
      _AccountManagementIntegrationsScreenState();
}

class _AccountManagementIntegrationsScreenState
    extends State<AccountManagementIntegrationsScreen> {
  final _gaCtrl = TextEditingController();
  final _matomoIdCtrl = TextEditingController();
  final _matomoUrlCtrl = TextEditingController();

  Company? _company;
  bool _dirty = false;
  bool _saving = false;

  @override
  void dispose() {
    _gaCtrl.dispose();
    _matomoIdCtrl.dispose();
    _matomoUrlCtrl.dispose();
    super.dispose();
  }

  void _syncFromCompany(Company c) {
    if (_dirty) return; // Don't trample the user's in-progress edits.
    _gaCtrl.text = c.googleAnalyticsKey;
    _matomoIdCtrl.text = c.matomoId;
    _matomoUrlCtrl.text = c.matomoUrl;
    _company = c;
  }

  void _markDirty() {
    if (_company == null) return;
    final next =
        _gaCtrl.text != _company!.googleAnalyticsKey ||
        _matomoIdCtrl.text != _company!.matomoId ||
        _matomoUrlCtrl.text != _company!.matomoUrl;
    if (next == _dirty) return;
    setState(() => _dirty = next);
  }

  Future<void> _save() async {
    final company = _company;
    if (company == null || _saving) return;
    setState(() => _saving = true);
    try {
      await context.read<Services>().company.updateCompany(
        draft: company.copyWith(
          googleAnalyticsKey: _gaCtrl.text.trim(),
          matomoId: _matomoIdCtrl.text.trim(),
          matomoUrl: _matomoUrlCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _saving = false;
      });
      Notify.success(context, context.tr('saved_settings'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      Notify.error(context, context.tr('error_refresh_page'), error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    final canSave = _dirty && !_saving;

    return SettingsScreenScaffold(
      titleKey: 'integrations',
      actions: [
        TextButton(
          onPressed: canSave ? _save : null,
          style: TextButton.styleFrom(foregroundColor: context.inTheme.accent),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('save')),
        ),
        const SizedBox(width: 8),
      ],
      body: companyId == null || companyId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Company?>(
              stream: services.company.watchCompany(companyId),
              builder: (context, snapshot) {
                final company = snapshot.data;
                if (company == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                _syncFromCompany(company);

                return SettingsFormShell(
                  sections: [
                    FormSection(
                      title: context.tr('integrations'),
                      children: [
                        TextField(
                          controller: _gaCtrl,
                          onChanged: (_) => _markDirty(),
                          decoration: InputDecoration(
                            labelText: context.tr('google_analytics_tracking_id'),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                        ),
                        TextField(
                          controller: _matomoIdCtrl,
                          onChanged: (_) => _markDirty(),
                          decoration: InputDecoration(
                            labelText: context.tr('matomo_id'),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                        ),
                        TextField(
                          controller: _matomoUrlCtrl,
                          onChanged: (_) => _markDirty(),
                          decoration: InputDecoration(
                            labelText: context.tr('matomo_url'),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (canSave) _save();
                          },
                        ),
                      ],
                    ),
                    FormSection(
                      title: context.tr('api_tokens'),
                      spacing: 0,
                      children: [
                        _IntegrationTile(
                          icon: Icons.lock_outline,
                          labelKey: 'api_tokens',
                          onTap: () => context.go('/settings/api_tokens'),
                        ),
                        _IntegrationTile(
                          icon: Icons.webhook_outlined,
                          labelKey: 'api_webhooks',
                          onTap: () => context.go('/settings/api_webhooks'),
                        ),
                        _IntegrationTile(
                          icon: Icons.menu_book_outlined,
                          labelKey: 'api_docs',
                          external: true,
                          onTap: () => _openExternal(context, _kApiDocsUrl),
                        ),
                        _IntegrationTile(
                          icon: Icons.electrical_services_outlined,
                          label: 'Zapier',
                          external: true,
                          onTap: () => _openExternal(context, _kZapierUrl),
                        ),
                        _IntegrationTile(
                          icon: Icons.account_balance_outlined,
                          labelKey: 'quickbooks',
                          onTap: () => context.go(
                            '/settings/account_management/integrations/quickbooks',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({
    required this.icon,
    required this.onTap,
    this.labelKey,
    this.label,
    this.external = false,
  }) : assert(labelKey != null || label != null);

  final IconData icon;
  final VoidCallback onTap;
  final String? labelKey;
  final String? label;
  final bool external;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: tokens.ink2),
      title: Text(label ?? context.tr(labelKey!)),
      trailing: external
          ? Icon(Icons.open_in_new, size: 18, color: tokens.ink3)
          : Icon(Icons.chevron_right, color: tokens.ink3),
      onTap: onTap,
    );
  }
}

Future<void> _openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final loc = Localization.of(context);
  final errorMessage =
      loc?.lookup('failed_to_open_url') ?? 'failed_to_open_url';
  final uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    }
  } catch (_) {
    /* fall through */
  }
  if (messenger == null) return;
  // ignore: use_build_context_synchronously
  Notify.error(messenger.context, errorMessage, messenger: messenger);
}
