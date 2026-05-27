import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/static/built_in_designs_catalog.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/design_edit_screen.dart';

/// Custom Designs tab body — second tab on the Invoice Design shell
/// (`/settings/invoice_design/custom_designs`).
///
/// Lists Built-in / Custom buckets. Tapping a custom row opens
/// [DesignEditScreen] for full create / edit / delete (the entity stack,
/// outbox wiring, and password gate live in [DesignRepository]); built-in
/// and template rows open the read-only [_DesignDetailScreen] since their
/// HTML isn't user-editable.
///
/// Self-contained — reads `Services` off Provider, doesn't bind to the
/// cascade VM. The tab is registered with `contributesToSave: false` so the
/// shell's Save button hides while it's active.
class CustomDesignsBody extends StatelessWidget {
  const CustomDesignsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    return StreamBuilder<List<Design>>(
      stream: companyId == null
          ? const Stream.empty()
          : services.designs.watchAll(companyId: companyId),
      builder: (context, snapshot) {
        final bundled = snapshot.data ?? const <Design>[];
        return _DesignsListView(bundled: bundled);
      },
    );
  }
}

/// Open the full design create/edit screen. Modal sub-flow (not page
/// navigation) — see the routing rule in `docs/architecture.md` § Navigation.
Future<void> showDesignEditScreen(
  BuildContext context, {
  String? existingId,
  Design? seedFrom,
  String? importJson,
  bool startInHtml = false,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DesignEditScreen(
        existingId: existingId,
        seedFrom: seedFrom,
        importJson: importJson,
        startInHtml: startInHtml,
      ),
    ),
  );
}

/// Open the read-only design detail screen (template rows, which are not
/// editable entities). Modal sub-flow — see `docs/architecture.md`.
Future<void> showDesignDetailScreen(BuildContext context, Design design) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _DesignDetailScreen(design: design),
    ),
  );
}

/// Entry chooser. Leads with the code-free path (duplicate a built-in /
/// recolor) and keeps raw HTML authoring + JSON import as secondary options.
Future<void> _showNewDesignChooser(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(ctx.tr('new_design')),
      children: [
        ListTile(
          leading: const Icon(Icons.dashboard_customize_outlined),
          title: Text(ctx.tr('duplicate_a_builtin')),
          subtitle: Text(ctx.tr('duplicate_a_builtin_hint')),
          onTap: () {
            Navigator.of(ctx).pop();
            showDesignEditScreen(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text(ctx.tr('edit_the_html')),
          subtitle: Text(ctx.tr('edit_the_html_hint')),
          onTap: () {
            Navigator.of(ctx).pop();
            showDesignEditScreen(context, startInHtml: true);
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: Text(ctx.tr('import_design')),
          subtitle: Text(ctx.tr('import_design_hint')),
          onTap: () async {
            Navigator.of(ctx).pop();
            await _promptImportJson(context);
          },
        ),
      ],
    ),
  );
}

Future<void> _promptImportJson(BuildContext context) async {
  final controller = TextEditingController();
  try {
    final json = await showDialog<String>(
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
    );
    if (json == null || json.trim().isEmpty || !context.mounted) return;
    unawaited(showDesignEditScreen(context, importJson: json));
  } finally {
    controller.dispose();
  }
}

Future<void> _exportDesign(BuildContext context, Design design) async {
  const encoder = JsonEncoder.withIndent('  ');
  await Clipboard.setData(
    ClipboardData(text: encoder.convert(design.toApiJson())),
  );
  if (!context.mounted) return;
  Notify.success(context, context.tr('copied_to_clipboard'));
}

class _DesignsListView extends StatelessWidget {
  const _DesignsListView({required this.bundled});

  final List<Design> bundled;

  @override
  Widget build(BuildContext context) {
    // Merge bundled with the static built-in catalog so the screen renders
    // before /refresh delivers the first envelope. Bundled rows win on id
    // collision (the server is authoritative).
    final byId = <String, _Row>{};
    for (final d in kBuiltInDesigns) {
      byId[d.id] = _Row.builtIn(d.id, d.name, d.isFree);
    }
    for (final d in bundled) {
      byId[d.id] = _Row.fromDomain(d);
    }
    final rows = byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    final builtIn = rows.where((r) => !r.isCustom).toList();
    final custom = rows.where((r) => r.isCustom).toList();

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.md(context),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(bottom: InSpacing.md(context)),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 44),
              ),
              onPressed: () => _showNewDesignChooser(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.tr('new_design')),
            ),
          ),
        ),
        if (custom.isNotEmpty) ...[
          _SectionHeader(label: context.tr('custom_designs')),
          for (final r in custom) _DesignTile(row: r),
          SizedBox(height: InSpacing.lg(context)),
        ],
        _SectionHeader(label: context.tr('built_in')),
        for (final r in builtIn) _DesignTile(row: r),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: InSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: context.inTheme.ink2,
        ),
      ),
    );
  }
}

class _DesignTile extends StatelessWidget {
  const _DesignTile({required this.row});

  final _Row row;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(row.name),
        subtitle: row.entities.isEmpty
            ? null
            : Text(
                row.entities.join(' · '),
                style: TextStyle(color: context.inTheme.ink3),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (row.isTemplate)
              _Pill(label: context.tr('template'), tone: _PillTone.neutral),
            if (!row.isCustom && !row.isFree)
              _Pill(label: context.tr('pro_plan'), tone: _PillTone.accent),
            if (row.design != null)
              PopupMenuButton<String>(
                tooltip: '',
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'copy',
                    child: Text(ctx.tr('edit_a_copy')),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Text(ctx.tr('export_design')),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'copy') {
                    showDesignEditScreen(context, seedFrom: row.design);
                  } else if (v == 'export') {
                    unawaited(_exportDesign(context, row.design!));
                  }
                },
              )
            else
              const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: row.isCustom
            ? () => showDesignEditScreen(context, existingId: row.id)
            : row.design == null
            ? null
            : () => showDesignDetailScreen(context, row.design!),
      ),
    );
  }
}

class _DesignDetailScreen extends StatelessWidget {
  const _DesignDetailScreen({required this.design});

  final Design design;

  @override
  Widget build(BuildContext context) {
    final sections = <(String, String)>[
      ('body', design.template.body),
      ('header', design.template.header),
      ('footer', design.template.footer),
      ('includes', design.template.includes),
      ('product', design.template.product),
      ('task', design.template.task),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(design.name),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              showDesignEditScreen(context, seedFrom: design);
            },
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: Text(context.tr('edit_a_copy')),
          ),
          IconButton(
            tooltip: context.tr('export_design'),
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => unawaited(_exportDesign(context, design)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(InSpacing.lg(context)),
        children: [
          if (design.entities.isNotEmpty)
            _MetaRow(
              label: context.tr('entities'),
              value: design.entities.join(', '),
            ),
          _MetaRow(
            label: context.tr('type'),
            value: design.isCustom
                ? context.tr('custom')
                : context.tr('built_in'),
          ),
          if (design.isTemplate)
            _MetaRow(
              label: context.tr('template'),
              value: context.tr('yes'),
            ),
          SizedBox(height: InSpacing.lg(context)),
          for (final s in sections)
            if (s.$2.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(context.tr(s.$1)),
                  childrenPadding: const EdgeInsets.all(12),
                  children: [
                    SelectableText(
                      s.$2,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: context.inTheme.ink3),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

enum _PillTone { neutral, accent }

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.tone});

  final String label;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final bg = tone == _PillTone.accent ? tokens.accentSoft : tokens.surfaceAlt;
    final fg = tone == _PillTone.accent ? tokens.accent : tokens.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11),
      ),
    );
  }
}

/// Lightweight projection used for the merged built-in + bundled list. Holds
/// a [Design] reference when the row came from the bundle (so the detail
/// screen has the full template HTML) and is null for the pure-static
/// built-in catalog entries (no template HTML on hand until the bundle lands).
class _Row {
  const _Row({
    required this.id,
    required this.name,
    required this.entities,
    required this.isCustom,
    required this.isTemplate,
    required this.isFree,
    required this.design,
  });

  factory _Row.builtIn(String id, String name, bool isFree) => _Row(
    id: id,
    name: name,
    entities: const <String>[],
    isCustom: false,
    isTemplate: false,
    isFree: isFree,
    design: null,
  );

  factory _Row.fromDomain(Design d) => _Row(
    id: d.id,
    name: d.name,
    entities: d.entities,
    isCustom: d.isCustom,
    isTemplate: d.isTemplate,
    isFree: d.isFree,
    design: d,
  );

  final String id;
  final String name;
  final List<String> entities;
  final bool isCustom;
  final bool isTemplate;
  final bool isFree;
  final Design? design;
}
