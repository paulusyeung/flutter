import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/contact.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/clients/view_models/client_edit_view_model.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// "Contacts" card on the client edit screen. Renders every contact inline,
/// each with its own First/Last/Email/Phone block plus a header row carrying
/// the primary-toggle star and (when 2+ contacts) a delete button.
///
/// "+ Add contact" sits at the bottom of the card.
///
/// Each `_ContactEditor` is keyed by the contact's id (or list index when
/// the id is empty — fresh contacts haven't been allocated server-side yet)
/// so adding/removing siblings doesn't recycle a `TextEditingController`
/// onto a different contact's data.
class ClientEditContactsSection extends StatelessWidget {
  const ClientEditContactsSection({super.key, required this.vm});

  final ClientEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final contacts = vm.draft.contacts;
    final canDelete = contacts.length > 1;
    return DashboardCardShell(
      title: context.tr('contacts'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contacts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: InSpacing.md(context)),
              child: Text(
                context.tr('no_contacts_yet'),
                style: TextStyle(color: tokens.ink3),
              ),
            )
          else
            for (var i = 0; i < contacts.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: InSpacing.sm),
                Divider(height: 1, thickness: 1, color: tokens.border),
                const SizedBox(height: InSpacing.sm),
              ],
              _ContactEditor(
                key: ValueKey(_contactKey(contacts[i], i)),
                index: i,
                contact: contacts[i],
                canDelete: canDelete,
                onMakePrimary: () => vm.setContactPrimary(i),
                onDelete: () => vm.removeContact(i),
                onFirstName: (v) => vm.setContactFirstNameAt(i, v),
                onLastName: (v) => vm.setContactLastNameAt(i, v),
                onEmail: (v) => vm.setContactEmailAt(i, v),
                onPhone: (v) => vm.setContactPhoneAt(i, v),
                onSendEmail: (v) => vm.setContactSendEmailAt(i, v),
                onPassword: (v) => vm.setContactPasswordAt(i, v),
              ),
            ],
          SizedBox(height: InSpacing.md(context)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: vm.addContact,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: Text(context.tr('add_contact')),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accentSoft,
                foregroundColor: tokens.accentInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stable key per contact row so the editor's internal text controllers
  /// follow the contact across sibling add/remove. Real contact ids are
  /// stable; brand-new contacts (id == '') fall back to `'new_<index>'`,
  /// which is fine because new rows are only ever appended at the end.
  String _contactKey(Contact c, int index) =>
      c.id.isNotEmpty ? c.id : 'new_$index';
}

class _ContactEditor extends StatelessWidget {
  const _ContactEditor({
    super.key,
    required this.index,
    required this.contact,
    required this.canDelete,
    required this.onMakePrimary,
    required this.onDelete,
    required this.onFirstName,
    required this.onLastName,
    required this.onEmail,
    required this.onPhone,
    required this.onSendEmail,
    required this.onPassword,
  });

  final int index;
  final Contact contact;
  final bool canDelete;
  final VoidCallback onMakePrimary;
  final VoidCallback onDelete;
  final ValueChanged<String> onFirstName;
  final ValueChanged<String> onLastName;
  final ValueChanged<String> onEmail;
  final ValueChanged<String> onPhone;
  final ValueChanged<bool> onSendEmail;
  final ValueChanged<String> onPassword;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final headerLabel = contact.isPrimary
        ? context.tr('primary_contact')
        : context.tr('contact_with_index', {'index': '${index + 1}'});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: context.tr(
                contact.isPrimary ? 'primary_contact' : 'make_primary',
              ),
              onPressed: contact.isPrimary ? null : onMakePrimary,
              icon: Icon(
                contact.isPrimary ? Icons.star : Icons.star_border,
                size: 20,
                color: contact.isPrimary ? tokens.accent : tokens.ink3,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            const SizedBox(width: InSpacing.xs),
            Expanded(
              child: Text(
                headerLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.ink3,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (canDelete)
              IconButton(
                tooltip: context.tr('remove_contact'),
                onPressed: onDelete,
                icon: Icon(Icons.close, size: 18, color: tokens.overdue),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
          ],
        ),
        const SizedBox(height: InSpacing.xs),
        EntityEditField(
          label: context.tr('first_name'),
          initial: contact.firstName,
          onChanged: onFirstName,
        ),
        EntityEditField(
          label: context.tr('last_name'),
          initial: contact.lastName,
          onChanged: onLastName,
        ),
        EntityEditField(
          label: context.tr('email'),
          initial: contact.email,
          onChanged: onEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        EntityEditField(
          label: context.tr('phone'),
          initial: contact.phone,
          onChanged: onPhone,
          keyboardType: TextInputType.phone,
        ),
        EntityEditField(
          label: context.tr('password'),
          initial: contact.password,
          onChanged: onPassword,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: contact.sendEmail,
          onChanged: onSendEmail,
          title: Text(context.tr('add_to_invoices')),
        ),
      ],
    );
  }
}
