import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';

/// Modal that captures the user's password for destructive server endpoints
/// (`delete`, `purge`, …). Writes to [PasswordCache] on Confirm; the sync
/// engine retries the parked outbox row once the cache is populated.
///
/// Triggered by the shell listening for [PasswordRequiredEvent] on the
/// [SyncRepository.events] stream. Also callable directly from any UI that
/// wants to prime the cache before a destructive action.
///
/// Returns `true` if the user confirmed (cache is populated), `false` if
/// they cancelled (cache untouched).
Future<bool> showConfirmPasswordSheet(
  BuildContext context, {
  required PasswordCache cache,
  String? message,
}) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return _ConfirmPasswordDialog(
        controller: controller,
        message: message ?? ctx.tr('confirm_password_message'),
        onConfirm: (pw) {
          cache.set(pw);
          Navigator.of(ctx).pop(true);
        },
        onCancel: () => Navigator.of(ctx).pop(false),
      );
    },
  );
  controller.dispose();
  return confirmed ?? false;
}

class _ConfirmPasswordDialog extends StatefulWidget {
  const _ConfirmPasswordDialog({
    required this.controller,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  });

  final TextEditingController controller;
  final String message;
  final void Function(String password) onConfirm;
  final VoidCallback onCancel;

  @override
  State<_ConfirmPasswordDialog> createState() => _ConfirmPasswordDialogState();
}

class _ConfirmPasswordDialogState extends State<_ConfirmPasswordDialog> {
  bool _obscure = true;

  bool get _canSubmit => widget.controller.text.isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    widget.onConfirm(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return AlertDialog(
      title: Text(context.tr('confirm_password_title')),
      content: FormSaveScope(
        enabled: true,
        onSubmit: _submit,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.message, style: TextStyle(color: tokens.ink2)),
            const SizedBox(height: InSpacing.md),
            _PasswordField(
              controller: widget.controller,
              obscure: _obscure,
              onObscureToggle: () => setState(() => _obscure = !_obscure),
              onChanged: (_) => setState(() {}),
              onSubmitted: _submit,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          // Override the theme's full-width minimumSize so the primary
          // action sits beside Cancel — see lib/app/theme.dart and the
          // canonical example in company_picker.dart.
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: _canSubmit ? _submit : null,
          child: Text(context.tr('confirm')),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onObscureToggle,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onObscureToggle;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autofocus: true,
      decoration: InputDecoration(
        labelText: context.tr('password'),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onObscureToggle,
        ),
      ),
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
    );
  }
}
