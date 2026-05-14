import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/diagnostics_log.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/version.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Holds the System Logs route for now. Until server-log streaming lands, it
/// surfaces the same app+sync diagnostics that the standalone Diagnostics
/// screen used to show.
class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
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
                return SettingsScreenScaffold(
                  titleKey: 'system_logs',
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: context.tr('copy_diagnostics'),
                      onPressed: () => _copy(allRows),
                    ),
                  ],
                  body: SettingsFormShell(
                    sections: [
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

  Future<void> _copy(List<(String, String)> rows) async {
    final text = rows.map((r) => '${r.$1}: ${r.$2}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    Notify.success(context, context.tr('copied_to_clipboard'));
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
