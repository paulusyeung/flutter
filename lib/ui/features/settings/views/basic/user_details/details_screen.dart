import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/language.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/markdown_text_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';
import 'package:admin/ui/features/settings/view_models/user_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Search keys for the Settings > User Details > Details tab. Colocated so
/// the search catalog stays in sync with what this screen renders — see
/// `lib/ui/features/settings/settings_search_catalog.dart`.
const kUserDetailsDetailsSearchKeys = <String>[
  'first_name',
  'last_name',
  'email',
  'phone',
  'document_language',
  'signature',
  'sign_out',
];

class UserDetailsDetailsScreen extends StatelessWidget {
  const UserDetailsDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDetailsViewModel>(
      builder: (context, vm, _) {
        if (!vm.isLoaded || !vm.draftReady) {
          return const Center(child: CircularProgressIndicator());
        }
        return SettingsFormShell(
          sections: [
            FormSection(
              title: context.tr('profile'),
              children: const [_DetailsForm()],
            ),
            const _SignOutSection(),
          ],
        );
      },
    );
  }
}

class _DetailsForm extends StatelessWidget {
  const _DetailsForm();

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final vm = context.watch<UserDetailsViewModel>();
    final user = vm.user;
    if (user == null) return const SizedBox.shrink();

    final languages = services.statics.languages.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final activeLanguage = languages
        .where((l) => l.id == user.languageId)
        .cast<Language?>()
        .firstWhere((_) => true, orElse: () => null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NameRow(user: user, vm: vm),
        SizedBox(height: InSpacing.lg(context)),
        _PlainTextField(
          label: context.tr('email'),
          initial: user.email,
          keyboardType: TextInputType.emailAddress,
          errorText: vm.fieldErrors['email']?.firstOrNull,
          onChanged: (v) => vm.updateUser((u) => u.copyWith(email: v.trim())),
        ),
        SizedBox(height: InSpacing.lg(context)),
        _PlainTextField(
          label: context.tr('phone'),
          initial: user.phone,
          keyboardType: TextInputType.phone,
          errorText: vm.fieldErrors['phone']?.firstOrNull,
          onChanged: (v) => vm.updateUser((u) => u.copyWith(phone: v.trim())),
        ),
        SizedBox(height: InSpacing.lg(context)),
        SearchableDropdownField<Language>(
          label: context.tr('document_language'),
          items: languages,
          initialValue: activeLanguage,
          displayString: (l) => l.name,
          idOf: (l) => l.id,
          onChanged: (l) =>
              vm.updateUser((u) => u.copyWith(languageId: l?.id ?? '')),
          errorText: vm.fieldErrors['language_id']?.firstOrNull,
        ),
        SizedBox(height: InSpacing.lg(context)),
        MarkdownTextField(
          label: context.tr('signature'),
          initialValue: user.signature,
          height: 180,
          onChanged: (v) => vm.updateUser((u) => u.copyWith(signature: v)),
        ),
      ],
    );
  }
}

/// First name + last name share a row on wide screens, stack on narrow.
class _NameRow extends StatelessWidget {
  const _NameRow({required this.user, required this.vm});
  final dynamic user;
  final UserDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final firstField = _PlainTextField(
      label: context.tr('first_name'),
      initial: user.firstName as String,
      errorText: vm.fieldErrors['first_name']?.firstOrNull,
      onChanged: (v) => vm.updateUser((u) => u.copyWith(firstName: v.trim())),
    );
    final lastField = _PlainTextField(
      label: context.tr('last_name'),
      initial: user.lastName as String,
      errorText: vm.fieldErrors['last_name']?.firstOrNull,
      onChanged: (v) => vm.updateUser((u) => u.copyWith(lastName: v.trim())),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              firstField,
              SizedBox(height: InSpacing.lg(context)),
              lastField,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: firstField),
            SizedBox(width: InSpacing.md(context)),
            Expanded(child: lastField),
          ],
        );
      },
    );
  }
}

/// Thin `TextField` wrapper that submits the form on Enter (via
/// [FormSaveScope.maybeOf]) and re-seeds when the upstream value changes
/// — important after a successful save resets the baseline. Multi-line
/// fields keep Enter for newlines (default behaviour) and so use a plain
/// `TextField` directly.
class _PlainTextField extends StatefulWidget {
  const _PlainTextField({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.keyboardType,
    this.errorText,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? errorText;

  @override
  State<_PlainTextField> createState() => _PlainTextFieldState();
}

class _PlainTextFieldState extends State<_PlainTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant _PlainTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-seed only when upstream changes — guards against clobbering an
    // in-progress edit while the user is typing.
    if (widget.initial != _controller.text &&
        widget.initial != oldWidget.initial) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = FormSaveScope.maybeOf(context);
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
      ),
      onChanged: widget.onChanged,
      onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
    );
  }
}

/// Right-aligned Sign Out section. Wrapped in its own FormSection so it
/// reads as a discrete area below the profile fields.
class _SignOutSection extends StatefulWidget {
  const _SignOutSection();

  @override
  State<_SignOutSection> createState() => _SignOutSectionState();
}

class _SignOutSectionState extends State<_SignOutSection> {
  bool _busy = false;

  Future<void> _onSignOutPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(dialogCtx.tr('sign_out')),
          content: Text(dialogCtx.tr('are_you_sure')),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(dialogCtx.tr('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 44),
                backgroundColor: Theme.of(dialogCtx).colorScheme.error,
                foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(dialogCtx.tr('sign_out')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await SettingsActions.signOut(context);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('sign_out'),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _onSignOutPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
              minimumSize: const Size(64, 40),
            ),
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(context.tr('sign_out')),
          ),
        ),
      ],
    );
  }
}
