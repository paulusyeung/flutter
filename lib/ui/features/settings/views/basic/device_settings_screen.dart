import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';
import 'package:admin/ui/features/settings/widgets/theme_tile.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

/// Top-level "Device Settings" page. Holds app-specific options that are not
/// stored on the server: theme, and the "download all data locally" action.
/// Unlike most settings screens this has no cascade — every control writes
/// directly to a device-local store (e.g. `nav_state` for theme).
class DeviceSettingsScreen extends StatelessWidget {
  const DeviceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: Text(context.tr('device_settings')),
            leading: wide ? null : const DrawerHamburger(),
            automaticallyImplyLeading: !wide,
          ),
          body: ListView(
            children: [
              ThemeTile(controller: services.theme),
              const Divider(height: 1),
              const _DownloadDataTile(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _DownloadDataTile extends StatefulWidget {
  const _DownloadDataTile();

  @override
  State<_DownloadDataTile> createState() => _DownloadDataTileState();
}

class _DownloadDataTileState extends State<_DownloadDataTile> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    await SettingsActions.forceResync(context);
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.cloud_download_outlined),
      title: Text(context.tr('refresh_data')),
      subtitle: Text(context.tr('download_data')),
      trailing: _running
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _running ? null : _run,
    );
  }
}
