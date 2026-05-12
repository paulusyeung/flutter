import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/auth/view_models/lock_view_model.dart';

/// Cold-launch biometric gate. Shown by the router when
/// `AuthRepository.requiresBiometricUnlock` is true. Auto-prompts on mount
/// (matching admin-portal `main_app.dart:228-229`); the user can retry via
/// the Unlock button or fall back to Sign out.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final LockViewModel _vm;

  @override
  void initState() {
    super.initState();
    final services = context.read<Services>();
    _vm = LockViewModel(auth: services.auth, biometric: services.biometric);
    // Auto-trigger on mount, but defer past the first frame so the
    // Localization delegate has resolved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm.unlock(context.tr('please_authenticate'));
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _onUnlock() async {
    await _vm.unlock(context.tr('please_authenticate'));
  }

  Future<void> _onSignOut() async {
    await _vm.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: InSpacing.xl,
                vertical: InSpacing.xxl,
              ),
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 64, color: tokens.accent),
                      const SizedBox(height: InSpacing.lg),
                      Text(
                        context.tr('biometric_authentication'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: tokens.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: InSpacing.sm),
                      Text(
                        context.tr('please_authenticate'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: tokens.ink2, height: 1.4),
                      ),
                      const SizedBox(height: InSpacing.xxl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            key: const ValueKey('lock_sign_out'),
                            onPressed: _vm.busy ? null : _onSignOut,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(120, 40),
                            ),
                            child: Text(context.tr('sign_out')),
                          ),
                          const SizedBox(width: InSpacing.md),
                          FilledButton.icon(
                            key: const ValueKey('lock_unlock'),
                            onPressed: _vm.busy ? null : _onUnlock,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(120, 44),
                            ),
                            icon: _vm.busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.fingerprint, size: 18),
                            label: Text(context.tr('unlock')),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
