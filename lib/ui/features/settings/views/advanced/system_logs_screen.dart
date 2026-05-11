import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/app/version.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: Text(context.tr('system_logs')),
            leading: wide ? null : const DrawerHamburger(),
            automaticallyImplyLeading: !wide,
          ),
          body: ValueListenableBuilder<String?>(
            valueListenable: services.serverVersion,
            builder: (context, serverVersion, _) {
              final session = services.auth.session.value;
              final companyId = session?.currentCompanyId ?? '';
              return StreamBuilder<int>(
                stream: services.db.outboxDao.watchPendingCount(
                  companyId: companyId,
                ),
                builder: (context, pendingSnap) {
                  return StreamBuilder<int>(
                    stream: services.db.outboxDao.watchDeadCount(
                      companyId: companyId,
                    ),
                    builder: (context, deadSnap) {
                      final pending = pendingSnap.data ?? 0;
                      final dead = deadSnap.data ?? 0;
                      final rows = <(String, String)>[
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
                        (context.tr('pending_outbox_rows'), '$pending'),
                        (context.tr('dead_outbox_rows'), '$dead'),
                      ];
                      return ListView(
                        children: [
                          for (final row in rows)
                            ListTile(
                              dense: true,
                              title: Text(row.$1),
                              subtitle: SelectableText(row.$2),
                            ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: FilledButton.icon(
                              icon: const Icon(Icons.copy),
                              label: Text(context.tr('copy_diagnostics')),
                              onPressed: () => _copy(rows),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _copy(List<(String, String)> rows) async {
    final text = rows.map((r) => '${r.$1}: ${r.$2}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('copied_to_clipboard'))));
  }
}
