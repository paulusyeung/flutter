import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/user_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

const kUserDetailsNotificationsSearchKeys = <String>[
  'notifications',
  'all_events',
  'user_logged_in_notification',
  'task_assigned_notification',
  'disable_recurring_payment_notification',
  'enable_e_invoice_received_notification',
  'invoice_created',
  'invoice_sent',
  'invoice_viewed',
  'invoice_late',
  'payment_success',
  'payment_failure',
  'payment_manual',
  'quote_created',
  'quote_sent',
  'quote_viewed',
  'quote_approved',
  'quote_expired',
  'quote_rejected',
  'credit_created',
  'credit_sent',
  'credit_viewed',
  'purchase_order_created',
  'purchase_order_sent',
  'purchase_order_viewed',
  'purchase_order_accepted',
  'inventory_threshold',
];

const String _kAllNotifications = 'all_notifications';
const String _kAllUserNotifications = 'all_user_notifications';

enum _MasterMode { allRecords, ownedByUser, custom }

enum _EventMode { allRecords, ownedByUser, none }

class _EventDef {
  const _EventDef(this.code, this.labelKey);
  final String code;
  final String labelKey;
}

const List<_EventDef> _kEvents = <_EventDef>[
  _EventDef('invoice_created', 'invoice_created'),
  _EventDef('invoice_sent', 'invoice_sent'),
  _EventDef('invoice_viewed', 'invoice_viewed'),
  _EventDef('invoice_late', 'invoice_late'),
  _EventDef('payment_success', 'payment_success'),
  _EventDef('payment_failure', 'payment_failure'),
  _EventDef('payment_manual', 'payment_manual'),
  _EventDef('quote_created', 'quote_created'),
  _EventDef('quote_sent', 'quote_sent'),
  _EventDef('quote_viewed', 'quote_viewed'),
  _EventDef('quote_approved', 'quote_approved'),
  _EventDef('quote_expired', 'quote_expired'),
  _EventDef('quote_rejected', 'quote_rejected'),
  _EventDef('credit_created', 'credit_created'),
  _EventDef('credit_sent', 'credit_sent'),
  _EventDef('credit_viewed', 'credit_viewed'),
  _EventDef('purchase_order_created', 'purchase_order_created'),
  _EventDef('purchase_order_sent', 'purchase_order_sent'),
  _EventDef('purchase_order_viewed', 'purchase_order_viewed'),
  _EventDef('purchase_order_accepted', 'purchase_order_accepted'),
  _EventDef('inventory_threshold', 'inventory_threshold'),
];

class UserDetailsNotificationsScreen extends StatelessWidget {
  const UserDetailsNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserDetailsViewModel>();
    if (!vm.isLoaded || !vm.draftReady) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = vm.user;
    if (user == null) return const SizedBox.shrink();

    final settings = user.companyUserSettings;
    final email = user.notificationsEmail;
    final master = _masterFor(email);

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('notifications'),
          children: [
            _BoolRow(
              labelKey: 'user_logged_in_notification',
              value: settings.userLoggedInNotification,
              onChanged: (v) => vm.updateCompanyUserSettings(
                (s) => s.copyWith(userLoggedInNotification: v),
              ),
            ),
            _BoolRow(
              labelKey: 'task_assigned_notification',
              value: settings.taskAssignedNotification,
              onChanged: (v) => vm.updateCompanyUserSettings(
                (s) => s.copyWith(taskAssignedNotification: v),
              ),
            ),
            _BoolRow(
              labelKey: 'disable_recurring_payment_notification',
              value: settings.disableRecurringPaymentNotification,
              onChanged: (v) => vm.updateCompanyUserSettings(
                (s) => s.copyWith(disableRecurringPaymentNotification: v),
              ),
            ),
            _BoolRow(
              labelKey: 'enable_e_invoice_received_notification',
              value: settings.enableEInvoiceReceivedNotification,
              onChanged: (v) => vm.updateCompanyUserSettings(
                (s) => s.copyWith(enableEInvoiceReceivedNotification: v),
              ),
            ),
          ],
        ),
        FormSection(
          title: context.tr('notification_subscriptions'),
          children: [
            _MasterRow(
              value: master,
              onChanged: (m) => _onMasterChanged(vm, email, m),
            ),
            const Divider(height: 1),
            for (final event in _kEvents)
              _EventRow(
                labelKey: event.labelKey,
                value: _modeForEvent(email, event.code, master),
                enabled: master == _MasterMode.custom,
                onChanged: (mode) =>
                    _onEventChanged(vm, email, event.code, mode),
              ),
          ],
        ),
      ],
    );
  }

  _MasterMode _masterFor(List<String> email) {
    if (email.contains(_kAllNotifications)) return _MasterMode.allRecords;
    if (email.contains(_kAllUserNotifications)) return _MasterMode.ownedByUser;
    return _MasterMode.custom;
  }

  _EventMode _modeForEvent(
    List<String> email,
    String event,
    _MasterMode master,
  ) {
    if (master == _MasterMode.allRecords) return _EventMode.allRecords;
    if (master == _MasterMode.ownedByUser) return _EventMode.ownedByUser;
    if (email.contains('${event}_all')) return _EventMode.allRecords;
    if (email.contains('${event}_user')) return _EventMode.ownedByUser;
    return _EventMode.none;
  }

  void _onMasterChanged(
    UserDetailsViewModel vm,
    List<String> email,
    _MasterMode mode,
  ) {
    switch (mode) {
      case _MasterMode.allRecords:
        vm.setNotificationsEmail(const [_kAllNotifications]);
      case _MasterMode.ownedByUser:
        vm.setNotificationsEmail(const [_kAllUserNotifications]);
      case _MasterMode.custom:
        // Drop the master codes; keep any per-event subscriptions already
        // there (lets the user undo a master selection without losing the
        // previous custom shape).
        final keep = email
            .where(
              (code) =>
                  code != _kAllNotifications && code != _kAllUserNotifications,
            )
            .toList();
        vm.setNotificationsEmail(keep);
    }
  }

  void _onEventChanged(
    UserDetailsViewModel vm,
    List<String> email,
    String event,
    _EventMode mode,
  ) {
    final next = email
        .where((code) => code != '${event}_all' && code != '${event}_user')
        .toList();
    switch (mode) {
      case _EventMode.allRecords:
        next.add('${event}_all');
      case _EventMode.ownedByUser:
        next.add('${event}_user');
      case _EventMode.none:
        break;
    }
    vm.setNotificationsEmail(next);
  }
}

class _BoolRow extends StatelessWidget {
  const _BoolRow({
    required this.labelKey,
    required this.value,
    required this.onChanged,
  });

  final String labelKey;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(context.tr(labelKey))),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _MasterRow extends StatelessWidget {
  const _MasterRow({required this.value, required this.onChanged});

  final _MasterMode value;
  final ValueChanged<_MasterMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: InSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr('all_events'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          DropdownButton<_MasterMode>(
            value: value,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            items: [
              DropdownMenuItem(
                value: _MasterMode.allRecords,
                child: Text(context.tr('all_records')),
              ),
              DropdownMenuItem(
                value: _MasterMode.ownedByUser,
                child: Text(context.tr('owned_by_user')),
              ),
              DropdownMenuItem(
                value: _MasterMode.custom,
                child: Text(context.tr('custom')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.labelKey,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String labelKey;
  final _EventMode value;
  final bool enabled;
  final ValueChanged<_EventMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr(labelKey),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: enabled ? tokens.ink : tokens.ink3,
              ),
            ),
          ),
          DropdownButton<_EventMode>(
            value: value,
            onChanged: enabled
                ? (v) {
                    if (v != null) onChanged(v);
                  }
                : null,
            items: [
              DropdownMenuItem(
                value: _EventMode.allRecords,
                child: Text(context.tr('all_records')),
              ),
              DropdownMenuItem(
                value: _EventMode.ownedByUser,
                child: Text(context.tr('owned_by_user')),
              ),
              DropdownMenuItem(
                value: _EventMode.none,
                child: Text(context.tr('none')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
