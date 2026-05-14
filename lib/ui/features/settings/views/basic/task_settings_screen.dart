import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/view_models/task_settings_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_number_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_company_scoped_host.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';

/// Searchable label keys rendered by this screen. Aggregated into
/// `kSettingsSearchCatalog['task_settings']` so the in-app search surfaces
/// these fields. `search_catalog_consistency_test` verifies every key here
/// appears as a `context.tr('…')` reference in this file.
const kTaskSettingsSearchKeys = <String>[
  'default_task_rate',
  'auto_start_tasks',
  'show_task_end_date',
  'show_task_item_description',
  'show_task_billable',
  'round_tasks',
  'direction',
  'task_round_to_nearest',
  'round_to_seconds',
  'configure_statuses',
  'show_tasks_table',
  'invoice_task_datelog',
  'invoice_task_timelog',
  'invoice_task_hours',
  'invoice_task_item_description',
  'invoice_task_project',
  'project_location',
  'lock_invoiced_tasks',
  'add_documents_to_invoice',
  'show_tasks_in_client_portal',
  'tasks_shown_in_portal',
];

/// Settings → Task Settings. Mixes top-level `company.*` toggles (auto
/// start, invoice task options, lock, documents) with cascade
/// `company.settings.*` fields (default rate, rounding, client portal).
///
/// Style: company-only `SettingsCompanyScopedHost` + `SettingsPageScaffold`
/// per CLAUDE.md § Settings screens — `CascadeSettingsScaffold` is wrong
/// here because top-level edits would be silently dropped at client scope.
/// `Overridable*` widgets still work inside this pattern; at company scope
/// they render plain, at non-company scope they show the override checkbox.
class TaskSettingsScreen extends StatelessWidget {
  const TaskSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return SettingsCompanyScopedHost<TaskSettingsViewModel>(
      create: (companyId) {
        final vm = TaskSettingsViewModel(
          repo: services.company,
          companyId: companyId,
        );
        unawaited(vm.load());
        return vm;
      },
      builder: (context, vm) => SettingsPageScaffold<TaskSettingsViewModel>(
        titleKey: 'task_settings',
        viewModel: vm,
        body: const _TaskSettingsBody(),
      ),
    );
  }
}

class _TaskSettingsBody extends StatelessWidget {
  const _TaskSettingsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskSettingsViewModel>();
    final scope = context.watch<SettingsLevelController>();
    final draft = vm.draft;
    if (draft == null) return const SizedBox.shrink();

    final isCompanyScope = scope.isCompany;
    final settings = vm.settings;

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('tasks'),
          children: [
            OverridableTextField(
              label: context.tr('default_task_rate'),
              apiKey: 'default_task_rate',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            if (isCompanyScope) ...[
              _TaskSwitch(
                label: context.tr('auto_start_tasks'),
                help: context.tr('auto_start_tasks_help'),
                value: draft.autoStartTasks,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(autoStartTasks: v)),
              ),
              _TaskSwitch(
                label: context.tr('show_task_end_date'),
                help: context.tr('show_task_end_date_help'),
                value: draft.showTaskEndDate,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(showTaskEndDate: v)),
              ),
            ],
            OverridableSwitchField(
              label: context.tr('show_task_item_description'),
              apiKey: 'show_task_item_description',
              subtitle: context.tr('show_task_item_description_help'),
            ),
            OverridableSwitchField(
              label: context.tr('show_task_billable'),
              apiKey: 'allow_billable_task_items',
              subtitle: context.tr('allow_billable_task_items_help'),
            ),
          ],
        ),
        _RoundingSection(
          settings: settings,
          isCompanyScope: isCompanyScope,
        ),
        if (isCompanyScope)
          FormSection(
            title: context.tr('invoicing'),
            children: [
              _TaskSwitch(
                label: context.tr('show_tasks_table'),
                help: context.tr('show_tasks_table_help'),
                value: draft.showTasksTable,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(showTasksTable: v)),
              ),
              _TaskSwitch(
                label: context.tr('invoice_task_datelog'),
                help: context.tr('invoice_task_datelog_help'),
                value: draft.invoiceTaskDatelog,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(invoiceTaskDatelog: v)),
              ),
              _TaskSwitch(
                label: context.tr('invoice_task_timelog'),
                help: context.tr('invoice_task_timelog_help'),
                value: draft.invoiceTaskTimelog,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(invoiceTaskTimelog: v)),
              ),
              _TaskSwitch(
                label: context.tr('invoice_task_hours'),
                help: context.tr('invoice_task_hours_help'),
                value: draft.invoiceTaskHours,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(invoiceTaskHours: v)),
              ),
              // Render disabled-with-tooltip when the cascade field gating
              // this row isn't enabled — fewer layout jumps than hide/show.
              _TaskSwitch(
                label: context.tr('invoice_task_item_description'),
                help: context.tr('invoice_task_item_description_help'),
                value: draft.invoiceTaskItemDescription,
                enabled: settings.showTaskItemDescription == true,
                disabledTooltip: context.tr('show_task_item_description'),
                onChanged: (v) => vm.updateCompany(
                  (c) => c.copyWith(invoiceTaskItemDescription: v),
                ),
              ),
              _TaskSwitch(
                label: context.tr('invoice_task_project'),
                help: context.tr('invoice_task_project_help'),
                value: draft.invoiceTaskProject,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(invoiceTaskProject: v)),
              ),
              _ProjectLocationDropdown(
                value: draft.invoiceTaskProjectHeader,
                enabled: draft.invoiceTaskProject,
                onChanged: (v) => vm.updateCompany(
                  (c) => c.copyWith(invoiceTaskProjectHeader: v),
                ),
              ),
              _TaskSwitch(
                label: context.tr('lock_invoiced_tasks'),
                help: context.tr('lock_invoiced_tasks_help'),
                value: draft.invoiceTaskLock,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(invoiceTaskLock: v)),
              ),
              _TaskSwitch(
                label: context.tr('add_documents_to_invoice'),
                help: context.tr('add_documents_to_invoice_help'),
                value: draft.invoiceTaskDocuments,
                onChanged: (v) => vm.updateCompany(
                  (c) => c.copyWith(invoiceTaskDocuments: v),
                ),
              ),
            ],
          ),
        FormSection(
          title: context.tr('client_portal'),
          children: [
            OverridableDropdownField<bool>(
              label: context.tr('show_tasks_in_client_portal'),
              apiKey: 'enable_client_portal_tasks',
              value: settings.enableClientPortalTasks,
              items: [
                DropdownMenuItem(
                  value: true,
                  child: Text(context.tr('enabled')),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text(context.tr('disabled')),
                ),
              ],
              onChanged: (v) => Provider.of<SettingsDraftHost>(context, listen: false)
                  .updateSettings((s) => s.copyWith(enableClientPortalTasks: v)),
            ),
            _PortalTasksDropdown(
              value: settings.showAllTasksClientPortal ?? 'invoiced',
              enabled: settings.enableClientPortalTasks != false,
            ),
          ],
        ),
      ],
    );
  }
}

/// Rounding card — gated UX (matches old Flutter). The "Round Tasks"
/// dropdown toggles the entire sub-section. Custom seconds field is
/// revealed when the user picks Custom in this session OR when the
/// loaded value isn't one of the preset values (parity with
/// admin-portal `_TaskSettingsState.isTaskRoundingCustom`).
class _RoundingSection extends StatefulWidget {
  const _RoundingSection({
    required this.settings,
    required this.isCompanyScope,
  });

  // ignore: unused_element_parameter
  final dynamic settings; // Avoid importing CompanySettings here.
  // ignore: unused_element_parameter
  final bool isCompanyScope;

  @override
  State<_RoundingSection> createState() => _RoundingSectionState();
}

class _RoundingSectionState extends State<_RoundingSection> {
  /// Sticky flag — set when the user actively selects "Custom" so the seconds
  /// field stays revealed even after they type a value that happens to match
  /// a preset (e.g. 60). Cleared when they pick a preset.
  bool _userPickedCustom = false;

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final raw = host.settings.taskRoundToNearest;
    final asInt = raw?.toInt();
    final enabled = raw != null && asInt != 1;
    final isPresetValue = asInt != null && _kPresetSeconds.contains(asInt);
    final isCustomValue = enabled && (asInt == 0 || !isPresetValue);
    final showCustomSeconds = enabled && (_userPickedCustom || isCustomValue);

    return FormSection(
      title: context.tr('rounding'),
      children: [
        OverridableDropdownField<bool>(
          label: context.tr('round_tasks'),
          apiKey: 'task_round_to_nearest',
          value: raw == null ? null : enabled,
          items: [
            DropdownMenuItem(value: true, child: Text(context.tr('enabled'))),
            DropdownMenuItem(value: false, child: Text(context.tr('disabled'))),
          ],
          onChanged: (v) {
            // Persists as `task_round_to_nearest`: null → cleared,
            // true → 900 (15 min default), false → 1 (explicitly disabled).
            host.updateSettings((s) {
              if (v == null) return s.copyWith(taskRoundToNearest: null);
              if (v) return s.copyWith(taskRoundToNearest: 900);
              return s.copyWith(taskRoundToNearest: 1);
            });
            setState(() => _userPickedCustom = false);
          },
        ),
        if (enabled) ...[
          OverridableDropdownField<bool>(
            label: context.tr('direction'),
            apiKey: 'task_round_up',
            value: host.settings.taskRoundUp,
            items: [
              DropdownMenuItem(
                value: false,
                child: Text(context.tr('round_down')),
              ),
              DropdownMenuItem(
                value: true,
                child: Text(context.tr('round_up')),
              ),
            ],
            onChanged: (v) =>
                host.updateSettings((s) => s.copyWith(taskRoundUp: v)),
          ),
          OverridableDropdownField<int>(
            label: context.tr('task_round_to_nearest'),
            apiKey: 'task_round_to_nearest',
            // Show the actual stored preset, or the Custom sentinel when the
            // value is non-preset / sticky-custom.
            value: isCustomValue || _userPickedCustom
                ? 0
                : (asInt ?? 900),
            items: [
              DropdownMenuItem(value: 60, child: Text(context.tr('1_minute'))),
              DropdownMenuItem(value: 300, child: Text(context.tr('5_minutes'))),
              DropdownMenuItem(value: 900, child: Text(context.tr('15_minutes'))),
              DropdownMenuItem(value: 1800, child: Text(context.tr('30_minutes'))),
              DropdownMenuItem(value: 3600, child: Text(context.tr('1_hour'))),
              DropdownMenuItem(value: 86400, child: Text(context.tr('1_day'))),
              DropdownMenuItem(value: 0, child: Text(context.tr('custom'))),
            ],
            onChanged: (v) {
              if (v == null) return;
              if (v == 0) {
                setState(() => _userPickedCustom = true);
                return;
              }
              setState(() => _userPickedCustom = false);
              host.updateSettings(
                (s) => s.copyWith(taskRoundToNearest: v.toDouble()),
              );
            },
          ),
          if (showCustomSeconds)
            OverridableNumberField(
              label: context.tr('round_to_seconds'),
              apiKey: 'task_round_to_nearest',
              integerOnly: true,
            ),
        ],
        if (widget.isCompanyScope) ...[
          const Divider(height: 1),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/settings/task_statuses'),
              icon: const Icon(Icons.label_outlined, size: 18),
              label: Text(context.tr('configure_statuses')),
            ),
          ),
        ],
      ],
    );
  }
}

const Set<int> _kPresetSeconds = {60, 300, 900, 1800, 3600, 86400};

/// Top-level `company.*` switch with a help-text subtitle and optional
/// disabled-with-tooltip state. Eliminates 11 copies of the same
/// `SwitchListTile` boilerplate; mirrors the shape used by
/// `product_settings_screen.dart`. Callers pass resolved strings (not
/// localization keys) so the static `search_catalog_consistency_test`
/// regex finds each `context.tr('...')` reference at the call site.
class _TaskSwitch extends StatelessWidget {
  const _TaskSwitch({
    required this.label,
    required this.help,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.disabledTooltip,
  });

  final String label;
  final String help;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final tile = SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(help),
      value: enabled ? value : false,
      onChanged: enabled ? onChanged : null,
    );
    if (enabled || disabledTooltip == null) return tile;
    return Tooltip(
      message: disabledTooltip!,
      child: tile,
    );
  }
}

/// Project Location dropdown — `invoice_task_project_header`:
/// false = service, true = description. Disabled-with-tooltip when the
/// parent `invoice_task_project` is off.
class _ProjectLocationDropdown extends StatelessWidget {
  const _ProjectLocationDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final field = DropdownButtonFormField<bool>(
      key: ValueKey('project-location-$value-$enabled'),
      initialValue: enabled ? value : null,
      decoration: InputDecoration(
        labelText: context.tr('project_location'),
        enabled: enabled,
      ),
      items: [
        DropdownMenuItem(
          value: false,
          child: Text(context.tr('service')),
        ),
        DropdownMenuItem(
          value: true,
          child: Text(context.tr('description')),
        ),
      ],
      onChanged: enabled ? (v) => v == null ? null : onChanged(v) : null,
    );
    if (enabled) return field;
    return Tooltip(
      message: context.tr('invoice_task_project'),
      child: field,
    );
  }
}

/// Tasks-shown-in-portal dropdown. Disabled-with-tooltip when the parent
/// `enable_client_portal_tasks` cascade field is set to false.
class _PortalTasksDropdown extends StatelessWidget {
  const _PortalTasksDropdown({required this.value, required this.enabled});

  final String value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dropdown = OverridableDropdownField<String>(
      label: context.tr('tasks_shown_in_portal'),
      apiKey: 'show_all_tasks_client_portal',
      value: value,
      items: [
        DropdownMenuItem(value: 'invoiced', child: Text(context.tr('invoiced'))),
        DropdownMenuItem(
          value: 'uninvoiced',
          child: Text(context.tr('uninvoiced')),
        ),
        DropdownMenuItem(value: 'all', child: Text(context.tr('all'))),
      ],
      onChanged: enabled
          ? (v) {
              if (v == null) return;
              final host = Provider.of<SettingsDraftHost>(
                context,
                listen: false,
              );
              host.updateSettings(
                (s) => s.copyWith(showAllTasksClientPortal: v),
              );
            }
          : (_) {},
    );
    if (enabled) return dropdown;
    return Tooltip(
      message: context.tr('show_tasks_in_client_portal'),
      child: AbsorbPointer(child: Opacity(opacity: 0.5, child: dropdown)),
    );
  }
}
