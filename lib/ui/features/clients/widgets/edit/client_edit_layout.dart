import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/features/clients/view_models/client_edit_view_model.dart';
import 'package:admin/ui/features/clients/widgets/edit/client_edit_address_section.dart';
import 'package:admin/ui/features/clients/widgets/edit/client_edit_contacts_section.dart';
import 'package:admin/ui/features/clients/widgets/edit/client_edit_details_section.dart';
import 'package:admin/ui/features/clients/widgets/edit/client_edit_notes_section.dart';

/// Lays out the four edit-screen cards (Details, Address, Notes, Contacts).
///
/// ≥1100 px: two columns side-by-side — left holds Details + Address + Notes,
/// right is the Contacts card. Two equal-width columns; Contacts gets a
/// dedicated column because it grows as the user adds more.
///
/// Otherwise: single scrolling column, cards stacked top-to-bottom.
class ClientEditLayout extends StatelessWidget {
  const ClientEditLayout({super.key, required this.vm});

  final ClientEditViewModel vm;

  static const double _twoColumnBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= _twoColumnBreakpoint;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(InSpacing.lg),
          child: twoCol ? _wide(context) : _narrow(context),
        );
      },
    );
  }

  Widget _wide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClientEditDetailsSection(vm: vm),
              const SizedBox(height: InSpacing.md),
              ClientEditAddressSection(vm: vm),
              const SizedBox(height: InSpacing.md),
              ClientEditNotesSection(vm: vm),
            ],
          ),
        ),
        const SizedBox(width: InSpacing.md),
        Expanded(child: ClientEditContactsSection(vm: vm)),
      ],
    );
  }

  Widget _narrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientEditDetailsSection(vm: vm),
        const SizedBox(height: InSpacing.md),
        ClientEditAddressSection(vm: vm),
        const SizedBox(height: InSpacing.md),
        ClientEditNotesSection(vm: vm),
        const SizedBox(height: InSpacing.md),
        ClientEditContactsSection(vm: vm),
      ],
    );
  }
}
