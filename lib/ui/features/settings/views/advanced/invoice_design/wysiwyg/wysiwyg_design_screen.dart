import 'dart:convert';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/core/widgets/notify.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/services/live_design_service.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/design_edit_view_model.dart'
    show kBlankDesignBody;
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_sizing.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/canvas/wysiwyg_canvas.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/mobile/mobile_reorder_view.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/palette/component_palette.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/preview/wysiwyg_preview_sheet.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/property_panel.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_edit_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';

/// WYSIWYG invoice designer screen — sibling to the Twig editor
/// [DesignEditScreen]. Routed via the Custom Designs new-design chooser
/// ("Use visual builder") and the row-level "Open in builder" action.
///
/// Form-factor adaptation (Phase 1):
///   - **Desktop ≥ 1024 px:** three-pane (palette / canvas / property panel).
///   - **Tablet 600–1024 px:** two-pane (palette + canvas); property panel
///     surfaces as a bottom sheet when a block is selected.
///   - **Phone < 600 px:** single-pane canvas with palette as a launching
///     bottom sheet. Drag-resize is disabled — a 12-col grid on a 320 px
///     viewport is unusable; user reorders blocks via the property sheet.
class WysiwygDesignScreen extends StatelessWidget {
  const WysiwygDesignScreen({this.existingId, this.seedFrom, super.key});

  final String? existingId;
  final Design? seedFrom;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    if (companyId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Watch the active company so the VM can seed DocumentSettings from
    // `company.settings.*` (matches React's `createDefaultDocumentSettings`).
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(companyId),
      builder: (context, snapshot) {
        final company = snapshot.data;
        if (company == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildScaffold(context, services, companyId, company);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    Services services,
    String companyId,
    Company company,
  ) {
    final repo = services.designs;
    // Phase 3a: Pro gate. Save disabled and a banner shown for free users.
    final isPro = services.auth.session.value?.hasProAccess ?? false;
    return SettingsEntityEditScaffold<Design, WysiwygDesignViewModel>(
      existingId: existingId,
      backRoute: '/settings/invoice_design/custom_designs',
      createTitleKey: 'new_design',
      editTitleKey: 'edit_design',
      wireName: 'design',
      watchById: (id) => repo.watch(companyId: companyId, id: id),
      refreshAll: () => repo.refreshAll(companyId: companyId),
      onArchive: (id) => repo.archive(companyId: companyId, id: id),
      onRestore: (id) => repo.restore(companyId: companyId, id: id),
      onDelete: (id) => repo.delete(companyId: companyId, id: id),
      vmFactory: ({existing}) => WysiwygDesignViewModel(
        repo: repo,
        companyId: companyId,
        existing: existing,
        // Phase 1.5 #6: seed DocumentSettings from the active company so a
        // brand-new design starts with the user's preferred page size,
        // fonts, etc.
        companySettings: company.settings,
      ),
      isArchivedOf: (d) => d.archivedAt != null,
      isDeletedOf: (d) => d.isDeleted,
      canSave: (vm) =>
          isPro &&
          !vm.isSaving &&
          vm.isDirty &&
          vm.draft.name.trim().isNotEmpty,
      guardUnsavedChanges: true,
      // Phase 1.5 #8: actually clear the draft on discard so the
      // unsaved-changes guard doesn't keep firing on every navigation.
      onDiscard: (vm) => vm.resetToEmpty(company.settings),
      customBodyBuilder: (context, vm) => _Workspace(
        vm: vm,
        seedFrom: seedFrom,
        isPro: isPro,
      ),
    );
  }
}

class _Workspace extends StatefulWidget {
  const _Workspace({
    required this.vm,
    this.seedFrom,
    required this.isPro,
  });

  final WysiwygDesignViewModel vm;
  final Design? seedFrom;
  final bool isPro;

  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  /// Phase 3c: dismissed by tapping "Start visual design" in the Twig
  /// coexistence banner. Stays dismissed for the session.
  bool _twigBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.seedFrom;
    if (seed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.vm.loadFrom(seed);
      });
    }
  }

  /// Whether the loaded design has custom Twig in `body` (anything not the
  /// blank scaffold) AND no WYSIWYG blocks yet. Builder save would
  /// overwrite the Twig last-writer-wins, so warn before the user starts
  /// editing here.
  bool _hasCustomTwig() {
    final t = widget.vm.draft.template;
    if (t.blocks.isNotEmpty) return false;
    final body = t.body.trim();
    if (body.isEmpty) return false;
    if (body == kBlankDesignBody.trim()) return false;
    return true;
  }

  /// Move the selected block by (dx, dy) cells, clamped to the 12-col grid.
  /// Locked blocks no-op. Skipped when nothing is selected (so an arrow
  /// key in an unrelated focus tree doesn't accidentally fire).
  void _nudgeSelected(int dx, int dy) {
    final block = widget.vm.selectedBlock;
    if (block == null || block.locked) return;
    final p = block.gridPosition;
    final maxX = 12 - p.w;
    final nx = (p.x + dx).clamp(0, maxX);
    final ny = (p.y + dy).clamp(0, 999);
    if (nx == p.x && ny == p.y) return;
    widget.vm.recordHistorySnapshot();
    widget.vm.updateBlock(
      block.copyWith(
        gridPosition: GridPosition(x: nx, y: ny, w: p.w, h: p.h),
      ),
    );
  }

  /// Resize the selected block by (dw, dh) cells from the bottom-right
  /// edge. Clamped via `block_sizing.dart`. Locked blocks no-op.
  void _resizeNudgeSelected(int dw, int dh) {
    final block = widget.vm.selectedBlock;
    if (block == null || block.locked) return;
    final p = block.gridPosition;
    final clamped = clampSize(
      type: block.type,
      desiredW: p.w + dw,
      desiredH: p.h + dh,
      x: p.x,
      y: p.y,
    );
    if (clamped.w == p.w && clamped.h == p.h) return;
    widget.vm.recordHistorySnapshot();
    widget.vm.updateBlock(
      block.copyWith(
        gridPosition: GridPosition(x: p.x, y: p.y, w: clamped.w, h: clamped.h),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the workspace in Shortcuts/Actions for undo/redo. Save (Cmd+S) is
    // already wired by the SettingsEntityEditScaffold; here we add the two
    // history shortcuts (and Ctrl variants for non-Mac).
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): _RedoIntent(),
        // Arrow-key nudging — moves the selected block one grid cell.
        // Shift + arrow resizes by one cell (anchored at the top-left;
        // grow / shrink on the right or bottom edge).
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            _NudgeIntent(dx: -1, dy: 0),
        SingleActivator(LogicalKeyboardKey.arrowRight):
            _NudgeIntent(dx: 1, dy: 0),
        SingleActivator(LogicalKeyboardKey.arrowUp):
            _NudgeIntent(dx: 0, dy: -1),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _NudgeIntent(dx: 0, dy: 1),
        SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
            _ResizeNudgeIntent(dw: -1, dh: 0),
        SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
            _ResizeNudgeIntent(dw: 1, dh: 0),
        SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
            _ResizeNudgeIntent(dw: 0, dh: -1),
        SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
            _ResizeNudgeIntent(dw: 0, dh: 1),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) {
              if (widget.vm.canUndo) widget.vm.undo();
              return null;
            },
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) {
              if (widget.vm.canRedo) widget.vm.redo();
              return null;
            },
          ),
          _NudgeIntent: CallbackAction<_NudgeIntent>(
            onInvoke: (intent) {
              _nudgeSelected(intent.dx, intent.dy);
              return null;
            },
          ),
          _ResizeNudgeIntent: CallbackAction<_ResizeNudgeIntent>(
            onInvoke: (intent) {
              _resizeNudgeSelected(intent.dw, intent.dh);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: ListenableBuilder(
            listenable: widget.vm,
            builder: (context, _) {
              final width = MediaQuery.of(context).size.width;
              return Column(
                children: [
                  if (!widget.isPro) const _ProGateBanner(),
                  if (!_twigBannerDismissed && _hasCustomTwig())
                    _TwigCoexistenceBanner(
                      onStartVisual: () =>
                          setState(() => _twigBannerDismissed = true),
                      onStayInTwig: () => Navigator.of(context).maybePop(),
                    ),
                  _TopBar(vm: widget.vm),
                  _DesignNameField(vm: widget.vm),
                  Expanded(
                    child: width < 600
                        ? _PhoneLayout(vm: widget.vm)
                        : width < 1024
                            ? _TabletLayout(vm: widget.vm)
                            : _DesktopLayout(vm: widget.vm),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Phase 3c: warns the user when this design already carries non-default
/// Twig code (legacy custom design). Saving from the visual builder would
/// overwrite the whole template last-writer-wins, so we surface the
/// choice up front: stay in the Twig editor or start the visual design.
class _TwigCoexistenceBanner extends StatelessWidget {
  const _TwigCoexistenceBanner({
    required this.onStartVisual,
    required this.onStayInTwig,
  });

  final VoidCallback onStartVisual;
  final VoidCallback onStayInTwig;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      width: double.infinity,
      color: tokens.partialSoft,
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.md(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_outlined, size: 18, color: tokens.partial),
              SizedBox(width: InSpacing.sm),
              Expanded(
                child: Text(
                  context.tr('twig_coexistence_banner'),
                  style: TextStyle(color: tokens.ink, fontSize: 13),
                ),
              ),
            ],
          ),
          SizedBox(height: InSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                onPressed: onStayInTwig,
                child: Text(context.tr('stay_in_twig_editor')),
              ),
              SizedBox(width: InSpacing.md(context)),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 44),
                ),
                onPressed: onStartVisual,
                child: Text(context.tr('start_visual_design')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Phase 3a: shown to free users above the workspace. The editor stays
/// fully interactive (so they can "Try it") but Save is disabled at the
/// scaffold level — the upgrade nudge is honest about the gate.
/// Phase 8e + 8k: export / import menu items.
enum _ExportKind { file, clipboard, importJson }

class _ProGateBanner extends StatelessWidget {
  const _ProGateBanner();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      width: double.infinity,
      color: tokens.accentSoft,
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.md(context),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, size: 18, color: tokens.ink),
          SizedBox(width: InSpacing.sm),
          Expanded(
            child: Text(
              context.tr('pro_required_to_save_visual_designer'),
              style: TextStyle(fontSize: 13, color: tokens.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marker intents wired by the workspace `Shortcuts` block. Save uses the
/// scaffold's existing `_SaveFormIntent` (see `entity_edit_scaffold.dart`).
class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _NudgeIntent extends Intent {
  const _NudgeIntent({required this.dx, required this.dy});
  final int dx;
  final int dy;
}

class _ResizeNudgeIntent extends Intent {
  const _ResizeNudgeIntent({required this.dw, required this.dh});
  final int dw;
  final int dh;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.vm});
  final WysiwygDesignViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.inTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.undo_outlined),
            tooltip: context.tr('undo'),
            onPressed: vm.canUndo ? vm.undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo_outlined),
            tooltip: context.tr('redo'),
            onPressed: vm.canRedo ? vm.redo : null,
          ),
          SizedBox(width: InSpacing.md(context)),
          TextButton.icon(
            icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
            label: Text(context.tr('fix_overlaps')),
            onPressed: vm.blocks.isEmpty ? null : vm.fixOverlaps,
          ),
          const Spacer(),
          // Phase 8g: zoom indicator. Fixed at 100% — the canvas
          // doesn't expose zoom yet and pinch-zoom would be a gesture
          // concern. Hidden on narrow viewports to keep the top bar
          // from overflowing.
          if (MediaQuery.sizeOf(context).width >= 720) ...[
            Text(
              '${context.tr('zoom')}: 100%',
              style: TextStyle(
                fontSize: 12,
                color: context.inTheme.ink3,
              ),
            ),
            SizedBox(width: InSpacing.md(context)),
          ],
          // Phase 8e: export menu — clipboard (legacy) + file download.
          // React's `InvoiceBuilder.tsx` downloads `invoice-design-{ts}.json`;
          // we keep the clipboard option for power users + add the file
          // path most users expect.
          PopupMenuButton<_ExportKind>(
            tooltip: context.tr('export_design'),
            // Always enabled — Import doesn't need an existing draft;
            // Export items disable themselves inside the menu when
            // blocks are empty.
            icon: const Icon(Icons.import_export_outlined, size: 18),
            onSelected: (k) => switch (k) {
              _ExportKind.clipboard => _exportDesignJson(context, vm),
              _ExportKind.file => _downloadDesignJson(context, vm),
              _ExportKind.importJson => _importDesignJson(context, vm),
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: _ExportKind.file,
                enabled: vm.blocks.isNotEmpty,
                child: Row(
                  children: [
                    const Icon(Icons.save_alt_outlined, size: 16),
                    SizedBox(width: InSpacing.sm),
                    Text(ctx.tr('download_json')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _ExportKind.clipboard,
                enabled: vm.blocks.isNotEmpty,
                child: Row(
                  children: [
                    const Icon(Icons.content_copy_outlined, size: 16),
                    SizedBox(width: InSpacing.sm),
                    Text(ctx.tr('copy_to_clipboard')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ExportKind.importJson,
                child: Row(
                  children: [
                    const Icon(Icons.file_upload_outlined, size: 16),
                    SizedBox(width: InSpacing.sm),
                    Text(ctx.tr('import_design')),
                  ],
                ),
              ),
            ],
          ),
          TextButton.icon(
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(context.tr('preview')),
            onPressed: vm.blocks.isEmpty
                ? null
                : () => _openPreview(context, vm),
          ),
        ],
      ),
    );
  }

  void _exportDesignJson(BuildContext context, WysiwygDesignViewModel vm) {
    Clipboard.setData(ClipboardData(text: _encodeDesignJson(vm)));
    Notify.success(context, context.tr('copied_to_clipboard'));
  }

  /// Phase 8e: write the design JSON to a file the user picks. Filename
  /// `invoice-design-{epoch-ms}.json` mirrors React's
  /// `InvoiceBuilder.tsx` Blob anchor. `FilePicker.saveFile` handles
  /// both desktop (path returned, write defensively) and web (the
  /// package shim downloads via a Blob anchor when `bytes:` is passed).
  Future<void> _downloadDesignJson(
    BuildContext context,
    WysiwygDesignViewModel vm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = context.tr;
    final json = _encodeDesignJson(vm);
    final bytes = Uint8List.fromList(utf8.encode(json));
    final name = 'invoice-design-${DateTime.now().millisecondsSinceEpoch}.json';
    try {
      final path = await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
      );
      if (path == null) return;
      // Desktop returns a path without writing; web writes via `bytes`
      // and may return a synthesized URL. Native: write defensively.
      if (!kIsWeb) {
        final file = File(path);
        if (!await file.exists() || await file.length() == 0) {
          await file.writeAsBytes(bytes);
        }
      }
      messenger.showSnackBar(SnackBar(content: Text(tr('exported'))));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr('an_error_occurred'))),
      );
    }
  }

  String _encodeDesignJson(WysiwygDesignViewModel vm) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(vm.draft.toApiJson(preserveTempId: false));
  }

  /// Phase 8k: import a design JSON payload into the **current** draft
  /// (replaces blocks + documentSettings). When the draft is non-empty
  /// we confirm first since this is destructive. Mirrors React
  /// `InvoiceBuilder.tsx` Import JSON.
  Future<void> _importDesignJson(
    BuildContext context,
    WysiwygDesignViewModel vm,
  ) async {
    // Confirm before overwriting a non-empty draft.
    if (vm.blocks.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('import_design')),
          content: Text(ctx.tr('import_design_overwrite_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.tr('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.tr('replace')),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }
    final raw = await _showImportJsonDialog(context);
    if (raw == null || raw.trim().isEmpty || !context.mounted) return;
    final err = vm.importFromJson(raw);
    if (!context.mounted) return;
    if (err != null) {
      Notify.error(context, context.tr(err));
    } else {
      Notify.success(context, context.tr('imported'));
    }
  }

  /// Shared paste-JSON dialog body. The Twig editor's
  /// `_promptImportJson` keeps its own copy in `custom_designs_body.dart`;
  /// merging the two is a separate refactor.
  Future<String?> _showImportJsonDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('import_design')),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: ctx.tr('paste_design_json'),
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(ctx.tr('import')),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _openPreview(BuildContext context, WysiwygDesignViewModel vm) {
    final services = context.read<Services>();
    final service = LiveDesignService(services.apiClient);
    final isPro = services.auth.session.value?.hasProAccess ?? false;
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final pane = ListenableBuilder(
      listenable: vm,
      builder: (_, _) => WysiwygPreviewSheet(
        service: service,
        design: vm.draft,
        // Phase 8l: gate the watermark on the auth-derived flag.
        isPro: isPro,
      ),
    );
    if (isPhone) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: SafeArea(child: pane)),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        // Read MediaQuery from the sheet's own (mounted) context — not the
        // outer _TopBar context. Reading it from a foreign/defunct context is
        // the anti-pattern that crashed the old _showPaletteSheet with a
        // "Null check operator used on a null value" (Element.widget == null).
        builder: (sheetContext) => SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.8,
          child: pane,
        ),
      );
    }
  }
}

class _DesignNameField extends StatelessWidget {
  const _DesignNameField({required this.vm});
  final WysiwygDesignViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.md(context),
      ),
      child: SettingsTextField(
        labelKey: 'design_name',
        initialValue: vm.draft.name,
        onChanged: vm.setName,
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.vm});
  final WysiwygDesignViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ComponentPalette(vm: vm),
              const VerticalDivider(width: 1),
              Expanded(child: WysiwygCanvas(vm: vm)),
              const VerticalDivider(width: 1),
              PropertyPanel(vm: vm),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({required this.vm});
  final WysiwygDesignViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ComponentPalette(vm: vm),
            const VerticalDivider(width: 1),
            Expanded(child: WysiwygCanvas(vm: vm)),
          ],
        ),
        if (vm.panelMode == PropertyPanelMode.block)
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: Material(
                elevation: 8,
                child: PropertyPanel(vm: vm),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({required this.vm});
  final WysiwygDesignViewModel vm;

  @override
  Widget build(BuildContext context) {
    // Step 6: phone gets the reorder list, not the unusable 12-col canvas.
    return MobileReorderView(vm: vm);
  }
}
