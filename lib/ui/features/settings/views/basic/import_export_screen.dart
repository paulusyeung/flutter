import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/services/upload_source.dart';
import 'package:admin/data/models/domain/bank_account.dart';
import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/data/models/domain/import_preview.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/import_api.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/file_drop_zone.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Search keys for the settings search catalog.
const kImportExportSearchKeys = <String>[
  'import',
  'csv',
  'import_type',
  'company_migration',
];

enum _Step { pick, map, done }

/// `/settings/import_export` — CSV data import. Three-stage flow mirroring
/// React/admin-portal: pick entity + file → `/api/v1/preimport` → map each
/// CSV column to an entity field → `/api/v1/import`. The server runs the
/// import asynchronously and emails the user on completion.
class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  /// Export report types — mirrors React's `Export.tsx` `ExportType` union
  /// (`POST /api/v1/reports/<type>`). Every entry has a localized label in
  /// `en.json` already.
  static const List<String> _exportTypes = [
    'clients',
    'client_contacts',
    'invoices',
    'invoice_items',
    'quotes',
    'quote_items',
    'credits',
    'recurring_invoices',
    'payments',
    'expenses',
    'products',
    'vendors',
    'purchase_orders',
    'purchase_order_items',
    'tasks',
    'documents',
    'activities',
  ];

  _Step _step = _Step.pick;
  String _entity = kImportableEntities.first;
  String _exportType = 'clients';
  bool _exporting = false;
  String? _fileName;
  List<int>? _bytes;
  bool _busy = false;
  bool _skipHeader = true;
  // Required only when [_entity] == 'bank_transaction' — the server needs a
  // target bank integration to attach imported transactions to.
  String? _bankIntegrationId;

  ImportPreview? _preview;
  // Column index → selected field path ('' = skip).
  final Map<int, String> _map = {};

  // Company-migration (import_json) state — independent of the CSV flow.
  UploadSource? _migrationSource;
  String? _migrationFileName;
  bool _migrationImportSettings = true;
  bool _migrationBusy = false;

  ImportApi get _api => ImportApi(context.read<Services>().apiClient);

  /// Active company's module bitmask — gates which entity types appear in the
  /// import / export pickers.
  int _enabledModules(BuildContext context) =>
      context
          .read<Services>()
          .auth
          .session
          .value
          ?.currentCompany
          ?.enabledModules ??
      0;

  Future<void> _onCsvFiles(List<UploadSource> sources) async {
    if (sources.isEmpty) return;
    final source = sources.first;
    final bytes = await source.readRange(0, await source.length());
    if (!mounted) return;
    setState(() {
      _fileName = source.fileName;
      _bytes = bytes;
    });
  }

  Future<void> _runPreImport() async {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() => _busy = true);
    try {
      final preview = await _api.preImport(
        entity: _entity,
        fileName: _fileName ?? 'import.csv',
        bytes: Uint8List.fromList(bytes),
      );
      if (!mounted) return;
      _map.clear();
      // Seed from server hints (index into `available`, -1 = no guess).
      for (var i = 0; i < preview.columns.length; i++) {
        final hint = i < preview.hints.length ? preview.hints[i] : -1;
        if (hint >= 0 && hint < preview.available.length) {
          _map[i] = preview.available[hint];
        } else {
          _map[i] = '';
        }
      }
      setState(() {
        _preview = preview;
        _step = _Step.map;
      });
    } on Object catch (e) {
      if (mounted) Notify.error(context, _msg(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runImport() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() => _busy = true);
    try {
      await _api.runImport(
        hash: preview.hash,
        entity: _entity,
        skipHeader: _skipHeader,
        columnMap: _map,
        bankIntegrationId: _bankIntegrationId,
      );
      if (!mounted) return;
      setState(() => _step = _Step.done);
    } on Object catch (e) {
      if (mounted) Notify.error(context, _msg(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    setState(() {
      _step = _Step.pick;
      _fileName = null;
      _bytes = null;
      _preview = null;
      _map.clear();
      _skipHeader = true;
      _bankIntegrationId = null;
    });
  }

  String _msg(BuildContext context, Object e) {
    if (e is ValidationException) {
      final flat = e.fieldErrors.values
          .expand((v) => v)
          .where((s) => s.isNotEmpty)
          .join('\n');
      return flat.isNotEmpty ? flat : e.message;
    }
    if (e is DemoModeException) return context.tr('not_available');
    if (e is ApiException) return e.message;
    return context.tr('an_error_occurred');
  }

  /// `POST /api/v1/reports/<type>` — queues a CSV export of the selected
  /// entity type and emails the user a download link. Mirrors React's
  /// `Export.tsx` (`send_email: true`, no `report_keys` filter = all rows,
  /// no date filter = all-time). Same email-link contract as Backup.
  Future<void> _runExport() async {
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final tr = context.tr;
    setState(() => _exporting = true);
    try {
      await services.apiClient.postJson(
        '/api/v1/reports/$_exportType',
        body: const {'send_email': true, 'report_keys': <String>[]},
      );
      if (!mounted) return;
      Notify.success(context, tr('exported_data'), messenger: messenger);
    } on Object catch (e) {
      if (mounted) {
        Notify.error(context, _msg(context, e), messenger: messenger);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _onMigrationFiles(List<UploadSource> sources) async {
    if (sources.isEmpty) return;
    final source = sources.first;
    setState(() {
      _migrationSource = source;
      _migrationFileName = source.fileName;
    });
  }

  Future<void> _runMigration() async {
    final source = _migrationSource;
    if (source == null) return;
    setState(() => _migrationBusy = true);
    try {
      await _api.runMigration(
        source: source,
        importSettings: _migrationImportSettings,
      );
      if (!mounted) return;
      Notify.success(context, context.tr('import_started'));
      setState(() {
        _migrationSource = null;
        _migrationFileName = null;
      });
    } on Object catch (e) {
      if (mounted) Notify.error(context, _msg(context, e));
    } finally {
      if (mounted) setState(() => _migrationBusy = false);
    }
  }

  Widget _migrationSection(BuildContext context) {
    return FormSection(
      title: context.tr('company_migration'),
      children: [
        Text(
          context.tr('migration_import_help'),
          style: TextStyle(fontSize: 13, color: context.inTheme.ink3),
        ),
        SizedBox(height: InSpacing.md(context)),
        FileDropZone(
          allowedExtensions: const ['zip', 'json'],
          enabled: !_migrationBusy,
          onFiles: _onMigrationFiles,
        ),
        if (_migrationFileName != null) ...[
          const SizedBox(height: InSpacing.sm),
          Text(
            _migrationFileName!,
            style: TextStyle(fontSize: 13, color: context.inTheme.ink2),
          ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _migrationImportSettings,
          onChanged: _migrationBusy
              ? null
              : (v) => setState(() => _migrationImportSettings = v),
          title: Text(context.tr('import_settings')),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: (_migrationSource == null || _migrationBusy)
                ? null
                : _runMigration,
            child: _migrationBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('import')),
          ),
        ),
      ],
    );
  }

  Widget _exportSection(BuildContext context) {
    return FormSection(
      title: context.tr('export'),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _exportType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('export'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _exporting
              ? null
              : (v) => setState(() => _exportType = v ?? _exportType),
          items: [
            for (final t in _exportTypes)
              if (isWireModuleEnabledForCompany(t, _enabledModules(context)))
                DropdownMenuItem(value: t, child: Text(context.tr(t))),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: _exporting ? null : _runExport,
            icon: _exporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined, size: 18),
            label: Text(context.tr('export')),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      titleKey: 'import_export',
      body: SettingsFormShell(
        sections: [
          switch (_step) {
            _Step.pick => _pickSection(context),
            _Step.map => _mapSection(context),
            _Step.done => _doneSection(context),
          },
          if (_step == _Step.pick) _migrationSection(context),
          if (_step == _Step.pick) _exportSection(context),
        ],
      ),
    );
  }

  /// Bank-account picker, shown only for `bank_transaction` imports — the
  /// `/api/v1/import` endpoint requires a `bank_integration_id` so imported
  /// rows attach to a target account.
  Widget _bankAccountField(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: StreamBuilder<List<BankAccount>>(
        stream: services.bankAccounts.watchAll(companyId: companyId),
        builder: (context, snap) {
          final accounts = (snap.data ?? const <BankAccount>[])
              .where((a) => !a.isDeleted)
              .toList();
          return DropdownButtonFormField<String>(
            initialValue: _bankIntegrationId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('bank_account'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _busy
                ? null
                : (v) => setState(() => _bankIntegrationId = v),
            items: [
              for (final a in accounts)
                DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name.isEmpty ? a.id : a.name),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _pickSection(BuildContext context) {
    return FormSection(
      title: context.tr('import'),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _entity,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('import_type'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _busy
              ? null
              : (v) => setState(() {
                  _entity = v ?? _entity;
                  _bankIntegrationId = null;
                }),
          items: [
            for (final e in kImportableEntities)
              if (isWireModuleEnabledForCompany(e, _enabledModules(context)))
                DropdownMenuItem(value: e, child: Text(context.tr(e))),
          ],
        ),
        if (_entity == 'bank_transaction') _bankAccountField(context),
        FileDropZone(
          allowedExtensions: const ['csv'],
          enabled: !_busy,
          onFiles: _onCsvFiles,
        ),
        if (_fileName != null) ...[
          const SizedBox(height: InSpacing.sm),
          Text(
            _fileName!,
            style: TextStyle(fontSize: 13, color: context.inTheme.ink2),
          ),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed:
                (_bytes == null ||
                    _busy ||
                    (_entity == 'bank_transaction' &&
                        (_bankIntegrationId ?? '').isEmpty))
                ? null
                : _runPreImport,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('continue')),
          ),
        ),
      ],
    );
  }

  Widget _mapSection(BuildContext context) {
    final preview = _preview!;
    final tokens = context.inTheme;
    return FormSection(
      title: context.tr('column_mapping'),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _skipHeader,
          onChanged: _busy ? null : (v) => setState(() => _skipHeader = v),
          title: Text(context.tr('skip_header')),
        ),
        const Divider(height: 1),
        for (var i = 0; i < preview.columns.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: InSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview.columns[i],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (i < preview.sample.length &&
                          preview.sample[i].isNotEmpty)
                        Text(
                          preview.sample[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: tokens.ink3),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: InSpacing.md(context)),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _map[i]?.isNotEmpty == true ? _map[i] : '',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _map[i] = v ?? ''),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(context.tr('skip')),
                      ),
                      for (final field in preview.available)
                        DropdownMenuItem(
                          value: field,
                          child: Text(field, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
              onPressed: _busy ? null : _reset,
              child: Text(context.tr('back')),
            ),
            SizedBox(width: InSpacing.md(context)),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
                onPressed: (_busy || _map.values.every((v) => v.isEmpty))
                    ? null
                    : _runImport,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('import')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _doneSection(BuildContext context) {
    return FormSection(
      title: context.tr('import'),
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: context.inTheme.accent),
            SizedBox(width: InSpacing.md(context)),
            Expanded(child: Text(context.tr('import_started'))),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: _reset,
            child: Text(context.tr('import')),
          ),
        ),
      ],
    );
  }
}
