import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/models/value/payment_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/payments/view_models/payment_edit_view_model.dart';
import 'package:admin/utils/formatting.dart';

/// Edit + create form body for a Payment. Single-column layout, four
/// sections: Identity (client + number + date + amount + currency), Payment
/// metadata (type + transaction reference + gateway), Notes, Custom fields.
///
/// Client / Currency / Payment Type / Gateway use [SearchableDropdownField]
/// per CLAUDE.md § Forms — these are the long-list bindings the user shouldn't
/// have to memorize ids for. Mirrors `expense_edit_identity_section.dart`
/// for the picker pattern.
class PaymentEditLayout extends StatelessWidget {
  const PaymentEditLayout({super.key, required this.vm});

  final PaymentEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormSaveScope(
      onSubmit: () => vm.save(),
      enabled: !vm.isSaving,
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IdentitySection(vm: vm),
              SizedBox(height: InSpacing.lg(context)),
              _PaymentMetaSection(vm: vm),
              SizedBox(height: InSpacing.lg(context)),
              _NotesSection(vm: vm),
              SizedBox(height: InSpacing.lg(context)),
              _CustomFieldsSection(vm: vm),
              SizedBox(height: InSpacing.lg(context)),
              _emailReceiptToggle(context, vm),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.vm});
  final PaymentEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: context.tr('details'),
      children: [
        _ClientPicker(vm: vm),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: vm.draft.number,
          decoration: InputDecoration(labelText: context.tr('number')),
          onChanged: vm.setNumber,
        ),
        const SizedBox(height: 12),
        InDateField(
          labelText: context.tr('date'),
          value: vm.draft.date?.toDateTime(),
          onChanged: (dt) => vm.setDate(
            dt == null ? null : Date(dt.year, dt.month, dt.day),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: decimalInputText(vm.draft.amount),
          decoration: InputDecoration(labelText: context.tr('amount')),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: vm.setAmount,
        ),
        const SizedBox(height: 12),
        _CurrencyPicker(vm: vm),
      ],
    );
  }
}

class _PaymentMetaSection extends StatelessWidget {
  const _PaymentMetaSection({required this.vm});
  final PaymentEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: context.tr('payment'),
      children: [
        _PaymentTypePicker(vm: vm),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: vm.draft.transactionReference,
          decoration: InputDecoration(
            labelText: context.tr('transaction_reference'),
          ),
          onChanged: vm.setTransactionReference,
        ),
        const SizedBox(height: 12),
        _GatewayPicker(vm: vm),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.vm});
  final PaymentEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: context.tr('notes'),
      children: [
        TextFormField(
          initialValue: vm.draft.privateNotes,
          decoration: InputDecoration(labelText: context.tr('private_notes')),
          maxLines: 4,
          onChanged: vm.setPrivateNotes,
        ),
      ],
    );
  }
}

class _CustomFieldsSection extends StatelessWidget {
  const _CustomFieldsSection({required this.vm});
  final PaymentEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: context.tr('custom_fields'),
      children: [
        TextFormField(
          initialValue: vm.draft.customValue1,
          decoration: InputDecoration(labelText: context.tr('custom_value1')),
          onChanged: vm.setCustomValue1,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: vm.draft.customValue2,
          decoration: InputDecoration(labelText: context.tr('custom_value2')),
          onChanged: vm.setCustomValue2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: vm.draft.customValue3,
          decoration: InputDecoration(labelText: context.tr('custom_value3')),
          onChanged: vm.setCustomValue3,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: vm.draft.customValue4,
          decoration: InputDecoration(labelText: context.tr('custom_value4')),
          onChanged: vm.setCustomValue4,
        ),
      ],
    );
  }
}

class _ClientPicker extends StatelessWidget {
  const _ClientPicker({required this.vm});
  final PaymentEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<List<Client>>(
      stream: services.clients.watchPage(
        companyId: vm.companyId,
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
          onChanged: (c) {
            vm.setClientId(c?.id ?? '');
            // Seed the payment currency from the client when the form hasn't
            // picked one yet — mirrors admin-portal's behavior.
            if (c != null && vm.draft.currencyId.isEmpty) {
              vm.setCurrencyId(c.currencyId);
            }
          },
          errorText: vm.fieldErrorFor('client_id'),
        );
      },
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  const _CurrencyPicker({required this.vm});
  final PaymentEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final currencies = services.statics.currencies.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    Currency? selected;
    for (final c in currencies) {
      if (c.id == vm.draft.currencyId) {
        selected = c;
        break;
      }
    }
    return SearchableDropdownField<Currency>(
      label: context.tr('currency'),
      items: currencies,
      initialValue: selected,
      displayString: (c) => '${c.code} · ${c.name}',
      idOf: (c) => c.id,
      onChanged: (c) => vm.setCurrencyId(c?.id ?? ''),
      errorText: vm.fieldErrorFor('currency_id'),
    );
  }
}

class _PaymentTypePicker extends StatelessWidget {
  const _PaymentTypePicker({required this.vm});
  final PaymentEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final types = services.statics.paymentTypes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    PaymentType? selected;
    for (final t in types) {
      if (t.id == vm.draft.typeId) {
        selected = t;
        break;
      }
    }
    return SearchableDropdownField<PaymentType>(
      label: context.tr('type'),
      items: types,
      initialValue: selected,
      displayString: (t) => t.name.isEmpty ? t.id : t.name,
      idOf: (t) => t.id,
      onChanged: (t) => vm.setTypeId(t?.id ?? ''),
      errorText: vm.fieldErrorFor('type_id'),
    );
  }
}

class _GatewayPicker extends StatelessWidget {
  const _GatewayPicker({required this.vm});
  final PaymentEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<List<CompanyGateway>>(
      stream: services.companyGateways.watchPage(
        companyId: vm.companyId,
        loadedPages: 100,
      ),
      builder: (context, snapshot) {
        final gateways = snapshot.data ?? const <CompanyGateway>[];
        CompanyGateway? selected;
        for (final g in gateways) {
          if (g.id == vm.draft.companyGatewayId) {
            selected = g;
            break;
          }
        }
        return SearchableDropdownField<CompanyGateway>(
          label: context.tr('gateway'),
          items: gateways,
          initialValue: selected,
          displayString: (g) {
            final gw = services.statics.gateways[g.gatewayKey];
            final name = gw?.name ?? '';
            return name.isEmpty ? (g.label.isEmpty ? g.id : g.label) : name;
          },
          idOf: (g) => g.id,
          onChanged: (g) => vm.setCompanyGatewayId(g?.id ?? ''),
          errorText: vm.fieldErrorFor('company_gateway_id'),
        );
      },
    );
  }
}

Widget _emailReceiptToggle(BuildContext context, PaymentEditViewModel vm) {
  return SwitchListTile(
    title: Text(context.tr('send_email')),
    value: vm.sendEmail,
    onChanged: (v) => vm.sendEmail = v,
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: tokens.ink,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
