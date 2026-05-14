import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/group_setting.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/language.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/view_models/group_setting_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// `/settings/group_settings/new` and `/settings/group_settings/:id`.
///
/// Edit-or-create form for a group. Save sits in the AppBar (per the rest
/// of the settings sidebar) plus an overflow menu with Archive / Restore /
/// Delete for existing groups.
class GroupSettingsEditScreen extends StatefulWidget {
  const GroupSettingsEditScreen({this.existingId, super.key});

  final String? existingId;

  @override
  State<GroupSettingsEditScreen> createState() =>
      _GroupSettingsEditScreenState();
}

class _GroupSettingsEditScreenState extends State<GroupSettingsEditScreen> {
  late final Services _services = context.read<Services>();
  late final String _companyId =
      _services.auth.session.value?.currentCompanyId ?? '';

  GroupSettingEditViewModel? _vm;
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.existingId == null) {
      setState(() {
        _vm = GroupSettingEditViewModel(
          repo: _services.groupSettings,
          companyId: _companyId,
        );
        _loading = false;
      });
      return;
    }
    try {
      var existing = await _services.groupSettings
          .watch(companyId: _companyId, id: widget.existingId!)
          .first;
      if (existing == null) {
        // Deep-link entry (`/settings/group_settings/<id>` typed before the
        // user ever opened the list) leaves Drift empty for this row even
        // though the server might know it. Trigger a refresh and retry
        // once before declaring "not found."
        await _services.groupSettings.refreshAll(companyId: _companyId);
        if (!mounted) return;
        existing = await _services.groupSettings
            .watch(companyId: _companyId, id: widget.existingId!)
            .first;
      }
      if (!mounted) return;
      if (existing == null) {
        setState(() {
          _loadError = 'not_found';
          _loading = false;
        });
        return;
      }
      setState(() {
        _vm = GroupSettingEditViewModel(
          repo: _services.groupSettings,
          companyId: _companyId,
          existing: existing,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Future<void> _onSave() async {
    final vm = _vm;
    if (vm == null) return;
    final saved = await vm.save();
    if (saved == null || !mounted) return;
    // For both create and edit, pop back to the list — the new row is
    // already visible there via the stream.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings/group_settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.existingId == null;
    final titleKey = isCreate ? 'new_group' : 'edit_group';

    if (_loading) {
      return SettingsScreenScaffold(
        titleKey: titleKey,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null || _vm == null) {
      return SettingsScreenScaffold(
        titleKey: titleKey,
        body: EmptyState(
          icon: Icons.error_outline,
          title: context.tr('not_found'),
          action: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => context.go('/settings/group_settings'),
            child: Text(context.tr('back')),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _vm!,
      child: Consumer<GroupSettingEditViewModel>(
        builder: (context, vm, _) {
          // Save is gated on both `isSaving` (mutually exclusive submits)
          // and `isDirty` (a no-op save would still enqueue an outbox row
          // and bump the server's `updated_at`).
          final canSave = !vm.isSaving && vm.isDirty;
          return SettingsScreenScaffold(
            titleKey: titleKey,
            actions: [
              if (!isCreate) _GroupOverflowMenu(group: vm.draft),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 36),
                  ),
                  onPressed: canSave ? _onSave : null,
                  child: vm.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('save')),
                ),
              ),
            ],
            body: FormSaveScope(
              onSubmit: _onSave,
              enabled: canSave,
              child: SettingsFormShell(
                sections: [
                  FormSection(
                    title: context.tr('group'),
                    children: [
                      _NameField(vm: vm),
                      _CurrencyField(vm: vm),
                      _LanguageField(vm: vm),
                      _CountryField(vm: vm),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({required this.vm});
  final GroupSettingEditViewModel vm;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.vm.draft.name,
  );

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
      decoration: InputDecoration(
        labelText: context.tr('name'),
        errorText: widget.vm.fieldErrorFor('name'),
      ),
      textInputAction: TextInputAction.done,
      onChanged: widget.vm.setName,
      onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({required this.vm});
  final GroupSettingEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final currencies = statics.currencies.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final current = vm.draft.currencyId == null
        ? null
        : statics.currency(vm.draft.currencyId!);
    return SearchableDropdownField<Currency>(
      label: context.tr('currency'),
      items: currencies,
      initialValue: current,
      displayString: (c) => '${c.code} — ${c.name}',
      idOf: (c) => c.id,
      onChanged: (c) => vm.setCascadeOverride('currency_id', c?.id),
    );
  }
}

class _LanguageField extends StatelessWidget {
  const _LanguageField({required this.vm});
  final GroupSettingEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final languages = statics.languages.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final current = vm.draft.languageId == null
        ? null
        : statics.language(vm.draft.languageId!);
    return SearchableDropdownField<Language>(
      label: context.tr('language'),
      items: languages,
      initialValue: current,
      displayString: (l) => l.name,
      idOf: (l) => l.id,
      onChanged: (l) => vm.setCascadeOverride('language_id', l?.id),
    );
  }
}

class _CountryField extends StatelessWidget {
  const _CountryField({required this.vm});
  final GroupSettingEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final countries = statics.countries.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final current = vm.draft.countryId == null
        ? null
        : statics.country(vm.draft.countryId!);
    return SearchableDropdownField<Country>(
      label: context.tr('country'),
      items: countries,
      initialValue: current,
      displayString: (c) => c.name,
      idOf: (c) => c.id,
      onChanged: (c) => vm.setCascadeOverride('country_id', c?.id),
    );
  }
}

/// Archive / Restore / Delete overflow menu for the edit screen. Visible
/// only for existing groups; uses the standard action helpers so the
/// success toasts follow the `<verb>_group` localization convention.
class _GroupOverflowMenu extends StatelessWidget {
  const _GroupOverflowMenu({required this.group});
  final GroupSetting group;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final canArchive = group.archivedAt == null && !group.isDeleted;
    final canRestore = group.archivedAt != null || group.isDeleted;

    return PopupMenuButton<String>(
      tooltip: context.tr('more_actions'),
      onSelected: (action) async {
        switch (action) {
          case 'archive':
            await StandardEntityActions.archive(
              context: context,
              wireName: 'group',
              op: () => services.groupSettings.archive(
                companyId: companyId,
                id: group.id,
              ),
            );
            if (context.mounted && context.canPop()) context.pop();
          case 'restore':
            await StandardEntityActions.restore(
              context: context,
              wireName: 'group',
              op: () => services.groupSettings.restore(
                companyId: companyId,
                id: group.id,
              ),
            );
            if (context.mounted && context.canPop()) context.pop();
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(ctx.tr('delete')),
                content: Text(ctx.tr('are_you_sure')),
                actions: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 40),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(ctx.tr('cancel')),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 44),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(ctx.tr('delete')),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            await StandardEntityActions.delete(
              context: context,
              wireName: 'group',
              op: () => services.groupSettings.delete(
                companyId: companyId,
                id: group.id,
              ),
            );
            if (context.mounted && context.canPop()) context.pop();
        }
      },
      itemBuilder: (context) => [
        if (canArchive)
          PopupMenuItem(value: 'archive', child: Text(context.tr('archive'))),
        if (canRestore)
          PopupMenuItem(value: 'restore', child: Text(context.tr('restore'))),
        PopupMenuItem(value: 'delete', child: Text(context.tr('delete'))),
      ],
    );
  }
}
