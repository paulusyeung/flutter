import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';

/// Banner that announces the current settings-edit scope when it isn't the
/// company. Renders nothing at [SettingsLevel.company]; at client (or
/// future group) level it shows a one-line "Client Settings: \<Name\>"
/// strip with a close button that resets the scope.
///
/// Mounted in two places — once inside the wide-mode shell, once at the
/// top of the per-section scaffold — so it appears regardless of layout.
/// The widget is cheap (single `Provider.watch`), and the duplicated
/// mount just renders one of the two depending on which path go_router
/// picks.
class SettingsScopeBanner extends StatelessWidget {
  const SettingsScopeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsLevelController>();
    if (controller.isCompany) return const SizedBox.shrink();
    final tokens = context.inTheme;
    final name = controller.targetName ?? '';
    final labelKey = controller.isGroup ? 'group_settings' : 'client_settings';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        border: Border(bottom: BorderSide(color: tokens.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: InSpacing.lg,
        vertical: InSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: tokens.ink),
          const SizedBox(width: InSpacing.sm),
          Expanded(
            child: Text(
              '${context.tr(labelKey)}: $name',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.ink,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: context.tr('close'),
            icon: const Icon(Icons.close, size: 18),
            onPressed: () async {
              // Reuse the app-wide unsaved-changes guard so the discard
              // dialog mirrors company-switch and PopScope behavior. On
              // Discard every registered editor's `onDiscard` runs, so the
              // current sub-page's draft resets cleanly before the scope
              // flips. The current route is preserved — the route helpers
              // in `settings_routes.dart` remount the sub-page when the
              // level changes, so we don't navigate here.
              final guard = context.read<Services>().unsavedChangesGuard;
              if (!await guard.confirmIfDirty(context)) return;
              controller.reset();
            },
          ),
        ],
      ),
    );
  }
}
