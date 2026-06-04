import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/portal_constants.dart';
import 'package:admin/data/models/api/client_registration_field_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Hidden / Optional / Required matrix for the twenty Client Portal
/// registration form fields. Each row writes through
/// `host.updateCompany((c) => c.copyWith(clientRegistrationFields: ...))`.
///
/// Fields the server hasn't sent default to (`visible: false`, `required: false`)
/// — matches React's behavior where missing entries render as "Hidden".
class RegistrationFieldsConfigurator extends StatelessWidget {
  const RegistrationFieldsConfigurator({super.key});

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final draft = host.draft;
    final current = draft?.clientRegistrationFields ?? const [];
    final byKey = {for (final f in current) f.key: f};
    return Column(
      children: [
        for (final key in kClientRegistrationFieldKeys)
          Padding(
            padding: EdgeInsets.symmetric(vertical: InSpacing.xs),
            child: _Row(
              fieldKey: key,
              current: byKey[key],
              onChanged: (next) => _apply(host, current, key, next),
            ),
          ),
      ],
    );
  }

  void _apply(
    SettingsDraftHost host,
    List<ClientRegistrationFieldApi> existing,
    String key,
    _FieldChoice choice,
  ) {
    final updated = ClientRegistrationFieldApi(
      key: key,
      visible: choice != _FieldChoice.hidden,
      required: choice == _FieldChoice.required,
    );
    final index = existing.indexWhere((f) => f.key == key);
    final next = index < 0
        ? [...existing, updated]
        : [
            for (var i = 0; i < existing.length; i++)
              if (i == index) updated else existing[i],
          ];
    host.updateCompany((c) => c.copyWith(clientRegistrationFields: next));
  }
}

enum _FieldChoice { hidden, optional, required }

class _Row extends StatelessWidget {
  const _Row({
    required this.fieldKey,
    required this.current,
    required this.onChanged,
  });

  final String fieldKey;
  final ClientRegistrationFieldApi? current;
  final ValueChanged<_FieldChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _choiceFor(current);
    return Row(
      children: [
        Expanded(
          child: Text(
            context.tr(fieldKey),
            style: Theme.of(context).textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<_FieldChoice>(
            initialValue: selected,
            isDense: true,
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: _FieldChoice.hidden,
                child: Text(context.tr('hidden')),
              ),
              DropdownMenuItem(
                value: _FieldChoice.optional,
                child: Text(context.tr('optional')),
              ),
              DropdownMenuItem(
                value: _FieldChoice.required,
                child: Text(context.tr('required')),
              ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  _FieldChoice _choiceFor(ClientRegistrationFieldApi? f) {
    if (f == null || !f.visible) return _FieldChoice.hidden;
    return f.required ? _FieldChoice.required : _FieldChoice.optional;
  }
}
