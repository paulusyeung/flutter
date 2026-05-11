import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/design_tokens.dart';
import '../../../../app/services.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'company_switcher_button.dart';
import 'sidebar_nav_item.dart';
import 'sidebar_section_header.dart';
import 'trial_footer.dart';

/// 232 px sidebar used in the wide (desktop / tablet) layout of the
/// authenticated shell. Drives off the static [_items] list — branch
/// indices match `lib/app/router.dart` (`0=Clients`, `1=Dashboard`,
/// `2=Settings`).
class InSidebar extends StatelessWidget {
  const InSidebar({
    required this.currentBranch,
    required this.onSelectBranch,
    this.width = 232,
    this.onBeforeCompanyPicker,
    super.key,
  });

  final int currentBranch;
  final ValueChanged<int> onSelectBranch;

  /// Fixed width of the sidebar. The persistent desktop rail uses the
  /// default 232 px; `AppDrawer` passes `null` so the sidebar fills the
  /// drawer's own (wider) width.
  final double? width;

  /// Fires before the company picker opens (when the user taps the
  /// switcher header). Used by `AppDrawer` to pop itself first so the
  /// picker doesn't stack on top of an open drawer.
  final VoidCallback? onBeforeCompanyPicker;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final auth = context.read<Services>().auth;
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: auth.session,
      builder: (context, session, _) {
        if (session == null) return const SizedBox.shrink();
        return Container(
          width: width,
          decoration: BoxDecoration(
            color: tokens.surface,
            border: Border(right: BorderSide(color: tokens.border)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: CompanySwitcherButton(
                  session: session,
                  onBeforeOpen: onBeforeCompanyPicker,
                ),
              ),
              Container(height: 1, color: tokens.border),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildItems(context, session.currentCompanyId),
                  ),
                ),
              ),
              const TrialFooter(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildItems(BuildContext context, String companyId) {
    final widgets = <Widget>[];
    for (final item in _items) {
      switch (item) {
        case _Section(:final label):
          widgets.add(SidebarSectionHeader(label));
        case _Nav():
          widgets.add(_buildNav(context, item, companyId));
      }
    }
    return widgets;
  }

  Widget _buildNav(BuildContext context, _Nav item, String companyId) {
    final isActive = item.branch != null && item.branch == currentBranch;
    final base = SidebarNavItem(
      label: item.label,
      icon: item.icon,
      active: isActive,
      disabled: item.disabled,
      onTap: item.branch == null ? null : () => onSelectBranch(item.branch!),
    );
    // The Clients row gets a live count badge layered on via a StreamBuilder
    // wrapper — keeps the simple SidebarNavItem ignorant of repos.
    if (item.label == 'Clients') {
      return StreamBuilder<int>(
        stream: context.read<Services>().clients.watchCount(
          companyId: companyId,
        ),
        builder: (context, snap) => SidebarNavItem(
          label: item.label,
          icon: item.icon,
          active: isActive,
          disabled: item.disabled,
          count: snap.data,
          onTap: item.branch == null
              ? null
              : () => onSelectBranch(item.branch!),
        ),
      );
    }
    return base;
  }
}

sealed class _Item {
  const _Item();
}

class _Section extends _Item {
  const _Section(this.label);
  final String? label;
}

class _Nav extends _Item {
  const _Nav({
    required this.label,
    required this.icon,
    this.branch,
    this.disabled = false,
  });

  final String label;
  final IconData icon;
  final int? branch;
  final bool disabled;
}

const List<_Item> _items = [
  _Section('Workspace'),
  _Nav(label: 'Dashboard', icon: Icons.dashboard_outlined, branch: 1),
  _Nav(label: 'Clients', icon: Icons.people_outline, branch: 0),
  _Nav(label: 'Invoices', icon: Icons.receipt_long_outlined, disabled: true),
  _Nav(label: 'Quotes', icon: Icons.request_quote_outlined, disabled: true),
  _Nav(label: 'Payments', icon: Icons.payments_outlined, disabled: true),
  _Nav(
    label: 'Expenses',
    icon: Icons.account_balance_wallet_outlined,
    disabled: true,
  ),
  _Nav(label: 'Projects', icon: Icons.work_outline, disabled: true),
  _Nav(label: 'Tasks', icon: Icons.task_outlined, disabled: true),
  _Nav(label: 'Vendors', icon: Icons.store_outlined, disabled: true),
  _Section('Saved'),
  _Nav(label: 'Overdue this week', icon: Icons.flag_outlined, disabled: true),
  _Nav(label: r'> $10k open', icon: Icons.attach_money, disabled: true),
  _Nav(label: 'Top 10 clients', icon: Icons.star_outline, disabled: true),
  _Section(null),
  _Nav(label: 'Settings', icon: Icons.settings_outlined, branch: 2),
];
