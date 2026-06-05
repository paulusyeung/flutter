import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Settings → Device Settings → Security → Biometric Authentication toggle.
///
/// Assumes the caller only mounts it when biometrics are available — the Device
/// Settings screen gates the whole Security section on
/// `BiometricService.isAvailable()`, so this tile doesn't re-check. Enabling
/// prompts the device first (verifying intent) before persisting; disabling is
/// immediate. Mirrors admin-portal's `device_settings_vm.dart:157-173`.
class BiometricToggleTile extends StatefulWidget {
  const BiometricToggleTile({super.key});

  @override
  State<BiometricToggleTile> createState() => _BiometricToggleTileState();
}

class _BiometricToggleTileState extends State<BiometricToggleTile> {
  bool _busy = false;

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      if (value) {
        final ok = await services.biometric.authenticate(
          reason: context.tr('confirm_to_enable_biometric'),
        );
        if (!ok) return; // toggle stays off — session value still false
      }
      await services.auth.setBiometricEnabled(value);
    } catch (e) {
      if (mounted) {
        Notify.error(
          context,
          context.tr('could_not_save'),
          messenger: messenger,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: context.read<Services>().auth.session,
      builder: (context, session, _) {
        final enabled = session?.biometricEnabled ?? false;
        return SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: Text(context.tr('biometric_authentication')),
          subtitle: Text(context.tr('enable_biometric_description')),
          value: enabled,
          onChanged: _busy ? null : _onChanged,
        );
      },
    );
  }
}
