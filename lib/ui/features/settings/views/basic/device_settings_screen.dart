import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/text_scale_controller.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';
import 'package:admin/ui/features/settings/widgets/biometric_toggle_tile.dart';
import 'package:admin/ui/features/settings/widgets/customize_colors_section.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/segmented_setting_row.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/theme_tile.dart';
import 'package:admin/utils/formatting.dart';

/// Top-level "Device Settings" page. Holds the device-local, no-save controls:
/// theme (mode + palette), the per-preset colour overrides, biometric
/// security, and the "download all data locally" action. Unlike most settings
/// screens this has no cascade and no save bar — every control writes
/// immediately to a device-local store (`nav_state`). Only the accent colour
/// is server-synced; it lives on User Details → Preferences with the save bar.
class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  // Resolved once on mount so the Security section either renders or is
  // omitted entirely — without this gate, devices without biometrics (most
  // desktops) would see an empty labeled "Security" card.
  late final Future<bool> _biometricAvailable;

  @override
  void initState() {
    super.initState();
    _biometricAvailable = context.read<Services>().biometric.isAvailable();
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return SettingsScreenScaffold(
      titleKey: 'device_settings',
      body: FutureBuilder<bool>(
        future: _biometricAvailable,
        builder: (context, snap) {
          final showSecurity = snap.data == true;
          return SettingsFormShell(
            sections: [
              FormSection(
                title: context.tr('theme'),
                spacing: 0,
                children: [
                  ThemeTile(controller: services.theme),
                  _FontSizeRow(controller: services.textScale),
                  const Divider(height: 1),
                  CustomizeColorsSection(controller: services.theme),
                ],
              ),
              if (showSecurity)
                FormSection(
                  title: context.tr('security'),
                  children: const [BiometricToggleTile()],
                ),
              const _DataSection(),
            ],
          );
        },
      ),
    );
  }
}

/// Device-local UI text-scale picker (Small / Normal / Large / Extra Large).
/// Same responsive [SegmentedSettingRow] shape as the theme mode/palette rows,
/// so it lines up under them in the Theme section.
class _FontSizeRow extends StatelessWidget {
  const _FontSizeRow({required this.controller});

  final TextScaleController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller,
      builder: (context, scale, _) {
        return SegmentedSettingRow(
          leading: const Icon(Icons.format_size_outlined),
          title: context.tr('font_size'),
          subtitle: context.tr(textScaleLabelKey(scale)),
          // Natural-width 4-segment button (vs the fixed-width theme rows):
          // cap + scroll it in the trailing slot so "Extra Large" at a large
          // text scale can't overflow the ListTile.
          scrollableTrailing: true,
          control: SegmentedButton<double>(
            showSelectedIcon: false,
            segments: [
              for (final option in kTextScaleOptions)
                ButtonSegment(
                  value: option,
                  // Natural width rather than the fixed-80px `segmentLabel`:
                  // these 4 size labels don't column-align with the 3-segment
                  // theme rows above, and "Extra Large" clips in 80px.
                  label: Text(context.tr(textScaleLabelKey(option))),
                ),
            ],
            selected: {scale},
            onSelectionChanged: (s) => controller.set(s.first),
          ),
        );
      },
    );
  }
}

class _DataSection extends StatefulWidget {
  const _DataSection();

  @override
  State<_DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<_DataSection> {
  bool _running = false;
  int? _lastSyncAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadLastSync();
    // Keep the relative "last updated" label fresh while the screen is open
    // ("just now" → "2m ago") without needing a manual refresh.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Read the active company's last-sync high-water mark so the user can see
  /// how stale their local cache is. One-shot (re-read after a download) — the
  /// value only moves on sync.
  Future<void> _loadLastSync() async {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null) return;
    final row = await services.db.companiesDao.byId(companyId);
    if (mounted) setState(() => _lastSyncAt = row?.lastSyncAt);
  }

  Future<void> _run() async {
    setState(() => _running = true);
    await SettingsActions.forceResync(
      context,
      successKey: 'download_complete',
      failureKey: 'download_failed',
    );
    if (mounted) setState(() => _running = false);
    await _loadLastSync();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final lastSync = _lastSyncAt;
    return FormSection(
      title: context.tr('data'),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('download_data'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.ink2),
            ),
            if (lastSync != null && lastSync > 0) ...[
              SizedBox(height: InSpacing.sm),
              Text(
                '${context.tr('last_updated')}: '
                '${formatRelativeTime(context, DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastSync)))}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: tokens.ink3),
              ),
            ],
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            // Compact, content-sized button. Without this the themed
            // `Size.fromHeight(44)` default (= infinite min-width) would make
            // the button fill the stretched FormSection column, defeating the
            // centerRight alignment and rendering edge-to-edge.
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: _running ? null : _run,
            icon: _running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_outlined),
            label: Text(context.tr('download')),
          ),
        ),
      ],
    );
  }
}
