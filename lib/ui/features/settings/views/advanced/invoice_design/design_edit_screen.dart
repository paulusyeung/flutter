import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/design_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_edit_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';

/// Create / edit a custom [Design]. Reached from the Custom Designs tab of
/// `/settings/invoice_design`. Lifecycle, AppBar, Save, and the
/// archive/restore/delete overflow are owned by
/// [SettingsEntityEditScaffold]; this widget declares the name + entities
/// fields and the six HTML template editors (body / header / footer /
/// includes / product / task).
class DesignEditScreen extends StatelessWidget {
  const DesignEditScreen({this.existingId, super.key});

  final String? existingId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.designs;

    return SettingsEntityEditScaffold<Design, DesignEditViewModel>(
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
      vmFactory: ({existing}) => DesignEditViewModel(
        repo: repo,
        companyId: companyId,
        existing: existing,
      ),
      isArchivedOf: (d) => d.archivedAt != null,
      isDeletedOf: (d) => d.isDeleted,
      // A nameless design renders as its UUID in the picker dropdowns.
      canSave: (vm) =>
          !vm.isSaving && vm.isDirty && vm.draft.name.trim().isNotEmpty,
      bodyBuilder: (context, vm) => [
        FormSection(
          title: context.tr('settings'),
          children: [
            SettingsTextField(
              initialValue: vm.draft.name,
              labelKey: 'name',
              onChanged: vm.setName,
              errorText: vm.fieldErrorFor('name'),
              externalSyncKey: vm.original?.id,
            ),
            _LoadFromExisting(vm: vm, companyId: companyId),
            _EntitiesField(vm: vm),
          ],
        ),
        _SectionEditor(
          titleKey: 'body',
          initial: vm.draft.template.body,
          onChanged: vm.setBody,
          syncKey: vm.original?.id,
        ),
        _SectionEditor(
          titleKey: 'header',
          initial: vm.draft.template.header,
          onChanged: vm.setHeader,
          syncKey: vm.original?.id,
        ),
        _SectionEditor(
          titleKey: 'footer',
          initial: vm.draft.template.footer,
          onChanged: vm.setFooter,
          syncKey: vm.original?.id,
        ),
        _SectionEditor(
          titleKey: 'includes',
          initial: vm.draft.template.includes,
          onChanged: vm.setIncludes,
          syncKey: vm.original?.id,
        ),
        _SectionEditor(
          titleKey: 'product',
          initial: vm.draft.template.product,
          onChanged: vm.setProduct,
          syncKey: vm.original?.id,
        ),
        _SectionEditor(
          titleKey: 'task',
          initial: vm.draft.template.task,
          onChanged: vm.setTask,
          syncKey: vm.original?.id,
        ),
      ],
    );
  }
}

/// Optional "duplicate / new from existing" — seeds the draft's template +
/// entities from another custom design that already carries template HTML.
/// Built-in catalog rows are excluded (their HTML only lands once the
/// `/refresh` bundle delivers it, so they'd seed an empty template).
class _LoadFromExisting extends StatelessWidget {
  const _LoadFromExisting({required this.vm, required this.companyId});

  final DesignEditViewModel vm;
  final String companyId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<List<Design>>(
      stream: services.designs.watchAll(companyId: companyId),
      builder: (context, snapshot) {
        final sources =
            (snapshot.data ?? const <Design>[])
                .where((d) => d.id != vm.draft.id)
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
        if (sources.isEmpty) return const SizedBox.shrink();
        return DropdownButtonFormField<String>(
          initialValue: null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('clone'),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final d in sources)
              DropdownMenuItem(value: d.id, child: Text(d.name)),
          ],
          onChanged: (id) {
            if (id == null) return;
            final src = sources.firstWhere((d) => d.id == id);
            vm.loadFrom(src);
          },
        );
      },
    );
  }
}

class _EntitiesField extends StatelessWidget {
  const _EntitiesField({required this.vm});

  final DesignEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('entities'),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        for (final e in DesignEditViewModel.supportedEntities)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: vm.draft.entities.contains(e),
            onChanged: (v) => vm.toggleEntity(e, v ?? false),
            title: Text(context.tr(e)),
          ),
      ],
    );
  }
}

/// One HTML template section, rendered as its own card with a full-height
/// monospace editor. Designs are raw HTML (not markdown), so this is a
/// plain multi-line `TextField` — never `MarkdownTextField`. Multi-line, so
/// Enter inserts a newline rather than submitting the form.
class _SectionEditor extends StatefulWidget {
  const _SectionEditor({
    required this.titleKey,
    required this.initial,
    required this.onChanged,
    required this.syncKey,
  });

  final String titleKey;
  final String initial;
  final ValueChanged<String> onChanged;
  final Object? syncKey;

  @override
  State<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<_SectionEditor> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(_SectionEditor old) {
    super.didUpdateWidget(old);
    // Reopening a different design (or Discard) reseeds the editor.
    if (old.syncKey != widget.syncKey && _controller.text != widget.initial) {
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
    return FormSection(
      title: context.tr(widget.titleKey),
      children: [
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          minLines: 14,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.all(InSpacing.md(context)),
          ),
        ),
      ],
    );
  }
}
