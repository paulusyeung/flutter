import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Search keys rendered by this tab.
const kRestoreTabSearchKeys = <String>[
  'restore',
  'import_settings',
  'import_data',
  'company_backup_file',
];

/// Restore tab body — chunked `.zip` upload to `/api/v1/import_json`. The
/// server runs the restore asynchronously and emails the user when it
/// finishes; the success toast here just confirms the upload was accepted.
class RestoreTabBody extends StatefulWidget {
  const RestoreTabBody({super.key});

  @override
  State<RestoreTabBody> createState() => _RestoreTabBodyState();
}

class _RestoreTabBodyState extends State<RestoreTabBody> {
  File? _file;
  int _fileLength = 0;
  bool _dragOver = false;
  bool _importSettings = false;
  // UX default: most users restoring a backup want their data back. Settings
  // is the rarer ask and stays opt-in.
  bool _importData = true;
  bool _busy = false;
  bool _cancelRequested = false;
  bool _completedNeedsBanner = false;
  int _sent = 0;
  int _total = 1;

  bool get _canRestore =>
      _file != null && (_importSettings || _importData) && !_busy;

  Future<void> _acceptPath(String path) async {
    if (!path.toLowerCase().endsWith('.zip')) {
      if (!mounted) return;
      Notify.warning(context, context.tr('dropzone_invalid_file_type'));
      return;
    }
    final file = File(path);
    // Capture length once so the build pass doesn't hit the disk on every
    // frame; also lets us reject 0-byte files before the upload spins
    // forever at 0%.
    int length = 0;
    try {
      length = await file.length();
    } catch (_) {
      length = 0;
    }
    if (length <= 0) {
      if (!mounted) return;
      Notify.warning(context, context.tr('dropzone_invalid_file_type'));
      return;
    }
    if (!mounted) return;
    setState(() {
      _file = file;
      _fileLength = length;
      _completedNeedsBanner = false;
    });
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null) return;
    await _acceptPath(path);
  }

  Future<void> _onDropped(List<String> paths) async {
    final zip = paths.firstWhere(
      (p) => p.toLowerCase().endsWith('.zip'),
      orElse: () => '',
    );
    if (zip.isEmpty) {
      if (!mounted) return;
      Notify.warning(context, context.tr('dropzone_invalid_file_type'));
      return;
    }
    await _acceptPath(zip);
  }

  Future<void> _confirmAndRestore() async {
    if (!_canRestore) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('restore')),
        content: Text(ctx.tr('restore_confirm_message')),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('continue')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await _runUpload();
  }

  Future<void> _runUpload() async {
    final file = _file;
    if (file == null) return;
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() {
      _busy = true;
      _cancelRequested = false;
      _sent = 0;
      _total = 1;
    });
    final idempotencyKey = const Uuid().v4();
    try {
      await services.apiClient.uploadMultipartChunked(
        path: '/api/v1/import_json',
        file: file,
        commonFields: {
          'import_settings': '$_importSettings',
          'import_data': '$_importData',
        },
        commonQueryTrue: {
          if (_importSettings) 'import_settings': 'true',
          if (_importData) 'import_data': 'true',
        },
        idempotencyKey: idempotencyKey,
        onProgress: (sent, total) {
          if (!mounted) return;
          setState(() {
            _sent = sent;
            _total = total;
          });
        },
        isCancelled: () => _cancelRequested,
      );
      if (!mounted) return;
      Notify.success(context, context.tr('import_started'), messenger: messenger);
      // Keep the file row visible with an inline banner so the user doesn't
      // bounce between "Restore" button and a blank form. They navigate
      // away (or re-pick) to clear.
      setState(() {
        _completedNeedsBanner = true;
        _importSettings = false;
        _importData = true;
      });
    } on UploadCancelledException {
      // User-initiated stop — silent.
    } on DemoModeException {
      if (!mounted) return;
      Notify.warning(
        context,
        context.tr('demo_mode_disabled'),
        messenger: messenger,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Notify.error(
        context,
        context.tr('error_title'),
        error: e,
        messenger: messenger,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _cancelRequested = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('restore'),
          children: [
            _Dropzone(
              file: _file,
              fileLength: _fileLength,
              dragOver: _dragOver,
              onEntered: () => setState(() => _dragOver = true),
              onExited: () => setState(() => _dragOver = false),
              onDrop: _onDropped,
              onPick: _pickFile,
              onClear: () => setState(() {
                _file = null;
                _fileLength = 0;
                _completedNeedsBanner = false;
              }),
              enabled: !_busy,
            ),
            SizedBox(height: InSpacing.lg(context)),
            _ImportToggles(
              importSettings: _importSettings,
              importData: _importData,
              onSettings: _busy
                  ? null
                  : (v) => setState(() => _importSettings = v),
              onData: _busy ? null : (v) => setState(() => _importData = v),
            ),
            if (_busy) ...[
              SizedBox(height: InSpacing.lg(context)),
              _UploadProgress(
                sent: _sent,
                total: _total,
                onCancel: () => setState(() => _cancelRequested = true),
              ),
            ] else if (_completedNeedsBanner) ...[
              SizedBox(height: InSpacing.lg(context)),
              _QueuedBanner(),
            ] else ...[
              SizedBox(height: InSpacing.lg(context)),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(context.tr('restore')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 44),
                  ),
                  onPressed: _canRestore ? _confirmAndRestore : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Dropzone extends StatelessWidget {
  const _Dropzone({
    required this.file,
    required this.fileLength,
    required this.dragOver,
    required this.onEntered,
    required this.onExited,
    required this.onDrop,
    required this.onPick,
    required this.onClear,
    required this.enabled,
  });

  final File? file;
  final int fileLength;
  final bool dragOver;
  final VoidCallback onEntered;
  final VoidCallback onExited;
  final void Function(List<String> paths) onDrop;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final borderColor = dragOver ? tokens.accent : tokens.border;
    return DropTarget(
      enable: enabled,
      onDragEntered: (_) => onEntered(),
      onDragExited: (_) => onExited(),
      onDragDone: (details) {
        final paths = <String>[];
        for (final xf in details.files) {
          if (xf.path.isNotEmpty) paths.add(xf.path);
        }
        onDrop(paths);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.all(InSpacing.lg(context)),
        decoration: BoxDecoration(
          color: dragOver ? tokens.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(InRadii.r2),
          border: Border.all(
            color: borderColor,
            width: dragOver ? 2 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: file == null
            ? _EmptyDropzone(onPick: enabled ? onPick : null)
            : _PickedFileRow(
                file: file!,
                sizeText: _formatBytes(fileLength),
                onClear: enabled ? onClear : null,
              ),
      ),
    );
  }
}

class _EmptyDropzone extends StatelessWidget {
  const _EmptyDropzone({required this.onPick});
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Below ~480 px the inline button squeezes the help text; stack on a
        // column instead.
        final narrow = constraints.maxWidth < 480;
        final icon = Icon(
          Icons.cloud_upload_outlined,
          color: tokens.ink3,
          size: 36,
        );
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('company_backup_file'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: InSpacing.sm / 2),
            Text(
              context.tr('company_backup_file_help'),
              style: TextStyle(color: tokens.ink2),
            ),
          ],
        );
        final button = OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: Text(context.tr('select_file')),
          style: OutlinedButton.styleFrom(minimumSize: const Size(120, 40)),
          onPressed: onPick,
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  icon,
                  SizedBox(width: InSpacing.md(context)),
                  Expanded(child: text),
                ],
              ),
              SizedBox(height: InSpacing.md(context)),
              Align(alignment: Alignment.centerLeft, child: button),
            ],
          );
        }
        return Row(
          children: [
            icon,
            SizedBox(width: InSpacing.md(context)),
            Expanded(child: text),
            SizedBox(width: InSpacing.md(context)),
            button,
          ],
        );
      },
    );
  }
}

class _PickedFileRow extends StatelessWidget {
  const _PickedFileRow({
    required this.file,
    required this.sizeText,
    required this.onClear,
  });
  final File file;
  final String sizeText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final name = file.path.split(Platform.pathSeparator).last;
    return Row(
      children: [
        Icon(Icons.folder_zip_outlined, color: tokens.accent, size: 28),
        SizedBox(width: InSpacing.md(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
              if (sizeText.isNotEmpty)
                Text(sizeText, style: TextStyle(color: tokens.ink3)),
            ],
          ),
        ),
        IconButton(
          tooltip: context.tr('cancel'),
          icon: const Icon(Icons.close),
          onPressed: onClear,
        ),
      ],
    );
  }
}

class _ImportToggles extends StatelessWidget {
  const _ImportToggles({
    required this.importSettings,
    required this.importData,
    required this.onSettings,
    required this.onData,
  });

  final bool importSettings;
  final bool importData;
  final ValueChanged<bool>? onSettings;
  final ValueChanged<bool>? onData;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('import_settings')),
          subtitle: Text(
            context.tr('settings'),
            style: TextStyle(color: tokens.ink3),
          ),
          value: importSettings,
          onChanged: onSettings,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('import_data')),
          subtitle: Text(
            context.tr('data'),
            style: TextStyle(color: tokens.ink3),
          ),
          value: importData,
          onChanged: onData,
        ),
      ],
    );
  }
}

class _UploadProgress extends StatelessWidget {
  const _UploadProgress({
    required this.sent,
    required this.total,
    required this.onCancel,
  });

  final int sent;
  final int total;
  final VoidCallback onCancel;

  String _mb(int bytes) => (bytes / 1024 / 1024).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final ratio = total <= 0 ? 0.0 : (sent / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    // Stack: bar → label → action row. Avoids horizontal squeeze on narrow
    // widths where a "X.X / Y.Y MB · NN% uploaded" string ellipsises.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(InRadii.r1),
          child: LinearProgressIndicator(value: ratio),
        ),
        SizedBox(height: InSpacing.sm),
        Text(
          '${_mb(sent)} / ${_mb(total)} MB · $percent% ${context.tr('uploaded')}',
          style: TextStyle(color: tokens.ink2),
        ),
        SizedBox(height: InSpacing.md(context)),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(context.tr('stop')),
            style: OutlinedButton.styleFrom(minimumSize: const Size(100, 40)),
            onPressed: onCancel,
          ),
        ),
      ],
    );
  }
}

class _QueuedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: EdgeInsets.all(InSpacing.md(context)),
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: Row(
        children: [
          Icon(Icons.mark_email_read_outlined, color: tokens.accent),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: Text(
              context.tr('import_started'),
              style: TextStyle(color: tokens.ink),
            ),
          ),
        ],
      ),
    );
  }
}
