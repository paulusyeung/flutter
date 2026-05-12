import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Searchable label keys rendered by this tab. See
/// `kCompanyDetailsDetailsSearchKeys` for the colocation pattern.
const kCompanyDetailsCustomFieldsSearchKeys = <String>['custom_fields'];

/// "Custom Fields" tab — editor for the four `company1..company4` slots in
/// `company.custom_fields`. Each slot is stored on the server as
/// `"<label>|<type>"`; this UI splits and rejoins around the pipe.
///
/// Field types match React's schema (`react/src/pages/settings/company/...`).
class CompanyDetailsCustomFieldsScreen extends StatelessWidget {
  const CompanyDetailsCustomFieldsScreen({super.key});

  static const _types = [
    ('', 'single_line_text'),
    ('multi_line_text', 'multi_line_text'),
    ('switch', 'switch'),
    ('date', 'date'),
    ('dropdown', 'dropdown'),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    if (vm.draft == null) return const SizedBox.shrink();
    return SettingsFormShell(
      child: FormSection(
        title: context.tr('custom_fields'),
        children: [
          for (var i = 1; i <= 4; i++) ...[
            if (i > 1) const SizedBox(height: InSpacing.lg),
            _Row(key: ValueKey('company$i'), slot: i),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({super.key, required this.slot});
  final int slot;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  late final TextEditingController _label;

  @override
  void initState() {
    super.initState();
    final vm = context.read<CompanyDetailsViewModel>();
    _label = TextEditingController(text: _currentLabel(vm));
  }

  String _currentLabel(CompanyDetailsViewModel vm) {
    final raw = vm.draft?.customFields['company${widget.slot}'] ?? '';
    return raw.split('|').first;
  }

  String _currentType(CompanyDetailsViewModel vm) {
    final raw = vm.draft?.customFields['company${widget.slot}'] ?? '';
    final parts = raw.split('|');
    return parts.length > 1 ? parts[1] : '';
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _write(CompanyDetailsViewModel vm, {String? label, String? type}) {
    final key = 'company${widget.slot}';
    final draft = vm.draft;
    if (draft == null) return;
    final next = Map<String, String>.from(draft.customFields);
    final newLabel = label ?? _label.text;
    final newType = type ?? _currentType(vm);
    if (newLabel.isEmpty && newType.isEmpty) {
      next.remove(key);
    } else {
      next[key] = newType.isEmpty ? newLabel : '$newLabel|$newType';
    }
    vm.updateCompany((c) => c.copyWith(customFields: next));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final type = _currentType(vm);

    final labelField = TextField(
      controller: _label,
      decoration: InputDecoration(
        labelText: '${context.tr('label')} ${widget.slot}',
      ),
      onChanged: (v) => _write(vm, label: v),
    );
    final typeField = DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: context.tr('field_type')),
      initialValue:
          CompanyDetailsCustomFieldsScreen._types.any((t) => t.$1 == type)
          ? type
          : '',
      items: [
        for (final t in CompanyDetailsCustomFieldsScreen._types)
          DropdownMenuItem(value: t.$1, child: Text(context.tr(t.$2))),
      ],
      onChanged: (v) => _write(vm, type: v ?? ''),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // On narrow viewports the side-by-side label + dropdown squashes
        // both fields. Stacked vertically reads cleaner.
        if (!Breakpoints.isWide(constraints)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              labelField,
              const SizedBox(height: InSpacing.sm),
              typeField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: labelField),
            const SizedBox(width: InSpacing.md),
            Expanded(child: typeField),
          ],
        );
      },
    );
  }
}
