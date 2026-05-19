import 'dart:convert';

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
import 'package:admin/ui/features/settings/widgets/plan_gate_banner.dart';
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
  bool _reconnecting = false;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final session = services.auth.session.value;
    final companyId = session?.currentCompanyId;
    // Mirrors React `usePaidOrSelfhost`: QuickBooks is available on
    // self-hosted (any plan) or hosted + a paid (Pro/Enterprise, trial-
    // aware) plan. Gated hosted users see the upgrade banner instead.
    final allowed =
        session != null && (session.isSelfHosted || session.hasProAccess);
    return SettingsScreenScaffold(
      titleKey: 'quickbooks',
      body: companyId == null || companyId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : !allowed
              ? const SingleChildScrollView(
                  child: PlanGateBanner(style: PlanGateStyle.inset),
                )
              : StreamBuilder<Company?>(
                  stream: services.company.watchCompany(companyId),
                  builder: (context, snapshot) {
                    final company = snapshot.data;
                    if (company == null) {
                      return const Center(
                          child: CircularProgressIndicator());
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
                      company: company,
                      busy: _disconnecting,
                      reconnecting: _reconnecting,
                      onDisconnect: _onDisconnect,
                      onReconnect: _onReconnect,
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

  /// Re-authorize an expired connection. Mirrors React
  /// `useQuickbooksReconnect`: fetch the reconnect URL, then launch it the
  /// same way as the initial connect (the hosted page redirects back).
  Future<void> _onReconnect() async {
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final errorMsg = context.tr('error_refresh_page');
    setState(() => _reconnecting = true);
    try {
      final uri = await services.quickbooks.reconnectUrl();
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
      if (mounted) setState(() => _reconnecting = false);
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

/// QuickBooks-connected surface. Mirrors React `QuickBooksDetails` +
/// `QuickBooksImportTab` + `QuickBooksSyncTab`, kept as sections on the one
/// screen (the rebuild routes QB as a single leaf — see `settings_routes`).
class _Connected extends StatefulWidget {
  const _Connected({
    required this.company,
    required this.busy,
    required this.reconnecting,
    required this.onDisconnect,
    required this.onReconnect,
  });

  final Company company;
  final bool busy;
  final bool reconnecting;
  final VoidCallback onDisconnect;
  final VoidCallback onReconnect;

  @override
  State<_Connected> createState() => _ConnectedState();
}

/// React surfaces these four entities as editable sync directions.
const _kQbSyncEntities = <String>['client', 'invoice', 'product', 'payment'];
const _kQbDirections = <String>['none', 'push', 'pull', 'bidirectional'];

class _ConnectedState extends State<_Connected> {
  // Import toggles (one-shot).
  bool _impClients = false;
  bool _impProducts = false;
  bool _impInvoices = false;
  bool _importing = false;

  // Sync settings draft.
  final Map<String, String> _dir = {};
  bool _automaticTaxes = false;
  final _taxable = TextEditingController();
  final _exempt = TextEditingController();
  bool _settingsDirty = false;
  bool _saving = false;

  Map<String, dynamic> get _qb =>
      (widget.company.quickbooks ?? const <String, dynamic>{});
  Map<String, dynamic> get _settings {
    final s = _qb['settings'];
    return s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    _seedFromCompany();
  }

  @override
  void didUpdateWidget(_Connected old) {
    super.didUpdateWidget(old);
    // Re-seed from a fresh server snapshot only when the user has no
    // unsaved edits, so a stream tick can't clobber in-progress changes.
    if (!_settingsDirty) _seedFromCompany();
  }

  void _seedFromCompany() {
    final s = _settings;
    _dir.clear();
    for (final e in _kQbSyncEntities) {
      final entry = s[e];
      final d = entry is Map ? entry['direction'] : null;
      _dir[e] = (d is String && _kQbDirections.contains(d)) ? d : 'none';
    }
    _automaticTaxes = s['automatic_taxes'] == true;
    _taxable.text = (s['default_taxable_code'] as String?) ?? '';
    _exempt.text = (s['default_exempt_code'] as String?) ?? '';
  }

  @override
  void dispose() {
    _taxable.dispose();
    _exempt.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _importing = true);
    try {
      await services.quickbooks.triggerImport(
        client: _impClients,
        product: _impProducts,
        invoice: _impInvoices,
      );
      if (!mounted) return;
      Notify.success(
        context,
        context.tr('sync_started'),
        messenger: messenger,
      );
      setState(() {
        _impClients = false;
        _impProducts = false;
        _impInvoices = false;
      });
    } catch (e) {
      if (!mounted) return;
      Notify.error(
        context,
        context.tr('error_refresh_page'),
        error: e,
        messenger: messenger,
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _saveSettings() async {
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    // Deep-copy the whole `quickbooks` blob (JSON-safe) so OAuth tokens /
    // realm / server-populated maps are preserved; only mutate the
    // user-editable settings keys (React persists via the normal company
    // update — same path here, through the outbox + Drift).
    final merged = jsonDecode(jsonEncode(_qb)) as Map<String, dynamic>;
    final settings = (merged['settings'] is Map)
        ? Map<String, dynamic>.from(merged['settings'] as Map)
        : <String, dynamic>{};
    for (final e in _kQbSyncEntities) {
      final existing = settings[e];
      final m = existing is Map
          ? Map<String, dynamic>.from(existing)
          : <String, dynamic>{};
      m['direction'] = _dir[e] ?? 'none';
      settings[e] = m;
    }
    settings['automatic_taxes'] = _automaticTaxes;
    settings['default_taxable_code'] = _taxable.text.trim();
    settings['default_exempt_code'] = _exempt.text.trim();
    merged['settings'] = settings;

    setState(() => _saving = true);
    try {
      await services.company.updateCompany(
        draft: widget.company.copyWith(quickbooks: merged),
      );
      if (!mounted) return;
      Notify.success(context, context.tr('saved'), messenger: messenger);
      setState(() => _settingsDirty = false);
    } catch (e) {
      if (!mounted) return;
      Notify.error(
        context,
        context.tr('error_refresh_page'),
        error: e,
        messenger: messenger,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final companyName = (_qb['companyName'] as String?) ?? '';
    final realmId = (_qb['realmID'] as String?) ?? '';
    final requiresReconnect = _qb['requires_reconnect'] == true;
    final anyImport = _impClients || _impProducts || _impInvoices;
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('quickbooks'),
          spacing: 0,
          children: [
            if (requiresReconnect) ...[
              Padding(
                padding: EdgeInsets.only(bottom: InSpacing.md(context)),
                child: Text(
                  context.tr('quickbooks_requires_reauth'),
                  style: TextStyle(color: tokens.overdue),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 44),
                  ),
                  icon: widget.reconnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.open_in_new, size: 18),
                  label: Text(context.tr('reconnect')),
                  onPressed:
                      widget.reconnecting ? null : widget.onReconnect,
                ),
              ),
              SizedBox(height: InSpacing.md(context)),
            ],
            _InfoRow(label: context.tr('company_name'), value: companyName),
            Divider(color: tokens.border, height: 1),
            _InfoRow(label: context.tr('realm_id'), value: realmId),
          ],
        ),
        FormSection(
          title: context.tr('import'),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _impClients,
              onChanged: _importing
                  ? null
                  : (v) => setState(() => _impClients = v),
              title: Text(context.tr('clients')),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _impProducts,
              onChanged: _importing
                  ? null
                  : (v) => setState(() => _impProducts = v),
              title: Text(context.tr('products')),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _impInvoices,
              onChanged: _importing
                  ? null
                  : (v) => setState(() => _impInvoices = v),
              title: Text(context.tr('invoices')),
            ),
            SizedBox(height: InSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
                icon: _importing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 18),
                label: Text(context.tr('sync')),
                onPressed:
                    (_importing || !anyImport) ? null : _import,
              ),
            ),
          ],
        ),
        FormSection(
          title: context.tr('quickbooks_sync_settings'),
          children: [
            for (final e in _kQbSyncEntities)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: InSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(context.tr(e))),
                    DropdownButton<String>(
                      value: _dir[e] ?? 'none',
                      onChanged: _saving
                          ? null
                          : (v) => setState(() {
                                _dir[e] = v ?? 'none';
                                _settingsDirty = true;
                              }),
                      items: [
                        for (final d in _kQbDirections)
                          DropdownMenuItem(
                            value: d,
                            child: Text(context.tr(d)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _automaticTaxes,
              onChanged: _saving
                  ? null
                  : (v) => setState(() {
                        _automaticTaxes = v;
                        _settingsDirty = true;
                      }),
              title: Text(context.tr('automatic_taxes')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taxable,
              onChanged: (_) => setState(() => _settingsDirty = true),
              decoration: InputDecoration(
                labelText: context.tr('default_taxable_code'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _exempt,
              onChanged: (_) => setState(() => _settingsDirty = true),
              decoration: InputDecoration(
                labelText: context.tr('default_exempt_code'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: InSpacing.md(context)),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
                onPressed: (_saving || !_settingsDirty) ? null : _saveSettings,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('save')),
              ),
            ),
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
                onPressed: widget.busy ? null : widget.onDisconnect,
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
