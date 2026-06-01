import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/models/value/payment_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/in_date_field.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/payments/view_models/payment_edit_view_model.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/payments/widgets/edit/payment_allocations_footer.dart';
import 'package:admin/ui/features/payments/widgets/edit/payment_allocations_section.dart';
import 'package:admin/utils/formatting.dart';

/// Edit + create form body for a Payment. Single-column layout, four
/// sections: Identity (client + number + date + amount + currency), Payment
/// metadata (type + transaction reference + gateway), Notes, Custom fields.
///
/// Client / Currency / Payment Type / Gateway use [SearchableDropdownField]
/// per CLAUDE.md § Forms — these are the long-list bindings the user shouldn't
/// have to memorize ids for. Mirrors `expense_edit_identity_section.dart`
/// for the picker pattern.
class PaymentEditLayout extends StatefulWidget {
  const PaymentEditLayout({super.key, required this.vm});

  final PaymentEditViewModel vm;

  @override
  State<PaymentEditLayout> createState() => _PaymentEditLayoutState();
}

class _PaymentEditLayoutState extends State<PaymentEditLayout>
    with FormatterHostMixin {
  @override
  void initState() {
    super.initState();
    // Load once; cached in `formatter` on this State so currency strings
    // can render `$1,234.50` instead of raw `Decimal.toString()`.
    loadFormatter(context.read<Services>(), widget.vm.companyId);
  }

  PaymentEditViewModel get vm => widget.vm;

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
              if (vm.isCreate) ...[
                SizedBox(height: InSpacing.lg(context)),
                PaymentAllocationsSection(
                  kind: AllocationKind.invoice,
                  paymentables: vm.draft.paymentables,
                  clientId: vm.draft.clientId,
                  paymentAmount: vm.draft.amount,
                  onChanged: vm.replacePaymentables,
                  formatter: formatter,
                ),
                SizedBox(height: InSpacing.lg(context)),
                _CreditsSectionGate(vm: vm, formatter: formatter),
                SizedBox(height: InSpacing.md(context)),
                PaymentAllocationsFooter(vm: vm, formatter: formatter),
              ],
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
          onChanged: (dt) =>
              vm.setDate(dt == null ? null : Date(dt.year, dt.month, dt.day)),
        ),
        const SizedBox(height: 12),
        // Controller-based so the auto-sync from allocations
        // (`PaymentEditViewModel.replacePaymentables`) actually updates
        // the visible text. `TextFormField(initialValue: …)` only consumes
        // its seed on first build, which would freeze this field at zero
        // while `draft.amount` drifts upward as the user picks invoices.
        _AmountField(vm: vm),
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
          onChanged: (c) => _onClientChanged(context, c),
          errorText: vm.fieldErrorFor('client_id'),
        );
      },
    );
  }

  Future<void> _onClientChanged(BuildContext context, Client? next) async {
    final nextId = next?.id ?? '';
    if (nextId == vm.draft.clientId) return;
    // If the user has already allocated paymentables, switching client
    // would orphan them. Confirm first.
    if (vm.draft.paymentables.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('change_client')),
          content: Text(ctx.tr('change_client_clears_allocations')),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(ctx.tr('cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(ctx.tr('continue_label')),
                ),
              ],
            ),
          ],
        ),
      );
      if (ok != true) return;
      vm.replaceClientAndClearPaymentables(nextId);
    } else {
      vm.setClientId(nextId);
    }
    // Seed the payment currency from the client when the form hasn't
    // picked one yet — mirrors admin-portal's behavior.
    if (next != null && vm.draft.currencyId.isEmpty) {
      vm.setCurrencyId(next.currencyId);
    }
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

class _CreditsSectionGate extends StatefulWidget {
  const _CreditsSectionGate({required this.vm, required this.formatter});
  final PaymentEditViewModel vm;
  final Formatter? formatter;

  @override
  State<_CreditsSectionGate> createState() => _CreditsSectionGateState();
}

class _CreditsSectionGateState extends State<_CreditsSectionGate> {
  // Memoize the company watch — without this the StreamBuilder cancels +
  // resubscribes on every parent rebuild (every amount keystroke flows
  // through `vm.notifyListeners()` and rebuilds this whole subtree).
  Stream<Company?>? _stream;

  Stream<Company?> _resolveStream(BuildContext context) {
    if (_stream != null) return _stream!;
    final services = context.read<Services>();
    return _stream = services.company.watchCompany(widget.vm.companyId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Company?>(
      stream: _resolveStream(context),
      builder: (context, snapshot) {
        final company = snapshot.data;
        if (company == null) return const SizedBox.shrink();
        if (!isModuleEnabled(company.enabledModules, EnabledModule.credits)) {
          return const SizedBox.shrink();
        }
        return PaymentAllocationsSection(
          kind: AllocationKind.credit,
          paymentables: widget.vm.draft.paymentables,
          clientId: widget.vm.draft.clientId,
          paymentAmount: widget.vm.draft.amount,
          onChanged: widget.vm.replacePaymentables,
          formatter: widget.formatter,
          // Invoices section owns the "select a client first" hint — keep
          // the credits side silent to avoid the duplicate prompt.
          showClientFirstHint: false,
        );
      },
    );
  }
}

/// Controller-backed top-form Amount input. Re-seeds from `vm.draft.amount`
/// when the external value drifts (auto-sync from allocations) without
/// stealing the user's cursor or wiping mid-keystroke text.
class _AmountField extends StatefulWidget {
  const _AmountField({required this.vm});
  final PaymentEditViewModel vm;

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: decimalInputText(widget.vm.draft.amount),
    );
    widget.vm.addListener(_onVmChanged);
  }

  void _onVmChanged() {
    // Don't fight the user's typing — only re-seed when the external
    // Decimal differs from what's parsed in the field AND the field isn't
    // focused. Compare on Decimal value so trailing-zero variants ("100"
    // vs "100.00") don't trigger a needless reseed.
    if (_focusNode.hasFocus) return;
    final external = widget.vm.draft.amount;
    final typed = Decimal.tryParse(_controller.text.trim()) ?? Decimal.zero;
    if (typed == external) return;
    final next = decimalInputText(external);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(labelText: context.tr('amount')),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.vm.setAmount,
    );
  }
}
