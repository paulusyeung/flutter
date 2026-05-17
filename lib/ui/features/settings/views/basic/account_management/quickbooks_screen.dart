import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Search keys for QuickBooks. Colocated with the screen so the search
/// catalog stays in sync via spread.
const kAccountManagementQuickbooksSearchKeys = <String>[
  'quickbooks',
  'connect',
  'disconnect',
  'company_name',
  'realm_id',
];

/// Settings → Account Management → Integrations → QuickBooks.
///
/// Connect / disconnect surface only. The actual import + sync-direction UI
/// is deferred until live API probing can verify the `quickbooks.settings.*`
/// payload shape; until then this screen routes users to the
/// already-validated server-side OAuth flow.
class QuickbooksScreen extends StatefulWidget {
  const QuickbooksScreen({super.key});

  @override
  State<QuickbooksScreen> createState() => _QuickbooksScreenState();
}

class _QuickbooksScreenState extends State<QuickbooksScreen> {
  bool _connecting = false;
  bool _disconnecting = false;
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    return SettingsScreenScaffold(
      titleKey: 'quickbooks',
      body: companyId == null || companyId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Company?>(
              stream: services.company.watchCompany(companyId),
              builder: (context, snapshot) {
                final company = snapshot.data;
                if (company == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final quickbooks = company.quickbooks;
                if (quickbooks == null || quickbooks.isEmpty) {
                  return _NotConnected(
                    busy: _connecting,
                    refreshing: _refreshing,
                    onConnect: _onConnect,
                    onRefresh: _onRefresh,
                  );
                }
                return _Connected(
                  blob: quickbooks,
                  busy: _disconnecting,
                  onDisconnect: _onDisconnect,
                );
              },
            ),
    );
  }

  Future<void> _onConnect() async {
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final errorMsg = context.tr('error_refresh_page');
    setState(() => _connecting = true);
    try {
      final uri = await services.quickbooks.buildAuthorizeUrl();
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        Notify.error(
          context,
          context.tr('failed_to_open_url'),
          messenger: messenger,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Notify.error(context, errorMsg, error: e, messenger: messenger);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  /// Pulled in via `R1` from the post-implementation review: `launchUrl`
  /// returns immediately after handing off to the OS browser, so we have
  /// no signal for "user completed OAuth in the external page". The
  /// connect screen surfaces an explicit "Refresh status" button that
  /// pulls a fresh `/refresh` — when the server now reports
  /// `company.quickbooks`, the `StreamBuilder<Company?>` upstairs swaps
  /// the body to the Connected card.
  Future<void> _onRefresh() async {
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final errorMsg = context.tr('error_refresh_page');
    setState(() => _refreshing = true);
    try {
      // "Refresh status" after an external OAuth round-trip — force a full
      // snapshot so the QuickBooks connection state is authoritative.
      await services.auth.refresh(fullSync: true);
    } catch (e) {
      if (!mounted) return;
      Notify.error(context, errorMsg, error: e, messenger: messenger);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _onDisconnect() async {
    final services = context.read<Services>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('disconnect')),
        content: Text(ctx.tr('are_you_sure')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('continue')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final successMsg = context.tr('disconnect');
    final errorMsg = context.tr('error_refresh_page');
    setState(() => _disconnecting = true);
    try {
      await services.quickbooks.disconnect();
      if (!mounted) return;
      Notify.success(context, successMsg, messenger: messenger);
    } catch (e) {
      if (!mounted) return;
      Notify.error(context, errorMsg, error: e, messenger: messenger);
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }
}

class _NotConnected extends StatelessWidget {
  const _NotConnected({
    required this.busy,
    required this.refreshing,
    required this.onConnect,
    required this.onRefresh,
  });

  final bool busy;
  final bool refreshing;
  final VoidCallback onConnect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.account_balance_outlined,
      title: context.tr('quickbooks'),
      subtitle: context.tr('quickbooks_connect_description'),
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.open_in_new, size: 18),
            label: Text(context.tr('connect')),
            onPressed: busy || refreshing ? null : onConnect,
          ),
          const SizedBox(height: 8),
          // OAuth completes in an external browser; `launchUrl` has no
          // "return to app" signal we can listen for. Once the user lands
          // back here they can tap this to pull a fresh `/refresh` and
          // flip the UI to the connected card.
          TextButton.icon(
            icon: refreshing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: Text(context.tr('refresh_data')),
            onPressed: busy || refreshing ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

class _Connected extends StatelessWidget {
  const _Connected({
    required this.blob,
    required this.busy,
    required this.onDisconnect,
  });

  final Map<String, dynamic> blob;
  final bool busy;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final companyName = (blob['companyName'] as String?) ?? '';
    final realmId = (blob['realmID'] as String?) ?? '';
    final requiresReconnect = blob['requires_reconnect'] == true;
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('quickbooks'),
          spacing: 0,
          children: [
            if (requiresReconnect)
              Padding(
                padding: EdgeInsets.only(bottom: InSpacing.md(context)),
                child: Text(
                  context.tr('quickbooks_requires_reauth'),
                  style: TextStyle(color: tokens.overdue),
                ),
              ),
            _InfoRow(label: context.tr('company_name'), value: companyName),
            Divider(color: tokens.border, height: 1),
            _InfoRow(label: context.tr('realm_id'), value: realmId),
          ],
        ),
        FormSection(
          title: context.tr('disconnect'),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: Icon(Icons.link_off, color: tokens.overdue),
                label: Text(
                  context.tr('disconnect'),
                  style: TextStyle(color: tokens.overdue),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                  side: BorderSide(color: tokens.overdue),
                ),
                onPressed: busy ? null : onDisconnect,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        value.isEmpty ? '—' : value,
        style: theme.textTheme.bodyMedium?.copyWith(color: tokens.ink),
      ),
    );
  }
}
