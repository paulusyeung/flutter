import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/features/settings/view_models/user_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

const kUserDetailsPasswordSearchKeys = <String>[
  'password',
  'new_password',
  'confirm_password',
];

class UserDetailsPasswordScreen extends StatefulWidget {
  const UserDetailsPasswordScreen({super.key});

  @override
  State<UserDetailsPasswordScreen> createState() =>
      _UserDetailsPasswordScreenState();
}

class _UserDetailsPasswordScreenState extends State<UserDetailsPasswordScreen> {
  late final TextEditingController _password;
  late final TextEditingController _confirm;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _password = TextEditingController();
    _confirm = TextEditingController();
    _password.addListener(_onChanged);
    _confirm.addListener(_onChanged);
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _onChanged() {
    final vm = context.read<UserDetailsViewModel>();
    final pw = _password.text;
    final cn = _confirm.text;
    final ready = pw.isNotEmpty && pw == cn && pw.length >= 6;
    vm.setPendingPassword(ready ? pw : null);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserDetailsViewModel>();
    final fieldError = vm.fieldErrors['password']?.firstOrNull;
    final scope = FormSaveScope.maybeOf(context);
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('password'),
          children: [
            TextField(
              controller: _password,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: context.tr('new_password'),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscure
                      ? context.tr('show_password')
                      : context.tr('hide_password'),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                errorText: fieldError,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: InSpacing.lg),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: context.tr('confirm_password'),
                errorText: _confirmError(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
            ),
          ],
        ),
      ],
    );
  }

  String? _confirmError() {
    final pw = _password.text;
    final cn = _confirm.text;
    if (cn.isEmpty) return null;
    if (pw == cn) return null;
    return context.tr('passwords_do_not_match');
  }
}
