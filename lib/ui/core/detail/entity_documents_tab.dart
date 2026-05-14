import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/document.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/utils/document_upload_validation.dart';
import 'package:admin/utils/url_safety.dart';
import 'package:admin/utils/formatting.dart';

/// Reusable per-entity Documents tab body. Used on the Client and Product
/// detail screens (and any future entity that supports attachments).
///
/// The widget is entity-agnostic — the host wires the four callbacks to
/// the right repository methods (`uploadDocument`, `deleteDocument`,
/// `setDocumentVisibility`) and supplies the document list. The tab
/// short-circuits to a save-first message when [entityId] is a tmp id
/// (the entity doesn't exist server-side yet — uploads would 404).
class EntityDocumentsTab extends StatefulWidget {
  const EntityDocumentsTab({
    super.key,
    required this.entityId,
    required this.documents,
    required this.onUpload,
    required this.onDelete,
    required this.onToggleVisibility,
    this.formatter,
    this.readOnly = false,
  });

  /// Server id of the parent entity. When it starts with `tmp_`, only the
  /// "save first" banner renders — the entity has to round-trip to the
  /// server before its documents URL is reachable.
  final String entityId;

  /// Current document list, derived from the entity's domain row by the
  /// host (typically `vm.client.documents` / `vm.product.documents`).
  final List<Document> documents;

  /// Callback for one or more newly picked / dropped local file paths.
  /// The host typically does `paths.forEach(repo.uploadDocument)` — the
  /// outbox handles sequencing.
  final Future<void> Function(List<String> localPaths) onUpload;

  /// Callback when the user picks **Delete** on a row. The host enqueues
  /// `repo.deleteDocument`; the sync engine prompts for the password
  /// because `requiresPasswordFor(MutationKind.documentDelete)` is true.
  /// No pre-confirmation dialog — typing the password is the
  /// confirmation.
  final Future<void> Function(Document doc) onDelete;

  /// Callback for the Set Private / Set Public menu items.
  final Future<void> Function(Document doc) onToggleVisibility;

  /// Optional [Formatter] for rendering dates in the company's preferred
  /// `date_format_id`. When null, falls back to the iso `YYYY-MM-DD`.
  final Formatter? formatter;

  /// When true, hide the upload affordance + per-row actions menu. Used
  /// when the user lacks `edit_<entity>` permission, mirroring React's
  /// `disableEditableOptions`.
  final bool readOnly;

  @override
  State<EntityDocumentsTab> createState() => _EntityDocumentsTabState();
}

class _EntityDocumentsTabState extends State<EntityDocumentsTab> {
  bool _dragOver = false;

  bool get _isDesktop {
    final p = defaultTargetPlatform;
    return p == TargetPlatform.macOS ||
        p == TargetPlatform.linux ||
        p == TargetPlatform.windows;
  }

  bool get _isTmp => widget.entityId.startsWith('tmp_');

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    if (_isTmp) {
      return Padding(
        padding: EdgeInsets.all(InSpacing.lg(context)),
        child: Text(
          context.tr('save_to_upload_documents'),
          style: TextStyle(color: tokens.ink3),
        ),
      );
    }
    final sorted = [...widget.documents]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Padding(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.readOnly) _buildUploadAffordance(context),
          if (sorted.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: widget.readOnly ? 0 : InSpacing.lg(context),
              ),
              child: Text(
                context.tr('no_records_found'),
                style: TextStyle(color: tokens.ink3),
              ),
            )
          else ...[
            SizedBox(height: InSpacing.lg(context)),
            _DocumentList(
              documents: sorted,
              formatter: widget.formatter,
              readOnly: widget.readOnly,
              onView: _onView,
              onDelete: widget.onDelete,
              onToggleVisibility: widget.onToggleVisibility,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadAffordance(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: _pickAndUpload,
      icon: const Icon(Icons.upload),
      label: Text(context.tr('upload')),
      style: FilledButton.styleFrom(minimumSize: const Size(120, 40)),
    );
    if (!_isDesktop) {
      return Align(alignment: Alignment.centerLeft, child: button);
    }
    return _Dropzone(
      dragOver: _dragOver,
      onEntered: () => setState(() => _dragOver = true),
      onExited: () => setState(() => _dragOver = false),
      onDrop: _onDrop,
      child: button,
    );
  }

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: kDocumentAllowedExtensions,
      allowMultiple: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final paths = <String>[];
    for (final f in picked.files) {
      final p = f.path;
      if (p == null) continue;
      paths.add(p);
    }
    if (!mounted) return;
    await _validateAndUpload(paths);
  }

  Future<void> _onDrop(List<String> droppedPaths) async {
    setState(() => _dragOver = false);
    await _validateAndUpload(droppedPaths);
  }

  Future<void> _validateAndUpload(List<String> paths) async {
    if (paths.isEmpty) return;
    final goodPaths = <String>[];
    bool sawWrongType = false;
    bool sawTooLarge = false;
    for (final p in paths) {
      final result = await validateDocumentUpload(p);
      if (result.isOk) {
        goodPaths.add(p);
      } else {
        switch (result.issue) {
          case DocumentUploadIssue.wrongExtension:
            sawWrongType = true;
          case DocumentUploadIssue.tooLarge:
            sawTooLarge = true;
          case DocumentUploadIssue.unreadable:
            sawWrongType = true; // surface as generic reject
          case null:
            break;
        }
      }
    }
    if (!mounted) return;
    if (sawWrongType) {
      Notify.warning(context, context.tr('dropzone_invalid_file_type'));
    }
    if (sawTooLarge) {
      Notify.warning(
        context,
        context.tr('upload_too_large_with_size', {'size': '$kDocumentMaxMb'}),
      );
    }
    if (goodPaths.isEmpty) return;
    try {
      await widget.onUpload(goodPaths);
      if (!mounted) return;
      Notify.success(context, context.tr('uploaded_document'));
    } catch (e) {
      if (!mounted) return;
      Notify.error(context, context.tr('error_uploading_document'), error: e);
    }
  }

  Future<void> _onView(Document doc) async {
    // Document URLs are server-supplied. Without this scheme check, a
    // hostile or compromised server could push javascript:, file:, or
    // intent:// URIs and have them dispatched to the OS handler when the
    // user taps "View document".
    if (!isSafeHttpsUrl(doc.url)) return;
    await launchUrl(Uri.parse(doc.url), mode: LaunchMode.externalApplication);
  }
}

class _Dropzone extends StatelessWidget {
  const _Dropzone({
    required this.dragOver,
    required this.onEntered,
    required this.onExited,
    required this.onDrop,
    required this.child,
  });

  final bool dragOver;
  final VoidCallback onEntered;
  final VoidCallback onExited;
  final Future<void> Function(List<String>) onDrop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final borderColor = dragOver ? tokens.accent : tokens.border;
    return DropTarget(
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr(
                  dragOver ? 'drop_files_here' : 'documents_drop_hint',
                ),
                style: TextStyle(color: tokens.ink2),
              ),
            ),
            SizedBox(width: InSpacing.md(context)),
            child,
          ],
        ),
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({
    required this.documents,
    required this.formatter,
    required this.readOnly,
    required this.onView,
    required this.onDelete,
    required this.onToggleVisibility,
  });

  final List<Document> documents;
  final Formatter? formatter;
  final bool readOnly;
  final Future<void> Function(Document doc) onView;
  final Future<void> Function(Document doc) onDelete;
  final Future<void> Function(Document doc) onToggleVisibility;

  static const _narrowBreakpoint = 720.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrowBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < documents.length; i++) ...[
              if (i > 0) const SizedBox(height: InSpacing.sm),
              _DocumentRow(
                doc: documents[i],
                narrow: narrow,
                formatter: formatter,
                readOnly: readOnly,
                onView: onView,
                onDelete: onDelete,
                onToggleVisibility: onToggleVisibility,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.doc,
    required this.narrow,
    required this.formatter,
    required this.readOnly,
    required this.onView,
    required this.onDelete,
    required this.onToggleVisibility,
  });

  final Document doc;
  final bool narrow;
  final Formatter? formatter;
  final bool readOnly;
  final Future<void> Function(Document doc) onView;
  final Future<void> Function(Document doc) onDelete;
  final Future<void> Function(Document doc) onToggleVisibility;

  static const _imageExts = <String>{
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'heic',
    'svg',
    'bmp',
  };

  String _formatDate(BuildContext context) {
    if (doc.updatedAt <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      doc.updatedAt * 1000,
      isUtc: true,
    );
    final iso =
        '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
    return formatter?.date(iso) ?? iso;
  }

  IconData _typeIcon() {
    final ext = doc.type.toLowerCase();
    return _imageExts.contains(ext)
        ? Icons.image_outlined
        : Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final displayName = doc.name.isNotEmpty ? doc.name : doc.hash;
    final dateLabel = _formatDate(context);
    final sizeLabel = doc.size > 0 ? formatSize(doc.size) : '';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.md(context),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: narrow
          ? _NarrowLayout(
              icon: _typeIcon(),
              displayName: displayName,
              isPrivate: !doc.isPublic,
              dateLabel: dateLabel,
              sizeLabel: sizeLabel,
              tokens: tokens,
              trailing: readOnly
                  ? null
                  : _ActionsMenu(
                      doc: doc,
                      onView: onView,
                      onDelete: onDelete,
                      onToggleVisibility: onToggleVisibility,
                    ),
            )
          : _WideLayout(
              icon: _typeIcon(),
              displayName: displayName,
              isPrivate: !doc.isPublic,
              dateLabel: dateLabel,
              sizeLabel: sizeLabel,
              tokens: tokens,
              trailing: readOnly
                  ? null
                  : _ActionsMenu(
                      doc: doc,
                      onView: onView,
                      onDelete: onDelete,
                      onToggleVisibility: onToggleVisibility,
                    ),
            ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.icon,
    required this.displayName,
    required this.isPrivate,
    required this.dateLabel,
    required this.sizeLabel,
    required this.tokens,
    required this.trailing,
  });

  final IconData icon;
  final String displayName;
  final bool isPrivate;
  final String dateLabel;
  final String sizeLabel;
  final InTheme tokens;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: tokens.ink2),
        SizedBox(width: InSpacing.md(context)),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.ink),
                ),
              ),
              if (isPrivate) ...[
                const SizedBox(width: InSpacing.sm),
                Icon(Icons.lock_outline, size: 14, color: tokens.ink3),
              ],
            ],
          ),
        ),
        SizedBox(width: InSpacing.md(context)),
        Expanded(
          flex: 2,
          child: Text(dateLabel, style: TextStyle(color: tokens.ink3)),
        ),
        SizedBox(width: InSpacing.md(context)),
        SizedBox(
          width: 80,
          child: Text(
            sizeLabel,
            textAlign: TextAlign.right,
            style: TextStyle(color: tokens.ink3),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: InSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.icon,
    required this.displayName,
    required this.isPrivate,
    required this.dateLabel,
    required this.sizeLabel,
    required this.tokens,
    required this.trailing,
  });

  final IconData icon;
  final String displayName;
  final bool isPrivate;
  final String dateLabel;
  final String sizeLabel;
  final InTheme tokens;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (dateLabel.isNotEmpty) dateLabel,
      if (sizeLabel.isNotEmpty) sizeLabel,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: tokens.ink2),
        SizedBox(width: InSpacing.md(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.ink),
                    ),
                  ),
                  if (isPrivate) ...[
                    const SizedBox(width: InSpacing.sm),
                    Icon(Icons.lock_outline, size: 14, color: tokens.ink3),
                  ],
                ],
              ),
              if (subtitleParts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitleParts.join(' · '),
                    style: TextStyle(color: tokens.ink3, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: InSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

enum _RowAction { view, toggleVisibility, delete }

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({
    required this.doc,
    required this.onView,
    required this.onDelete,
    required this.onToggleVisibility,
  });

  final Document doc;
  final Future<void> Function(Document doc) onView;
  final Future<void> Function(Document doc) onDelete;
  final Future<void> Function(Document doc) onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RowAction>(
      tooltip: context.tr('actions'),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        switch (action) {
          case _RowAction.view:
            await onView(doc);
          case _RowAction.toggleVisibility:
            await onToggleVisibility(doc);
          case _RowAction.delete:
            await onDelete(doc);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _RowAction.view,
          child: ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(context.tr('view')),
          ),
        ),
        PopupMenuItem(
          value: _RowAction.toggleVisibility,
          child: ListTile(
            leading: Icon(
              doc.isPublic ? Icons.lock_outline : Icons.lock_open_outlined,
            ),
            title: Text(
              context.tr(doc.isPublic ? 'set_private' : 'set_public'),
            ),
          ),
        ),
        PopupMenuItem(
          value: _RowAction.delete,
          child: ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(context.tr('delete')),
          ),
        ),
      ],
    );
  }
}
