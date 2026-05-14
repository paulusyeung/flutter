import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/projects/view_models/project_edit_view_model.dart';
import 'package:admin/ui/features/projects/widgets/edit/color_field.dart';

/// Identity + client + assignment + due date + color. Always rendered.
class ProjectEditDetailsSection extends StatelessWidget {
  const ProjectEditDetailsSection({super.key, required this.vm});
  final ProjectEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      title: context.tr('details'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EntityEditField(
            label: context.tr('name'),
            initial: vm.draft.name,
            onChanged: vm.setName,
            autofocus: vm.isCreate,
            errorText: vm.fieldErrorFor('name'),
          ),
          // Number is server-assigned on first save and immutable afterwards
          // (the server owns the sequence; allowing edits can collide).
          // Surfaced read-only on existing projects so users can copy it.
          if (!vm.isCreate)
            EntityEditField(
              label: context.tr('number'),
              initial: vm.draft.number,
              onChanged: (_) {},
              readOnly: true,
            ),
          _ClientPicker(vm: vm),
          _DueDateField(vm: vm),
          ColorField(initial: vm.draft.color, onChanged: vm.setColor),
        ],
      ),
    );
  }
}

/// Searchable client picker for new projects; locked tap-to-navigate row
/// once the project exists (matches React's `ClientActionButtons`).
class _ClientPicker extends StatelessWidget {
  const _ClientPicker({required this.vm});
  final ProjectEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    if (!vm.isCreate) {
      return _LockedClientRow(
        clientId: vm.draft.clientId,
        companyId: companyId,
      );
    }
    return StreamBuilder<List<Client>>(
      stream: services.clients.watchPage(
        companyId: companyId,
        loadedPages: 100,
      ),
      builder: (context, snapshot) {
        final clients = snapshot.data ?? const <Client>[];
        Client? selected;
        for (final c in clients) {
          if (c.id == vm.draft.clientId) {
            selected = c;
            break;
          }
        }
        return SearchableDropdownField<Client>(
          label: context.tr('client'),
          items: clients,
          initialValue: selected,
          displayString: (c) => c.displayName.isEmpty
              ? (c.name.isEmpty ? c.id : c.name)
              : c.displayName,
          idOf: (c) => c.id,
          onChanged: (c) => vm.setClientId(c?.id ?? ''),
          errorText: vm.fieldErrorFor('client_id'),
        );
      },
    );
  }
}

/// Renders the client picker as a read-only InputDecorator-wrapped row
/// matching the surrounding [EntityEditField] chrome — outlined border,
/// floating label, lock-icon suffix to signal the field is server-bound.
/// Tap navigates to the linked client.
class _LockedClientRow extends StatelessWidget {
  const _LockedClientRow({required this.clientId, required this.companyId});
  final String clientId;
  final String companyId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final tokens = context.inTheme;
    final me = services.auth.session.value?.currentCompany;
    final canView = me?.can('view_client') ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: canView && clientId.isNotEmpty
            ? () => context.go('/clients/$clientId')
            : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: context.tr('client'),
            suffixIcon: Icon(Icons.lock_outline, size: 18, color: tokens.ink3),
          ),
          child: StreamBuilder<Client?>(
            stream: services.clients.watch(companyId: companyId, id: clientId),
            builder: (context, snap) {
              final c = snap.data;
              final name = c == null
                  ? clientId
                  : (c.displayName.isNotEmpty
                        ? c.displayName
                        : (c.name.isEmpty ? clientId : c.name));
              return Text(name, style: TextStyle(color: tokens.ink));
            },
          ),
        ),
      ),
    );
  }
}

/// Simple date picker for the due date. Tap → showDatePicker.
class _DueDateField extends StatelessWidget {
  const _DueDateField({required this.vm});
  final ProjectEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final value = vm.draft.dueDate;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final initial = value == null
              ? now
              : DateTime(value.year, value.month, value.day);
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 10),
          );
          if (picked != null) {
            vm.setDueDate(Date(picked.year, picked.month, picked.day));
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: context.tr('due_date'),
            suffixIcon: value == null
                ? const Icon(Icons.event)
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => vm.setDueDate(null),
                  ),
          ),
          // Locale-aware medium date (`Jan 5, 2026`). Threading the
          // company-aware `Formatter.date` through the edit form is a
          // separate refactor — for now we match the list-cell behavior.
          child: Text(
            value == null
                ? ''
                : DateFormat.yMMMd(
                    Localizations.localeOf(context).toString(),
                  ).format(value.toDateTime()),
            style: TextStyle(color: tokens.ink),
          ),
        ),
      ),
    );
  }
}
