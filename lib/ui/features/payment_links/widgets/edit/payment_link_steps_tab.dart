import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/payment_links/view_models/payment_link_edit_view_model.dart';

/// Fourth tab — configurable checkout step order. Two dropdowns (auth +
/// other) feed into a single reorderable list; per-row red markers
/// surface missing dependencies computed locally from the step catalog.
/// The 300ms-debounced `/steps/check` round-trip catches server-only
/// rules.
class PaymentLinkStepsTab extends StatefulWidget {
  const PaymentLinkStepsTab({super.key, required this.vm});

  final PaymentLinkEditViewModel vm;

  @override
  State<PaymentLinkStepsTab> createState() => _PaymentLinkStepsTabState();
}

class _PaymentLinkStepsTabState extends State<PaymentLinkStepsTab> {
  @override
  void initState() {
    super.initState();
    // Lazy-load the catalog the first time the tab is shown — small JSON
    // payload, but no point firing it on edit-screen mount.
    widget.vm.loadSteps();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final catalog = vm.availableSteps;
    if (vm.stepsLoading || catalog == null) {
      return Center(child: Text(context.tr('loading_ellipsis')));
    }
    if (vm.stepsError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Text(vm.stepsError!),
        ),
      );
    }
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('order'),
          children: [
            _StepPickers(vm: vm, catalog: catalog),
            SizedBox(height: InSpacing.md(context)),
            _StepList(vm: vm, catalog: catalog),
            if (vm.serverStepErrors.isNotEmpty) ...[
              SizedBox(height: InSpacing.md(context)),
              for (final error in vm.serverStepErrors)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: InSpacing.xs),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
            SizedBox(height: InSpacing.sm),
            Text(
              context.tr('steps_order_help'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.inTheme.ink3),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepPickers extends StatelessWidget {
  const _StepPickers({required this.vm, required this.catalog});

  final PaymentLinkEditViewModel vm;
  final List<PaymentLinkStep> catalog;

  @override
  Widget build(BuildContext context) {
    final selected = vm.orderedStepIds.toSet();
    final hasAuth = selected.any((s) => s.startsWith('auth.'));
    final authOptions = catalog
        .where((s) => s.id.startsWith('auth.') && !selected.contains(s.id))
        .toList(growable: false);
    final otherOptions = catalog
        .where((s) => !s.id.startsWith('auth.') && !selected.contains(s.id))
        .toList(growable: false);
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: null,
            decoration: InputDecoration(
              labelText: context.tr('authentication'),
            ),
            // "Auth-only-one": once an auth step is in the list, hide the
            // rest. Matches React's behavior.
            items: hasAuth
                ? const <DropdownMenuItem<String>>[]
                : [
                    for (final s in authOptions)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
            onChanged: (id) {
              if (id != null) vm.addStep(id);
            },
          ),
        ),
        SizedBox(width: InSpacing.md(context)),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: null,
            decoration: InputDecoration(labelText: context.tr('other_steps')),
            items: [
              for (final s in otherOptions)
                DropdownMenuItem(value: s.id, child: Text(s.label)),
            ],
            onChanged: (id) {
              if (id != null) vm.addStep(id);
            },
          ),
        ),
      ],
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.vm, required this.catalog});

  final PaymentLinkEditViewModel vm;
  final List<PaymentLinkStep> catalog;

  @override
  Widget build(BuildContext context) {
    final ids = vm.orderedStepIds;
    if (ids.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: InSpacing.md(context)),
        child: Text('—', style: TextStyle(color: context.inTheme.ink3)),
      );
    }
    final byId = {for (final s in catalog) s.id: s};
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: ids.length,
      onReorder: vm.reorderStep,
      itemBuilder: (context, index) {
        final id = ids[index];
        final step = byId[id];
        final missingDep = vm.missingDependencyAt(index);
        return _StepRow(
          key: ValueKey(id),
          index: index,
          id: id,
          label: step?.label ?? id,
          missingDependency: missingDep,
          onRemove: () => vm.removeStep(index),
        );
      },
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.index,
    required this.id,
    required this.label,
    required this.missingDependency,
    required this.onRemove,
  });

  final int index;
  final String id;
  final String label;
  final String? missingDependency;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final hasError = missingDependency != null;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.xs),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.drag_indicator, size: 18),
            ),
          ),
          if (hasError)
            Tooltip(
              message: '${context.tr('depends_on')}: $missingDependency',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: hasError ? theme.colorScheme.error : tokens.ink,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
