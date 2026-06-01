import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/product_settings_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_company_scoped_host.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';

/// Searchable label keys rendered by this screen. Aggregated into
/// `kSettingsSearchCatalog['product_settings']` so the in-app search surfaces
/// these fields. Keep in sync when adding or removing a field below — the
/// `search_catalog_consistency_test` verifies every key here appears as a
/// `context.tr('…')` reference in this file.
const kProductSettingsSearchKeys = <String>[
  'track_inventory',
  'stock_notifications',
  'notification_threshold',
  'show_product_discount',
  'show_product_cost',
  'show_product_quantity',
  'default_quantity',
  'show_product_description',
  'fill_products',
  'update_products',
  'convert_products',
  'convert_to',
];

/// Settings → Product Settings. Company-only page that writes 12 top-level
/// `company.*` fields. Mirrors the legacy admin-portal page with two UX
/// refinements: the Notification Threshold and Convert To dropdown are
/// conditionally revealed under their parent toggles, and visually nested
/// via a leading indent so the parent/child relationship reads at a glance.
///
/// All 12 fields are top-level on the Company API (not `company.settings.*`);
/// edits flow through `vm.updateCompany((c) => c.copyWith(...))`.
class ProductSettingsScreen extends StatelessWidget {
  const ProductSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return SettingsCompanyScopedHost<ProductSettingsViewModel>(
      create: (companyId) {
        final vm = ProductSettingsViewModel(
          repo: services.company,
          companyId: companyId,
        );
        unawaited(vm.load());
        return vm;
      },
      builder: (context, vm) => SettingsPageScaffold<ProductSettingsViewModel>(
        titleKey: 'product_settings',
        viewModel: vm,
        body: const _ProductSettingsBody(),
      ),
    );
  }
}

class _ProductSettingsBody extends StatelessWidget {
  const _ProductSettingsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductSettingsViewModel>();
    final draft = vm.draft;
    if (draft == null) return const SizedBox.shrink();

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('settings'),
          spacing: 0,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('track_inventory')),
              subtitle: Text(context.tr('track_inventory_help')),
              value: draft.trackInventory,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(trackInventory: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('stock_notifications')),
              subtitle: Text(context.tr('stock_notifications_help')),
              value: draft.stockNotification,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(stockNotification: v)),
            ),
            if (draft.stockNotification)
              _NestedChild(child: _ThresholdField(vm: vm)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('show_product_discount')),
              subtitle: Text(context.tr('show_product_discount_help')),
              value: draft.enableProductDiscount,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(enableProductDiscount: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('show_product_cost')),
              subtitle: Text(context.tr('show_cost_help')),
              value: draft.enableProductCost,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(enableProductCost: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('show_product_quantity')),
              subtitle: Text(context.tr('show_product_quantity_help')),
              value: draft.enableProductQuantity,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(enableProductQuantity: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('default_quantity')),
              subtitle: Text(context.tr('default_quantity_help')),
              value: draft.defaultQuantity,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(defaultQuantity: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('show_product_description')),
              subtitle: Text(context.tr('show_product_description_help')),
              value: draft.showProductDetails,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(showProductDetails: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('fill_products')),
              subtitle: Text(context.tr('fill_products_help')),
              value: draft.fillProducts,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(fillProducts: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('update_products')),
              subtitle: Text(context.tr('update_products_help')),
              value: draft.updateProducts,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(updateProducts: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('convert_products')),
              subtitle: Text(context.tr('convert_products_help')),
              value: draft.convertProducts,
              onChanged: (v) =>
                  vm.updateCompany((c) => c.copyWith(convertProducts: v)),
            ),
            if (draft.convertProducts)
              _NestedChild(child: _ConvertToDropdown(vm: vm)),
          ],
        ),
      ],
    );
  }
}

/// Indents conditional children under their parent toggle so the
/// parent/child relationship reads at a glance.
class _NestedChild extends StatelessWidget {
  const _NestedChild({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: InSpacing.lg(context),
        bottom: InSpacing.md(context),
      ),
      child: child,
    );
  }
}

/// Inventory notification threshold input. Stateful so the controller is the
/// source of truth while the user is typing — the VM is the sink. Empty-for-zero
/// rendering so a fresh page doesn't show a meaningless "0".
class _ThresholdField extends StatefulWidget {
  const _ThresholdField({required this.vm});

  final ProductSettingsViewModel vm;

  @override
  State<_ThresholdField> createState() => _ThresholdFieldState();
}

class _ThresholdFieldState extends State<_ThresholdField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.vm.draft?.inventoryNotificationThreshold ?? 0;
    _controller = TextEditingController(text: initial == 0 ? '' : '$initial');
  }

  @override
  void didUpdateWidget(_ThresholdField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resync the controller when the draft value diverges from what the
    // user has typed — covers Discard guard reset and server-driven refresh
    // that lands a new value while the page is open. Comparing parsed ints
    // (not raw strings) leaves an in-progress keystroke alone: while the
    // user is typing "50", controller text and draft both parse to 50, so
    // no resync fires and the cursor stays put.
    final current = widget.vm.draft?.inventoryNotificationThreshold ?? 0;
    final parsed = int.tryParse(_controller.text) ?? 0;
    if (parsed != current) {
      _controller.text = current == 0 ? '' : '$current';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: context.tr('notification_threshold'),
      ),
      onChanged: (value) {
        final parsed = int.tryParse(value) ?? 0;
        widget.vm.updateCompany(
          (c) => c.copyWith(inventoryNotificationThreshold: parsed),
        );
      },
    );
  }
}

/// Convert To dropdown — true → client currency, false → company currency.
/// Conditional on `convert_products` so the value isn't editable when the
/// surrounding feature is disabled.
class _ConvertToDropdown extends StatelessWidget {
  const _ConvertToDropdown({required this.vm});

  final ProductSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final value = vm.draft?.convertRateToClient ?? false;
    return DropdownButtonFormField<bool>(
      key: ValueKey('convert-to-$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: context.tr('convert_to')),
      items: [
        DropdownMenuItem(
          value: true,
          child: Text(context.tr('client_currency')),
        ),
        DropdownMenuItem(
          value: false,
          child: Text(context.tr('company_currency')),
        ),
      ],
      onChanged: (v) {
        if (v == null) return;
        vm.updateCompany((c) => c.copyWith(convertRateToClient: v));
      },
    );
  }
}
