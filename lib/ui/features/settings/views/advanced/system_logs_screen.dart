import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/diagnostics_log.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/version.dart';
import 'package:admin/data/models/domain/system_log.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/data/repositories/system_log_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/ui/features/settings/views/advanced/debug_panel_section.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';
import 'package:admin/utils/formatting.dart';

/// Settings → System Logs. Hosts two distinct things on one screen:
/// 1. The server-side System Logs feed (`/api/v1/system_logs`) — admin
///    /owner only; surfaces gateway / email / webhook / PDF / security
///    events with collapsible JSON payloads.
/// 2. Local diagnostics — app version, server URL, outbox state, and the
///    `claude-diagnostics.log` file path. Always visible (no permissions
///    needed) since it's all local data and useful for support reports.
class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  PackageInfo? _packageInfo;
  SystemLogRefreshResult? _lastRefresh;
  bool _refreshing = false;
  DateTime? _lastFetchedAt;
  // Tracks whether _maybeAutoRefresh has run yet. Without this we'd flash
  // the `no_system_logs` empty state for one frame before the postFrame
  // callback flips `_refreshing`.
  bool _initialFetchAttempted = false;
  // Flipped by a long-press on the AppBar title. Reveals the hidden Debug
  // Panel as a pinned band at the bottom of the viewport. Intentionally not
  // persisted — the user re-reveals on each visit so the affordance stays
  // hidden.
  bool _debugRevealed = false;

  @override
  void initState() {
    super.initState();
    _loadPackage();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoRefresh());
  }

  Future<void> _loadPackage() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  /// Fire a refresh on first open OR when the cache is > 1 h old. Matches
  /// React's `staleTime: 3600000` semantics.
  Future<void> _maybeAutoRefresh() async {
    if (!mounted) return;
    final services = context.read<Services>();
    final session = services.auth.session.value;
    final companyId = session?.currentCompanyId ?? '';
    if (companyId.isEmpty) return;
    if (!_canViewServerLogs(session)) return;
    final last = await services.systemLogs.lastFetchedAt(companyId);
    if (!mounted) return;
    setState(() {
      _lastFetchedAt = last;
      _initialFetchAttempted = true;
    });
    final now = DateTime.now().toUtc();
    final stale = last == null || now.difference(last) > const Duration(hours: 1);
    if (stale) {
      await _refresh();
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    if (companyId.isEmpty) return;
    setState(() {
      _refreshing = true;
      _initialFetchAttempted = true;
    });
    final result = await services.systemLogs.refresh(companyId);
    final last = await services.systemLogs.lastFetchedAt(companyId);
    if (!mounted) return;
    // If the user switched companies mid-await, don't apply this refresh's
    // result to the new company's screen state — bail.
    final currentCompanyId = services.auth.session.value?.currentCompanyId ?? '';
    if (currentCompanyId != companyId) {
      setState(() => _refreshing = false);
      return;
    }
    setState(() {
      _refreshing = false;
      _lastRefresh = result;
      _lastFetchedAt = last;
    });
  }

  void _revealDebugPanel() {
    if (_debugRevealed) return;
    HapticFeedback.mediumImpact();
    setState(() => _debugRevealed = true);
    Notify.success(context, context.tr('debug_panel_revealed'));
  }

  /// Height of the pinned debug-panel band: ~45 % of viewport, clamped so
  /// toolbar + tabs + a few rows always fit on small windows and the panel
  /// never devours the whole screen on tall ones.
  double _debugPanelHeight(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return (h * 0.45).clamp(320.0, 480.0);
  }

  bool _canViewServerLogs(AuthSession? session) {
    final me = session?.currentCompany;
    if (me == null) return false;
    return me.isAdmin || me.isOwner;
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return ValueListenableBuilder<String?>(
      valueListenable: services.serverVersion,
      builder: (context, serverVersion, _) {
        final session = services.auth.session.value;
        final companyId = session?.currentCompanyId ?? '';
        return StreamBuilder<int>(
          stream: services.db.outboxDao.watchPendingCount(companyId: companyId),
          builder: (context, pendingSnap) {
            return StreamBuilder<int>(
              stream: services.db.outboxDao.watchDeadCount(
                companyId: companyId,
              ),
              builder: (context, deadSnap) {
                final pending = pendingSnap.data ?? 0;
                final dead = deadSnap.data ?? 0;
                final appRows = <(String, String)>[
                  (
                    context.tr('app_version'),
                    '${_packageInfo?.version ?? '?'} (${_packageInfo?.buildNumber ?? '?'})',
                  ),
                  (
                    context.tr('client_version_constant'),
                    AppVersion.kClientVersion,
                  ),
                  (
                    context.tr('min_server_version'),
                    AppVersion.kMinServerVersion,
                  ),
                ];
                final serverRows = <(String, String)>[
                  (context.tr('server_url'), session?.baseUrl ?? '—'),
                  (
                    context.tr('server_version_label'),
                    serverVersion ?? context.tr('not_yet_seen'),
                  ),
                  (
                    context.tr('hosted'),
                    (session?.isHosted ?? false)
                        ? context.tr('yes')
                        : context.tr('no'),
                  ),
                  (context.tr('account_id'), session?.accountId ?? '—'),
                  (
                    context.tr('company'),
                    session?.currentCompany?.displayName ?? '—',
                  ),
                  (
                    context.tr('company_id_label'),
                    session?.currentCompanyId ?? '—',
                  ),
                ];
                final outboxRows = <(String, String)>[
                  (context.tr('pending_outbox_rows'), '$pending'),
                  (context.tr('dead_outbox_rows'), '$dead'),
                ];
                final allRows = [...appRows, ...serverRows, ...outboxRows];
                final diag = services.diagnosticsLog;
                final canViewServerLogs = _canViewServerLogs(session);

                return SettingsScreenScaffold(
                  titleKey: 'system_logs',
                  onTitleLongPress: _revealDebugPanel,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: context.tr('copy_diagnostics'),
                      onPressed: () => _copy(allRows),
                    ),
                  ],
                  body: Column(
                    children: [
                      Expanded(
                        child: SettingsFormShell(
                          sections: _buildSections(
                            services: services,
                            companyId: companyId,
                            canViewServerLogs: canViewServerLogs,
                            appRows: appRows,
                            serverRows: serverRows,
                            outboxRows: outboxRows,
                            diag: diag,
                          ),
                        ),
                      ),
                      if (_debugRevealed)
                        SizedBox(
                          height: _debugPanelHeight(context),
                          child: DebugPanelSection(
                            store: services.debugCaptureStore,
                            onHide: () =>
                                setState(() => _debugRevealed = false),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Builds the list of FormSection cards rendered in the top-of-screen
  /// scroll area. Pulled out of [build] so the body Column can split into a
  /// top scroll region + a pinned bottom band cleanly.
  List<Widget> _buildSections({
    required Services services,
    required String companyId,
    required bool canViewServerLogs,
    required List<(String, String)> appRows,
    required List<(String, String)> serverRows,
    required List<(String, String)> outboxRows,
    required DiagnosticsLog? diag,
  }) {
    return [
      if (companyId.isNotEmpty && canViewServerLogs)
        _buildSystemLogsSection(services: services, companyId: companyId),
      FormSection(
        title: context.tr('application'),
        children: [
          for (final row in appRows)
            _DiagnosticRow(label: row.$1, value: row.$2),
        ],
      ),
      FormSection(
        title: context.tr('server'),
        children: [
          for (final row in serverRows)
            _DiagnosticRow(label: row.$1, value: row.$2),
        ],
      ),
      FormSection(
        title: context.tr('outbox'),
        children: [
          for (final row in outboxRows)
            _DiagnosticRow(label: row.$1, value: row.$2),
        ],
      ),
      if (diag != null)
        FormSection(
          title: context.tr('diagnostics_log'),
          children: [
            _DiagnosticRow(
              label: context.tr('diagnostics_log_path'),
              value: diag.path,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.note_add_outlined),
                label: Text(context.tr('append_outbox_snapshot')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                onPressed: companyId.isEmpty
                    ? null
                    : () => _appendSnapshot(
                          services: services,
                          diag: diag,
                          companyId: companyId,
                        ),
              ),
            ),
          ],
        ),
    ];
  }

  Widget _buildSystemLogsSection({
    required Services services,
    required String companyId,
  }) {
    final tokens = context.inTheme;
    final lastFetchedLabel = _lastFetchedAt == null
        ? null
        : formatRelativeTime(
            context,
            DateTime.now().toUtc().difference(_lastFetchedAt!.toUtc()),
          );
    return FormSection(
      title: context.tr('system_logs'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lastFetchedLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${context.tr('last_refreshed')}: $lastFetchedLabel',
                style: TextStyle(fontSize: 12, color: tokens.ink3),
              ),
            ),
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: context.tr('refresh'),
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
      ),
      children: [
        StreamBuilder<List<SystemLog>>(
          stream: services.systemLogs.watch(companyId),
          builder: (context, snap) {
            final rows = snap.data ?? const <SystemLog>[];
            return _buildSectionBody(rows: rows, tokens: tokens);
          },
        ),
      ],
    );
  }

  Widget _buildSectionBody({
    required List<SystemLog> rows,
    required InTheme tokens,
  }) {
    if (rows.isEmpty) {
      if (_lastRefresh == SystemLogRefreshResult.forbidden ||
          _lastRefresh == SystemLogRefreshResult.notFound) {
        return EmptyState(
          icon: Icons.lock_outline,
          title: context.tr('system_logs_unavailable'),
          subtitle: context.tr('system_logs_unavailable_help'),
        );
      }
      if (_lastRefresh == SystemLogRefreshResult.networkError) {
        return ErrorView(
          message: context.tr('system_logs_load_failed'),
          onRetry: _refresh,
        );
      }
      if (_refreshing || !_initialFetchAttempted) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      return EmptyState(
        icon: Icons.terminal_outlined,
        title: context.tr('no_system_logs'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = Breakpoints.isWide(constraints);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: tokens.border),
              _SystemLogRow(log: rows[i], isWide: isWide),
            ],
          ],
        );
      },
    );
  }

  Future<void> _copy(List<(String, String)> rows) async {
    final text = rows.map((r) => '${r.$1}: ${r.$2}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    Notify.success(context, context.tr('copied_to_clipboard'));
  }

  Future<void> _appendSnapshot({
    required Services services,
    required DiagnosticsLog diag,
    required String companyId,
  }) async {
    final count = await diag.appendOutboxSnapshot(
      db: services.db,
      companyId: companyId,
    );
    if (!mounted) return;
    Notify.success(
      context,
      context.tr('wrote_stale_rows', {'count': '$count'}),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: TextStyle(
              color: tokens.ink3,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(color: tokens.ink, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// One row in the System Logs feed. Renders category / type / event in a
/// responsive layout (left-column on wide; stacked on narrow) with a
/// collapsible JSON viewer for the `log` payload.
class _SystemLogRow extends StatefulWidget {
  const _SystemLogRow({required this.log, required this.isWide});

  final SystemLog log;
  final bool isWide;

  @override
  State<_SystemLogRow> createState() => _SystemLogRowState();
}

class _SystemLogRowState extends State<_SystemLogRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final relative = formatRelativeTime(
      context,
      DateTime.now().toUtc().difference(widget.log.createdAt.toUtc()),
    );
    final categoryLabel = context.tr(widget.log.categoryKey);
    final typeDisp = widget.log.typeDisplay();
    final typeText = typeDisp.isKey
        ? context.tr(typeDisp.value)
        : typeDisp.value;
    final eventLabel = context.tr(widget.log.eventKey);
    final (eventFg, eventBg) = _toneColors(tokens, widget.log.tone);
    final meta = '$typeText · $relative';

    final categoryWidget = Text(
      categoryLabel,
      style: TextStyle(
        color: tokens.ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
    final metaWidget = Text(
      meta,
      style: TextStyle(color: tokens.ink3, fontSize: 12),
    );
    final pill = StatusPill(
      label: eventLabel,
      fgColor: eventFg,
      bgColor: eventBg,
    );
    final logBlock = _LogBlock(
      raw: widget.log.log,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
    );

    final body = widget.isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    categoryWidget,
                    const SizedBox(height: 2),
                    metaWidget,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: pill),
                    const SizedBox(height: 8),
                    logBlock,
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: categoryWidget),
                  const SizedBox(width: 8),
                  pill,
                ],
              ),
              const SizedBox(height: 2),
              metaWidget,
              const SizedBox(height: 8),
              logBlock,
            ],
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: body,
    );
  }

  (Color fg, Color bg) _toneColors(InTheme tokens, SystemLogTone tone) {
    switch (tone) {
      case SystemLogTone.success:
        return (tokens.paid, tokens.paidSoft);
      case SystemLogTone.failure:
        return (tokens.overdue, tokens.overdueSoft);
      case SystemLogTone.warning:
        return (tokens.sent, tokens.sentSoft);
      case SystemLogTone.neutral:
        return (tokens.ink3, tokens.accentSoft);
    }
  }
}

/// Collapsible JSON / text view for the `log` field. Pretty-prints decoded
/// JSON; falls back to the raw string when `jsonDecode` throws. Collapsed
/// state shows a one-line preview + chevron; expanded state shows the
/// monospace `SelectableText` block with a copy button.
class _LogBlock extends StatelessWidget {
  const _LogBlock({
    required this.raw,
    required this.expanded,
    required this.onToggle,
  });

  final String raw;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final decoded = _tryDecode(raw);
    final preview = _preview(raw, decoded);

    if (!expanded) {
      return InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(InRadii.r2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.ink3,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 18,
                color: tokens.ink3,
              ),
            ],
          ),
        ),
      );
    }

    final pretty = decoded == null
        ? raw
        : const JsonEncoder.withIndent('  ').convert(decoded);

    return Container(
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 16),
                visualDensity: VisualDensity.compact,
                tooltip: context.tr('copy'),
                onPressed: () => _copy(context),
              ),
              IconButton(
                icon: const Icon(Icons.expand_less, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: onToggle,
              ),
            ],
          ),
          SelectableText(
            pretty,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: tokens.ink,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: raw));
    if (!context.mounted) return;
    Notify.success(context, context.tr('copied_to_clipboard'));
  }

  Object? _tryDecode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final first = trimmed.codeUnitAt(0);
    if (first != 0x7B /* { */ && first != 0x5B /* [ */) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  String _preview(String raw, Object? decoded) {
    if (decoded is Map) {
      return '{ ${decoded.length} fields }';
    }
    if (decoded is List) {
      return '[ ${decoded.length} items ]';
    }
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 80) return cleaned;
    return '${cleaned.substring(0, 80)}…';
  }
}
