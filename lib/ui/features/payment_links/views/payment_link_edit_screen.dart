import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/payment_link.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/payment_links/view_models/payment_link_edit_view_model.dart';
import 'package:admin/ui/features/payment_links/widgets/edit/payment_link_overview_tab.dart';
import 'package:admin/ui/features/payment_links/widgets/edit/payment_link_settings_tab.dart';
import 'package:admin/ui/features/payment_links/widgets/edit/payment_link_steps_tab.dart';
import 'package:admin/ui/features/payment_links/widgets/edit/payment_link_webhook_tab.dart';

/// Labels surfaced on the edit screen for the in-app settings search index.
const kPaymentLinkEditSearchKeys = <String>[
  'overview',
  'settings',
  'webhook',
  'order',
  'authentication',
  'other_steps',
  'webhook_url',
  'rest_method',
  'header_key',
  'header_value',
  'frequency',
  'remaining_cycles',
  'auto_bill',
  'promo_code',
  'promo_discount',
  'allow_cancellation',
  'refund_period',
  'trial_enabled',
  'trial_duration',
  'per_seat_enabled',
  'max_seats_limit',
];

/// Edit + Create form for a Payment Link. Four tabs (Overview,
/// Settings, Webhook, Steps). Tabs are precedented by the gateway edit
/// screen — `/settings/...` settings entities with logically-disjoint
/// zones consistently use this shape.
class PaymentLinkEditScreen extends StatelessWidget {
  const PaymentLinkEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;
  final PaymentLink? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<PaymentLink, PaymentLinkEditViewModel>(
      existingId: existingId,
      entityTypeName: 'payment_link',
      fetchExisting: (ctx, services, companyId, id) =>
          services.paymentLinks.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) =>
          PaymentLinkEditViewModel(
            repo: services.paymentLinks,
            companyId: companyId,
            existing: existing,
            cloneFrom: cloneFrom,
          ),
      titleWhileLoading: (ctx) => existingId == null
          ? ctx.tr('new_payment_link')
          : ctx.tr('edit_payment_link'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_payment_link')
          : (vm.draft.name.isNotEmpty
                ? '${ctx.tr('edit_payment_link')} · ${vm.draft.name}'
                : ctx.tr('edit_payment_link')),
      canSave: (vm) =>
          !vm.isSaving && vm.isDirty && vm.draft.name.trim().isNotEmpty,
      bodyBuilder: (ctx, vm) => _PaymentLinkEditBody(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (s) => s.id,
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/settings/payment_links/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}

class _PaymentLinkEditBody extends StatefulWidget {
  const _PaymentLinkEditBody({required this.vm});

  final PaymentLinkEditViewModel vm;

  @override
  State<_PaymentLinkEditBody> createState() => _PaymentLinkEditBodyState();
}

class _PaymentLinkEditBodyState extends State<_PaymentLinkEditBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.vm,
      builder: (context, _) {
        final tokens = context.inTheme;
        return Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelColor: tokens.ink,
              unselectedLabelColor: tokens.ink3,
              indicatorColor: tokens.accent,
              indicatorWeight: 2,
              tabs: [
                Tab(text: context.tr('overview')),
                Tab(text: context.tr('settings')),
                Tab(text: context.tr('webhook')),
                Tab(text: context.tr('steps')),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  PaymentLinkOverviewTab(vm: widget.vm),
                  PaymentLinkSettingsTab(vm: widget.vm),
                  PaymentLinkWebhookTab(vm: widget.vm),
                  PaymentLinkStepsTab(vm: widget.vm),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
