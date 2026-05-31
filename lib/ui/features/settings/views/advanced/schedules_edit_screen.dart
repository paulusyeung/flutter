import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/data/models/domain/report_schedule_seed.dart';
import 'package:admin/data/models/domain/schedule.dart';
import 'package:admin/data/models/domain/schedule_constants.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/view_models/schedule_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_edit_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';
import 'package:admin/utils/formatting.dart';

/// `/settings/schedules/new` and `/settings/schedules/:id`.
///
/// Edit-or-create form for a single Schedule. The form is template-driven:
/// on create the user picks a template card; the body then reveals a
/// "Common" section (next_run / frequency / cycles / pause) plus a
/// per-template parameter section.
class SchedulesEditScreen extends StatelessWidget {
  const SchedulesEditScreen({
    this.existingId,
    this.starter,
    this.seed,
    super.key,
  });

  final String? existingId;

  /// `?starter=...` from the empty-state starter cards. Pre-fills the
  /// template + parameters when set on a fresh create.
  final String? starter;

  /// Passed via `context.go(..., extra:)` from the reports screen's
  /// "Schedule" launcher — pre-fills a fresh create as an `email_report`
  /// schedule with the current report's filters/columns. Same typed-`extra`
  /// prefill precedent as `PaymentLinkEditScreen.cloneFrom`.
  final ReportScheduleSeed? seed;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.schedules;

    return SettingsEntityEditScaffold<Schedule, ScheduleEditViewModel>(
      existingId: existingId,
      backRoute: '/settings/schedules',
      createTitleKey: 'new_schedule',
      editTitleKey: 'edit_schedule',
      wireName: 'schedule',
      watchById: (id) => repo.watch(companyId: companyId, id: id),
      refreshAll: () => repo.refreshAll(companyId: companyId),
      onArchive: (id) => repo.archive(companyId: companyId, id: id),
      onRestore: (id) => repo.restore(companyId: companyId, id: id),
      onDelete: (id) => repo.delete(companyId: companyId, id: id),
      vmFactory: ({existing}) {
        final vm = ScheduleEditViewModel(
          repo: repo,
          companyId: companyId,
          existing: existing,
          sync: services.sync,
          connectivity: services.connectivity,
        );
        // Prefill on fresh creates. A report seed (from the reports
        // "Schedule" launcher) wins over a starter card; they never
        // co-occur in practice. `updateDraft` mirrors how `_applyStarter`
        // mutates the VM post-construction.
        if (existing == null) {
          if (seed != null) {
            vm.applyReportSeed(seed!);
          } else if (starter != null) {
            _applyStarter(vm, starter!);
          }
        }
        return vm;
      },
      isArchivedOf: (s) => s.archivedAt != null,
      isDeletedOf: (s) => s.isDeleted,
      canSave: (vm) => vm.canSave,
      bodyBuilder: (context, vm) {
        // Card-picker landing step on a fresh create — only shown when no
        // template is selected yet.
        if (vm.isCreate && vm.draft.template.isEmpty) {
          return [_TemplatePickerLanding(vm: vm)];
        }
        return [
          _CommonFieldsSection(vm: vm),
          _TemplateParametersSection(vm: vm),
        ];
      },
    );
  }
}

void _applyStarter(ScheduleEditViewModel vm, String starter) {
  switch (starter) {
    case 'monthly_statement':
      vm.setTemplate(kScheduleTemplateEmailStatement);
      vm.setFrequencyId('5'); // monthly
      vm.setStatementStatus(kStatementStatusAll);
      vm.setShowAgingTable(true);
      break;
    case 'quarterly_pnl':
      vm.setTemplate(kScheduleTemplateEmailReport);
      vm.setFrequencyId('7'); // three months
      vm.setReportName('profitloss');
      vm.setReportSendEmail(true);
      break;
    case 'weekly_reminders':
      vm.setTemplate(kScheduleTemplateInvoiceOutstandingTasks);
      vm.setFrequencyId('2'); // weekly
      vm.setOutstandingTasksAutoSend(true);
      break;
  }
}

// ============== Card-picker landing step ===============

class _TemplatePickerLanding extends StatelessWidget {
  const _TemplatePickerLanding({required this.vm});

  final ScheduleEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('pick_a_template'),
      children: [
        Text(
          context.tr('pick_a_template_hint'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final cols = wide ? 2 : 1;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final t in kScheduleTemplates)
                  SizedBox(
                    width: (constraints.maxWidth - 12 * (cols - 1)) / cols,
                    child: _TemplateCard(
                      templateKey: t,
                      onTap: () => vm.setTemplate(t),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.templateKey, required this.onTap});

  final String templateKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(InRadii.r3),
      child: InkWell(
        borderRadius: BorderRadius.circular(InRadii.r3),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(templateKey), color: theme.colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                context.tr(templateKey),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('${templateKey}_hint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String t) {
    switch (t) {
      case kScheduleTemplateEmailStatement:
        return Icons.receipt_long_outlined;
      case kScheduleTemplateEmailRecord:
        return Icons.mail_outline;
      case kScheduleTemplateEmailReport:
        return Icons.assessment_outlined;
      case kScheduleTemplateInvoiceOutstandingTasks:
        return Icons.timer_outlined;
      case kScheduleTemplatePaymentSchedule:
        return Icons.payments_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }
}

// ============== Common fields (every template) ===============

class _CommonFieldsSection extends StatelessWidget {
  const _CommonFieldsSection({required this.vm});

  final ScheduleEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('details'),
      children: [
        SettingsTextField(
          initialValue: vm.draft.name,
          labelKey: 'name',
          onChanged: vm.setName,
          errorText: vm.fieldErrorFor('name'),
          externalSyncKey: vm.original?.id,
        ),
        _TemplateDisplayField(vm: vm),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('pause_schedule')),
          subtitle: Text(
            context.tr('pause_schedule_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: vm.draft.isPaused,
          onChanged: vm.setIsPaused,
        ),
        if (vm.draft.supportsNextRun)
          InDateField(
            value: vm.draft.nextRun?.toDateTime(),
            labelText: context.tr('next_run'),
            onChanged: (dt) {
              vm.setNextRun(
                dt == null ? null : Date(dt.year, dt.month, dt.day),
              );
            },
          ),
        if (vm.draft.supportsFrequency) ...[
          DropdownButtonFormField<String>(
            initialValue: vm.draft.frequencyId.isEmpty
                ? null
                : vm.draft.frequencyId,
            decoration: InputDecoration(labelText: context.tr('frequency')),
            items: [
              for (final entry in kScheduleFrequencies.entries)
                DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(context.tr(entry.value)),
                ),
            ],
            onChanged: (v) => vm.setFrequencyId(v ?? ''),
          ),
          DropdownButtonFormField<int>(
            initialValue: vm.draft.remainingCycles,
            decoration: InputDecoration(
              labelText: context.tr('remaining_cycles'),
            ),
            items: [
              DropdownMenuItem<int>(
                value: kScheduleRemainingCyclesEndless,
                child: Text(context.tr('endless')),
              ),
              for (var i = 0; i <= kScheduleRemainingCyclesMax; i++)
                DropdownMenuItem<int>(value: i, child: Text(i.toString())),
            ],
            onChanged: (v) =>
                vm.setRemainingCycles(v ?? kScheduleRemainingCyclesEndless),
          ),
        ],
      ],
    );
  }
}

/// Read-only chip showing the chosen template. Disabled because changing
/// it post-create would orphan all the parameter fields the user just
/// filled in.
class _TemplateDisplayField extends StatelessWidget {
  const _TemplateDisplayField({required this.vm});

  final ScheduleEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.isCreate) {
      // Show the template name as a read-only label; switching back to
      // the picker is a one-button affordance.
      return InputDecorator(
        decoration: InputDecoration(labelText: context.tr('template')),
        child: Row(
          children: [
            Expanded(child: Text(context.tr(vm.draft.template))),
            TextButton(
              onPressed: () => _onChange(context),
              child: Text(context.tr('change')),
            ),
          ],
        ),
      );
    }
    // On edit: template is locked. Matches React (Edit.tsx disables it).
    return InputDecorator(
      decoration: InputDecoration(labelText: context.tr('template')),
      child: Text(context.tr(vm.draft.template)),
    );
  }

  Future<void> _onChange(BuildContext context) async {
    // Compare current parameters against the freshly-seeded defaults for
    // the same template. If they match, the user hasn't typed anything
    // template-specific — just swap. Otherwise prompt before discarding.
    final fresh = Schedule.empty().withTemplate(vm.draft.template).parameters;
    final current = vm.draft.parameters;
    final pristine =
        jsonEncode(_sortedMap(current)) == jsonEncode(_sortedMap(fresh));
    if (pristine) {
      vm.setTemplate('');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('discard_changes_question')),
        content: Text(dialogContext.tr('discard_changes_warning')),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('keep_editing')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('discard')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      vm.setTemplate('');
    }
  }

  /// Stable-ordered map for `jsonEncode`-based deep equality.
  Map<String, dynamic> _sortedMap(Map<String, dynamic> input) {
    final keys = input.keys.toList()..sort();
    return {for (final k in keys) k: input[k]};
  }
}

// ============== Per-template parameter section ===============

class _TemplateParametersSection extends StatelessWidget {
  const _TemplateParametersSection({required this.vm});

  final ScheduleEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    switch (vm.draft.template) {
      case kScheduleTemplateEmailStatement:
        return _EmailStatementSection(vm: vm);
      case kScheduleTemplateEmailRecord:
        return _EmailRecordSection(vm: vm);
      case kScheduleTemplateEmailReport:
        return _EmailReportSection(vm: vm);
      case kScheduleTemplateInvoiceOutstandingTasks:
        return _InvoiceOutstandingTasksSection(vm: vm);
      case kScheduleTemplatePaymentSchedule:
        return _PaymentScheduleSection(vm: vm);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ============== email_statement ===============

class _EmailStatementSection extends StatelessWidget {
  const _EmailStatementSection({required this.vm});

  final ScheduleEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('email_statement'),
      children: [
        _dateRangeDropdown(
          context,
          value: vm.draft.statementDateRange,
          onChanged: vm.setStatementDateRange,
        ),
        DropdownButtonFormField<String>(
          initialValue: vm.draft.statementStatus,
          decoration: InputDecoration(labelText: context.tr('status')),
          items: [
            for (final s in kStatementStatuses)
              DropdownMenuItem<String>(value: s, child: Text(context.tr(s))),
          ],
          onChanged: (v) => vm.setStatementStatus(v ?? kStatementStatusAll),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('show_aging_table')),
          value: vm.draft.statementShowAgingTable,
          onChanged: vm.setShowAgingTable,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('show_payments_table')),
          value: vm.draft.statementShowPaymentsTable,
          onChanged: vm.setShowPaymentsTable,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('show_credits_table')),
          value: vm.draft.statementShowCreditsTable,
          onChanged: vm.setShowCreditsTable,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('only_clients_with_invoices')),
          value: vm.draft.statementOnlyClientsWithInvoices,
          onChanged: vm.setOnlyClientsWithInvoices,
        ),
        _ClientCsvField(
          labelKey: 'clients',
          hintKey: 'all_clients',
          ids: vm.draft.statementClients,
          onChanged: vm.setStatementClients,
        ),
      ],
    );
  }
}

// ============== email_record ===============

class _EmailRecordSection extends StatelessWidget {
  const _EmailRecordSection({required this.vm});

  final ScheduleEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final templates =
        kEmailRecordTemplatesPerEntity[vm.draft.recordEntityType] ??
        const <String>[];
    final modules =
        context
            .read<Services>()
            .auth
            .session
            .value
            ?.currentCompany
            ?.enabledModules ??
        0;
    return FormSection(
      title: context.tr('email_record'),
      children: [
        DropdownButtonFormField<String>(
          initialValue: vm.draft.recordEntityType,
          decoration: InputDecoration(labelText: context.tr('type')),
          items: [
            // Keep the currently-selected type even if its module is off so
            // editing an existing schedule that targets it isn't broken.
            for (final t in kEmailRecordEntityTypes)
              if (t == vm.draft.recordEntityType ||
                  isWireModuleEnabledForCompany(t, modules))
                DropdownMenuItem<String>(value: t, child: Text(context.tr(t))),
          ],
          onChanged: (v) {
            if (v != null) vm.setRecordEntityType(v);
          },
        ),
        SettingsTextField(
          initialValue: vm.draft.recordEntityId,
          labelKey: '${vm.draft.recordEntityType}_id',
          onChanged: vm.setRecordEntityId,
          errorText: vm.fieldErrorFor('entity_id'),
          externalSyncKey: vm.draft.recordEntityType,
        ),
        DropdownButtonFormField<String>(
          initialValue: templates.contains(vm.draft.recordEmailTemplate)
              ? vm.draft.recordEmailTemplate
              : (templates.isNotEmpty ? templates.first : null),
          decoration: InputDecoration(labelText: context.tr('template')),
          items: [
            for (final t in templates)
              DropdownMenuItem<String>(value: t, child: Text(context.tr(t))),
          ],
          onChanged: (v) {
            if (v != null) vm.setRecordEmailTemplate(v);
          },
        ),
      ],
    );
  }
}

// ============== email_report ===============

class _EmailReportSection extends StatefulWidget {
  const _EmailReportSection({required this.vm});

  final ScheduleEditViewModel vm;

  @override
  State<_EmailReportSection> createState() => _EmailReportSectionState();
}

class _EmailReportSectionState extends State<_EmailReportSection> {
  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final reportName = vm.draft.reportName;
    final fields =
        kEmailReportFieldsByReport[reportName] ?? const <EmailReportField>{};

    return FormSection(
      title: context.tr('email_report'),
      children: [
        SearchableDropdownField<_ReportOption>(
          label: context.tr('report'),
          items: _reportOptions(context),
          initialValue: _reportOptions(context).firstWhere(
            (o) => o.id == reportName,
            orElse: () => _reportOptions(context).first,
          ),
          displayString: (o) => o.display,
          idOf: (o) => o.id,
          onChanged: (o) {
            if (o != null) vm.setReportName(o.id);
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in fields) ...[
                const SizedBox(height: 12),
                _buildReportField(context, vm, f),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportField(
    BuildContext context,
    ScheduleEditViewModel vm,
    EmailReportField field,
  ) {
    switch (field) {
      case EmailReportField.sendEmail:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('send_email')),
          value: vm.draft.reportSendEmail,
          onChanged: vm.setReportSendEmail,
        );
      case EmailReportField.dateRange:
        return _dateRangeDropdown(
          context,
          value: vm.draft.reportDateRange,
          onChanged: vm.setReportDateRange,
        );
      case EmailReportField.startDate:
        if (vm.draft.reportDateRange != 'custom') {
          return const SizedBox.shrink();
        }
        return SettingsTextField(
          initialValue: vm.draft.reportStartDate,
          labelKey: 'start_date',
          onChanged: vm.setReportStartDate,
          externalSyncKey: vm.draft.reportName,
        );
      case EmailReportField.endDate:
        if (vm.draft.reportDateRange != 'custom') {
          return const SizedBox.shrink();
        }
        return SettingsTextField(
          initialValue: vm.draft.reportEndDate,
          labelKey: 'end_date',
          onChanged: vm.setReportEndDate,
          externalSyncKey: vm.draft.reportName,
        );
      case EmailReportField.status:
        return SettingsTextField(
          initialValue: vm.draft.reportStatus,
          labelKey: 'status',
          onChanged: vm.setReportStatus,
          externalSyncKey: vm.draft.reportName,
        );
      case EmailReportField.documentEmailAttachment:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('document_email_attachment')),
          value: vm.draft.reportDocumentEmailAttachment,
          onChanged: vm.setReportDocumentEmailAttachment,
        );
      case EmailReportField.pdfEmailAttachment:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('attach_pdf')),
          value: vm.draft.reportPdfEmailAttachment,
          onChanged: vm.setReportPdfEmailAttachment,
        );
      case EmailReportField.isExpenseBilled:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('expense_paid_report')),
          value: vm.draft.reportIsExpenseBilled,
          onChanged: vm.setReportIsExpenseBilled,
        );
      case EmailReportField.isIncomeBilled:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('cash_vs_accrual')),
          value: vm.draft.reportIsIncomeBilled,
          onChanged: vm.setReportIsIncomeBilled,
        );
      case EmailReportField.includeTax:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('include_tax')),
          value: vm.draft.reportIncludeTax,
          onChanged: vm.setReportIncludeTax,
        );
      case EmailReportField.includeDeleted:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('include_deleted')),
          value: vm.draft.reportIncludeDeleted,
          onChanged: vm.setReportIncludeDeleted,
        );
      case EmailReportField.productKey:
        return SettingsTextField(
          initialValue: vm.draft.reportProductKey,
          labelKey: 'product_key',
          onChanged: vm.setReportProductKey,
          externalSyncKey: vm.draft.reportName,
        );
      case EmailReportField.clientIdSingular:
        return SettingsTextField(
          initialValue: vm.draft.reportClientId,
          labelKey: 'client_id',
          onChanged: vm.setReportClientId,
          externalSyncKey: vm.draft.reportName,
        );
      case EmailReportField.clients:
        return _ClientCsvField(
          labelKey: 'clients',
          hintKey: 'all_clients',
          ids: vm.draft.reportClients,
          onChanged: vm.setReportClients,
        );
      case EmailReportField.vendors:
        return _ClientCsvField(
          labelKey: 'vendors',
          hintKey: 'all',
          ids: vm.draft.reportVendors,
          onChanged: vm.setReportVendorsCsv,
        );
      case EmailReportField.projects:
        return _ClientCsvField(
          labelKey: 'projects',
          hintKey: 'all',
          ids: vm.draft.reportProjects,
          onChanged: vm.setReportProjectsCsv,
        );
      case EmailReportField.categories:
        return _ClientCsvField(
          labelKey: 'categories',
          hintKey: 'all',
          ids: vm.draft.reportCategories,
          onChanged: vm.setReportCategoriesCsv,
        );
      case EmailReportField.templateId:
        return SettingsTextField(
          initialValue: vm.draft.reportTemplateId,
          labelKey: 'design',
          onChanged: vm.setReportTemplateId,
          externalSyncKey: vm.draft.reportName,
        );
      case EmailReportField.groupBy:
        return SettingsTextField(
          initialValue: vm.draft.reportGroupBy,
          labelKey: 'group_by',
          onChanged: vm.setReportGroupBy,
          externalSyncKey: vm.draft.reportName,
        );
      case EmailReportField.reportKeys:
        // No UI in either legacy client; round-tripped through the
        // payload only.
        return const SizedBox.shrink();
    }
  }

  List<_ReportOption> _reportOptions(BuildContext context) {
    return [
      for (final r in kEmailReportReportNames)
        _ReportOption(
          id: r,
          display: '${context.tr(emailReportCategoryOf(r))} · ${context.tr(r)}',
        ),
    ];
  }
}

class _ReportOption {
  const _ReportOption({required this.id, required this.display});

  final String id;
  final String display;
}

// ============== invoice_outstanding_tasks ===============

class _InvoiceOutstandingTasksSection extends StatelessWidget {
  const _InvoiceOutstandingTasksSection({required this.vm});

  final ScheduleEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('invoice_outstanding_tasks'),
      children: [
        _dateRangeDropdown(
          context,
          value: vm.draft.outstandingTasksDateRange,
          onChanged: (v) => vm._patchOutstandingDateRange(v),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('auto_send')),
          subtitle: Text(
            context.tr('auto_send_help'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: vm.draft.outstandingTasksAutoSend,
          onChanged: vm.setOutstandingTasksAutoSend,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('include_project_tasks')),
          subtitle: Text(
            context.tr('include_project_tasks_help'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: vm.draft.outstandingTasksIncludeProjectTasks,
          onChanged: vm.setOutstandingTasksIncludeProjectTasks,
        ),
        _ClientCsvField(
          labelKey: 'clients',
          hintKey: 'all_clients',
          ids: vm.draft.outstandingTasksClients,
          onChanged: (ids) => vm._patchOutstandingClients(ids),
        ),
      ],
    );
  }
}

extension on ScheduleEditViewModel {
  // The outstanding-tasks template reuses the statement setters because
  // both write the same parameter keys (`date_range`, `clients`).
  void _patchOutstandingDateRange(String v) => setStatementDateRange(v);
  void _patchOutstandingClients(List<String> ids) => setStatementClients(ids);
}

// ============== payment_schedule ===============

class _PaymentScheduleSection extends StatefulWidget {
  const _PaymentScheduleSection({required this.vm});

  final ScheduleEditViewModel vm;

  @override
  State<_PaymentScheduleSection> createState() =>
      _PaymentScheduleSectionState();
}

class _PaymentScheduleSectionState extends State<_PaymentScheduleSection> {
  /// Mode preference for the next-added row when no rows exist yet. Once
  /// a row is in place, the displayed mode is read from `rows.first` and
  /// this field is unused — the toggle is locked until the user clears
  /// the rows back out.
  bool _pendingMode = true;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final rows = vm.draft.paymentScheduleRows;
    final isAmountMode = rows.isEmpty ? _pendingMode : rows.first.isAmount;
    final today = Date.today();

    return FormSection(
      title: context.tr('payment_schedule'),
      children: [
        // Lock invoice id on edit — matches React PaymentSchedule.tsx:389.
        // Render as a read-only decorator so the field is also out of the
        // focus tree (a previous IgnorePointer+Opacity wrap left it
        // keyboard-focusable). On create, the standard editable field.
        if (vm.isCreate)
          SettingsTextField(
            initialValue: vm.draft.paymentScheduleInvoiceId,
            labelKey: 'invoice_id',
            onChanged: vm.setPaymentScheduleInvoiceId,
            errorText: vm.fieldErrorFor('invoice_id'),
            externalSyncKey: vm.original?.id,
          )
        else
          InputDecorator(
            decoration: InputDecoration(
              labelText: context.tr('invoice_id'),
              enabled: false,
            ),
            child: Text(
              vm.draft.paymentScheduleInvoiceId,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('auto_bill')),
          subtitle: Text(
            context.tr('auto_bill_help'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: vm.draft.paymentScheduleAutoBill,
          onChanged: vm.setPaymentScheduleAutoBill,
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('amount_mode')),
          subtitle: Text(
            isAmountMode ? context.tr('amount') : context.tr('percent'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: isAmountMode,
          // Mode applies to row 0; subsequent rows inherit. Lock the
          // toggle once any row exists — flipping mode after rows are
          // populated would re-interpret each row's numeric amount
          // (e.g. "200.00 USD" becomes "200%" — way over 100%). Mirrors
          // React's AddScheduleModal.tsx:260 (mode toggle only on row 0).
          // To change mode, the user clears the rows back out and the
          // toggle re-enables.
          onChanged: rows.isEmpty
              ? (v) => setState(() => _pendingMode = v)
              : null,
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Text(
            context.tr('no_payment_schedule_rows_hint'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++)
                _PaymentScheduleRowTile(
                  key: ValueKey(rows[i].id),
                  index: i,
                  row: rows[i],
                  isAmountMode: isAmountMode,
                  isPast: rows[i].date.compareTo(today) < 0,
                  onChanged: (updated) {
                    final next = List<ScheduleParamsRow>.from(rows);
                    next[i] = updated;
                    vm.setPaymentScheduleRows(next);
                  },
                  onRemove: () {
                    final next = List<ScheduleParamsRow>.from(rows)
                      ..removeAt(i);
                    vm.setPaymentScheduleRows(next);
                  },
                ),
            ],
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          icon: const Icon(Icons.add),
          label: Text(context.tr('add_row')),
          onPressed: () {
            final nextId = (rows.isEmpty ? 0 : rows.last.id) + 1;
            // Default new-row date: row 0 today, otherwise one day after
            // the last row's date so the strict-ordering rule is satisfied
            // out of the box.
            final base = rows.isEmpty ? today : _addDays(rows.last.date, 1);
            final next = List<ScheduleParamsRow>.from(rows)
              ..add(
                ScheduleParamsRow(
                  id: nextId,
                  date: base,
                  amount: Decimal.zero,
                  isAmount: isAmountMode,
                ),
              );
            vm.setPaymentScheduleRows(next);
          },
        ),
      ],
    );
  }
}

Date _addDays(Date d, int days) {
  final dt = DateTime(d.year, d.month, d.day).add(Duration(days: days));
  return Date(dt.year, dt.month, dt.day);
}

class _PaymentScheduleRowTile extends StatefulWidget {
  const _PaymentScheduleRowTile({
    required this.index,
    required this.row,
    required this.isAmountMode,
    required this.isPast,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final ScheduleParamsRow row;
  final bool isAmountMode;
  final bool isPast;
  final ValueChanged<ScheduleParamsRow> onChanged;
  final VoidCallback onRemove;

  @override
  State<_PaymentScheduleRowTile> createState() =>
      _PaymentScheduleRowTileState();
}

class _PaymentScheduleRowTileState extends State<_PaymentScheduleRowTile> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: _displayAmount(widget.row));
  }

  @override
  void didUpdateWidget(covariant _PaymentScheduleRowTile old) {
    super.didUpdateWidget(old);
    // Re-seed when the row's amount or mode changes externally (e.g. the
    // section clears amounts on mode flip in a future fix). Skip when the
    // text already matches what the user is typing.
    final next = _displayAmount(widget.row);
    if (next != _amountController.text &&
        (widget.row.amount != old.row.amount ||
            widget.row.isAmount != old.row.isAmount)) {
      _amountController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  static String _displayAmount(ScheduleParamsRow row) =>
      row.amount == Decimal.zero ? '' : row.amount.toString();

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final isPast = widget.isPast;
    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: InDateField(
                value: row.date.toDateTime(),
                labelText: context.tr('date'),
                enabled: !isPast,
                onChanged: (d) {
                  if (d == null) return;
                  widget.onChanged(
                    row.copyWith(date: Date(d.year, d.month, d.day)),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: widget.isAmountMode
                      ? context.tr('amount')
                      : context.tr('percent'),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                ],
                enabled: !isPast,
                onChanged: (v) {
                  final services = context.read<Services>();
                  final companyId =
                      services.auth.session.value?.currentCompanyId ?? '';
                  final useComma = services
                          .formatterIfReady(companyId)
                          ?.settings
                          .useCommaAsDecimalPlace ??
                      false;
                  final parsed = parseDecimal(
                        v,
                        useCommaAsDecimalPlace: useComma,
                      ) ??
                      Decimal.zero;
                  widget.onChanged(row.copyWith(amount: parsed));
                },
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: isPast ? null : widget.onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: context.tr('remove'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============== shared helpers ===============

Widget _dateRangeDropdown(
  BuildContext context, {
  required String value,
  required ValueChanged<String> onChanged,
}) {
  return DropdownButtonFormField<String>(
    initialValue: kScheduleDateRangeOptions.contains(value) ? value : null,
    decoration: InputDecoration(labelText: context.tr('date_range')),
    items: [
      for (final o in kScheduleDateRangeOptions)
        DropdownMenuItem<String>(value: o, child: Text(context.tr(o))),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

/// Comma-separated id input. A scaffolding placeholder until proper
/// entity-pickers land — the user can paste a list of ids (or leave
/// empty for "all"). Empty list emits the wire's "no filter" signal.
class _ClientCsvField extends StatefulWidget {
  const _ClientCsvField({
    required this.labelKey,
    required this.hintKey,
    required this.ids,
    required this.onChanged,
  });

  final String labelKey;
  final String hintKey;
  final List<String> ids;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_ClientCsvField> createState() => _ClientCsvFieldState();
}

class _ClientCsvFieldState extends State<_ClientCsvField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.ids.join(', '));
  }

  @override
  void didUpdateWidget(covariant _ClientCsvField old) {
    super.didUpdateWidget(old);
    // External list change (e.g. starter prefill) — reseed the controller
    // without disturbing the cursor while the user is mid-edit.
    final joined = widget.ids.join(', ');
    if (joined != _controller.text.replaceAll(' ', '').replaceAll(',', ', ') &&
        joined != _controller.text) {
      _controller.text = joined;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.tr(widget.labelKey),
        hintText: context.tr(widget.hintKey),
        helperText: context.tr('comma_separated_ids'),
      ),
      onChanged: (raw) {
        final ids = raw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(growable: false);
        widget.onChanged(ids);
      },
    );
  }
}
