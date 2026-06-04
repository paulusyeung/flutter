import 'package:flutter/material.dart';

import 'package:admin/ui/features/settings/view_models/email_settings_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/email_settings/email_settings_body.dart';
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';

/// Settings → Email Settings. Cascade-aware (company / group / client) — the
/// scaffold swaps to the shared `ClientSettingsDraftViewModel` at non-company
/// scope; per-page customization (the `_sync_send_time` one-shot flag) lives
/// in [EmailSettingsViewModel].
///
/// Save is additionally gated on the Gmail / Microsoft user picker:
/// selecting those providers without a connected user leaves Save disabled
/// (matches admin-portal's `_isFormValid` rule).
class EmailSettingsScreen extends StatelessWidget {
  const EmailSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CascadeSettingsScaffold(
      titleKey: 'email_settings',
      companyVmFactory: ({required repo, required companyId}) =>
          EmailSettingsViewModel(repo: repo, companyId: companyId),
      body: const EmailSettingsBody(),
      canSaveOverride: _emailSaveGate,
    );
  }

  static bool _emailSaveGate(SettingsDraftHost host) {
    // A custom email style must contain the `$body` placeholder, or the
    // server renders a broken email. The inline red `_BodyVariableChip`
    // explains why Save is disabled. Matches v1 (save-time dialog) + React.
    if (host.settings.emailStyle == 'custom' &&
        !(host.settings.emailStyleCustom ?? '').contains(r'$body')) {
      return false;
    }
    final method = host.settings.emailSendingMethod;
    if (method != 'gmail' && method != 'office365' && method != 'microsoft') {
      return true;
    }
    final userId = host.settings.gmailSendingUserId ?? '';
    return userId.isNotEmpty && userId != '0';
  }
}
