import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/activity_card.dart';
import 'package:admin/ui/features/dashboard/widgets/chart_card.dart';
import 'package:admin/ui/features/dashboard/widgets/dashboard_top_bar.dart';
import 'package:admin/ui/features/dashboard/widgets/freshness_label.dart';
import 'package:admin/ui/features/dashboard/widgets/kpi_row.dart';
import 'package:admin/ui/features/dashboard/widgets/mobile_dashboard_body.dart';
import 'package:admin/ui/features/dashboard/widgets/needs_your_attention_card.dart';
import 'package:admin/ui/features/dashboard/widgets/recent_payments_card.dart';
import 'package:admin/ui/features/dashboard/widgets/upcoming_invoices_card.dart';
import 'package:admin/ui/features/dashboard/widgets/upcoming_quotes_card.dart';
import 'package:admin/ui/features/dashboard/widgets/upcoming_recurring_invoices_card.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_activity.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/data/repositories/dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Services _services;
  late DashboardViewModel _vm;
  late String _companyId;
  // Empty when the active company has neither a `displayName` nor a `name`;
  // `_resolveCompanyName(context)` falls back to the localized 'Dashboard'
  // string at render time so the fallback follows the active locale.
  late String _rawCompanyName;
  Formatter? _formatter;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    final session = _services.auth.session.value!;
    _companyId = session.currentCompanyId;
    _rawCompanyName = _rawNameFor(session.currentCompany);
    _vm = _buildVm();
    _services.auth.session.addListener(_onSessionChanged);
    _loadFormatter();
  }

  static String _rawNameFor(dynamic company) {
    if (company == null) return '';
    final display = company.displayName as String? ?? '';
    if (display.isNotEmpty) return display;
    return company.name as String? ?? '';
  }

  String _resolveCompanyName(BuildContext context) =>
      _rawCompanyName.isNotEmpty ? _rawCompanyName : context.tr('dashboard');

  DashboardViewModel _buildVm() => DashboardViewModel(
    repo: _services.dashboard,
    companyId: _companyId,
    navStateDao: _services.db.navStateDao,
    statics: _services.statics,
  );

  void _loadFormatter() {
    final loadingFor = _companyId;
    _services.formatterFor(loadingFor).then((f) {
      if (!mounted || loadingFor != _companyId) return;
      setState(() => _formatter = f);
    });
  }

  void _onSessionChanged() {
    final s = _services.auth.session.value;
    if (s == null || s.currentCompanyId == _companyId) return;
    final oldVm = _vm;
    setState(() {
      _companyId = s.currentCompanyId;
      _rawCompanyName = _rawNameFor(s.currentCompany);
      _formatter = null;
      _vm = _buildVm();
    });
    oldVm.dispose();
    _loadFormatter();
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    _vm.dispose();
    super.dispose();
  }

  /// Set of route prefixes that are actually wired into the router today.
  /// Targets outside this set short-circuit to a snack instead of navigating
  /// (an unknown route would otherwise land the user on the root error page
  /// and lose the shell's nav rail / bottom nav). Update as new entity routes
  /// land in the router — `/invoices`, `/payments`, `/quotes`,
  /// `/recurring_invoices`, etc. all get added here when their detail screens
  /// ship. Until then, the dashboard's deep-links snack via this gate.
  static const _knownRoutePrefixes = {'/clients', '/dashboard', '/settings'};

  Future<void> _safeNavigate(String route) async {
    final isKnown = _knownRoutePrefixes.any(
      (p) => route == p || route.startsWith('$p/'),
    );
    if (!isKnown) {
      _showSnack(context.tr('details_in_next_update'));
      return;
    }
    context.go(route);
  }

  void _showSnack(String msg) {
    Notify.info(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableProvider<DashboardViewModel>.value(
      value: _vm,
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        final globalNav = Breakpoints.isGlobalNavVisible(context);
        final scaffold = Builder(
          builder: (context) {
            final tokens = context.inTheme;
            return Scaffold(
              backgroundColor: tokens.bg,
              // Drawer keyed on *window* width — not [wide] — so the
              // hamburger doesn't appear at medium widths where the
              // global persistent rail is already visible.
              drawer: globalNav ? null : const AppDrawer(),
              body: SafeArea(
                child: Column(
                  children: [
                    DashboardTopBar(
                      vm: _vm,
                      companyName: _resolveCompanyName(context),
                      onNewInvoice: () => _safeNavigate('/invoices/new'),
                      formatter: _formatter,
                      compact: !wide,
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _vm.refresh,
                        child: _formatter == null
                            ? const Center(child: CircularProgressIndicator())
                            : (wide
                                  ? _buildScroll(context, constraints)
                                  : _buildMobile(context)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        return scaffold;
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    return MobileDashboardBody(
      vm: _vm,
      formatter: _formatter!,
      companyName: _resolveCompanyName(context),
      onPastDueInvoiceTap: _navInvoice,
      onAllInvoices: () => _safeNavigate('/invoices'),
      onNewInvoice: () => _safeNavigate('/invoices/new'),
      onAddClient: () => _safeNavigate('/clients/new'),
      onLogExpense: () => _safeNavigate('/expenses/new'),
      onReports: () => _safeNavigate('/reports'),
      onOutstandingTap: () => _safeNavigate('/invoices'),
      onOverdueTap: () => _safeNavigate('/invoices'),
      onPaidTap: () => _safeNavigate('/payments'),
      onActivityTap: _navActivity,
      onAllActivities: () => _safeNavigate('/activities'),
      onUpcomingInvoiceTap: _navInvoice,
      onPaymentTap: _navPayment,
      onAllPayments: () => _safeNavigate('/payments'),
      onQuoteTap: _navQuote,
      onAllQuotes: () => _safeNavigate('/quotes'),
      onRecurringTap: _navRecurring,
      onAllRecurring: () => _safeNavigate('/recurring_invoices'),
    );
  }

  // Cell-level navigation helpers shared by every list card. The pair pattern
  // (entity tap vs client tap) lines up 1:1 with the per-cell callback split
  // in `DashboardEntityTableRow.cellTaps`.

  void _navInvoice(DashboardInvoiceRow row) =>
      _safeNavigate('/invoices/${row.id}');
  void _navInvoiceClient(DashboardInvoiceRow row) =>
      _safeNavigate('/clients/${row.clientId}');
  void _navPayment(DashboardPaymentRow row) =>
      _safeNavigate('/payments/${row.id}');
  void _navPaymentClient(DashboardPaymentRow row) =>
      _safeNavigate('/clients/${row.clientId}');
  void _navQuote(DashboardQuoteRow row) => _safeNavigate('/quotes/${row.id}');
  void _navQuoteClient(DashboardQuoteRow row) =>
      _safeNavigate('/clients/${row.clientId}');
  void _navRecurring(DashboardRecurringInvoiceRow row) =>
      _safeNavigate('/recurring_invoices/${row.id}');
  void _navRecurringClient(DashboardRecurringInvoiceRow row) =>
      _safeNavigate('/clients/${row.clientId}');

  /// Resolve an activity row to its most-specific deep-link. Mirrors the
  /// precedence the activity-list page is expected to use when M2 lands.
  /// Rows that reference no entity (e.g. a system-only activity) silently
  /// do nothing — there's no per-activity detail screen.
  void _navActivity(DashboardActivity a) {
    final target = _activityTarget(a);
    if (target == null) return;
    _safeNavigate(target);
  }

  static String? _activityTarget(DashboardActivity a) {
    if (a.invoiceId != null) return '/invoices/${a.invoiceId}';
    if (a.quoteId != null) return '/quotes/${a.quoteId}';
    if (a.paymentId != null) return '/payments/${a.paymentId}';
    if (a.recurringInvoiceId != null) {
      return '/recurring_invoices/${a.recurringInvoiceId}';
    }
    if (a.expenseId != null) return '/expenses/${a.expenseId}';
    if (a.clientId != null) return '/clients/${a.clientId}';
    return null;
  }

  Widget _buildScroll(BuildContext context, BoxConstraints outer) {
    final width = outer.maxWidth;
    final formatter = _formatter!;
    final children = <Widget>[
      KpiRow(
        vm: _vm,
        formatter: formatter,
        onOutstandingTap: () => _safeNavigate('/invoices'),
        onOverdueTap: () => _safeNavigate('/invoices'),
        onPaidThisMonthTap: () => _safeNavigate('/payments'),
      ),
      const SizedBox(height: InSpacing.lg),
      _chartAndActivity(context, width, formatter),
      const SizedBox(height: InSpacing.lg),
      _bottomGrid(context, width, formatter),
      const SizedBox(height: InSpacing.lg),
      Align(
        alignment: Alignment.centerRight,
        child: FreshnessLabel(
          lastRefreshed: _vm.lastRefreshed,
          isRefreshing: _vm.isAnyRefreshing,
          onRefresh: _vm.refresh,
        ),
      ),
      const SizedBox(height: InSpacing.xl),
    ];

    return ListView(
      padding: const EdgeInsets.all(InSpacing.xl),
      children: children,
    );
  }

  Widget _chartAndActivity(
    BuildContext context,
    double width,
    Formatter formatter,
  ) {
    final chart = ChartCard(vm: _vm, formatter: formatter);
    final activity = ActivityCard(
      section: _vm.activities,
      onViewAll: () => _safeNavigate('/activities'),
      onRetry: () => _vm.retry(DashboardKind.activities),
      onActivityTap: _navActivity,
    );
    if (width >= 1024) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 17, child: chart),
            const SizedBox(width: InSpacing.lg),
            Expanded(flex: 10, child: activity),
          ],
        ),
      );
    }
    return Column(
      children: [
        chart,
        const SizedBox(height: InSpacing.lg),
        activity,
      ],
    );
  }

  Widget _bottomGrid(BuildContext context, double width, Formatter formatter) {
    final cards = <Widget>[
      NeedsYourAttentionCard(
        section: _vm.pastDue,
        formatter: formatter,
        onInvoiceTap: _navInvoice,
        onClientTap: _navInvoiceClient,
        onViewAll: () => _safeNavigate('/invoices'),
        onRetry: () => _vm.retry(DashboardKind.pastDue),
      ),
      UpcomingInvoicesCard(
        section: _vm.upcomingInvoices,
        formatter: formatter,
        onInvoiceTap: _navInvoice,
        onClientTap: _navInvoiceClient,
        onViewAll: () => _safeNavigate('/invoices'),
        onRetry: () => _vm.retry(DashboardKind.upcomingInvoices),
      ),
      RecentPaymentsCard(
        section: _vm.recentPayments,
        formatter: formatter,
        onPaymentTap: _navPayment,
        onClientTap: _navPaymentClient,
        onViewAll: () => _safeNavigate('/payments'),
        onRetry: () => _vm.retry(DashboardKind.recentPayments),
      ),
      UpcomingQuotesCard(
        section: _vm.upcomingQuotes,
        formatter: formatter,
        onQuoteTap: _navQuote,
        onClientTap: _navQuoteClient,
        onViewAll: () => _safeNavigate('/quotes'),
        onRetry: () => _vm.retry(DashboardKind.upcomingQuotes),
      ),
      ExpiredQuotesCard(
        section: _vm.expiredQuotes,
        formatter: formatter,
        onQuoteTap: _navQuote,
        onClientTap: _navQuoteClient,
        onViewAll: () => _safeNavigate('/quotes'),
        onRetry: () => _vm.retry(DashboardKind.expiredQuotes),
      ),
      UpcomingRecurringInvoicesCard(
        section: _vm.upcomingRecurring,
        formatter: formatter,
        onRecurringTap: _navRecurring,
        onClientTap: _navRecurringClient,
        onViewAll: () => _safeNavigate('/recurring_invoices'),
        onRetry: () => _vm.retry(DashboardKind.upcomingRecurring),
      ),
    ];

    int columns;
    if (width >= 1280) {
      columns = 3;
    } else if (width >= 1024) {
      columns = 2;
    } else if (width >= 600) {
      columns = 2;
    } else {
      columns = 1;
    }
    return _MultiColumnGrid(
      columns: columns,
      gap: InSpacing.lg,
      children: cards,
    );
  }
}

/// Simple column-balanced grid that places `children` left-to-right, top-to-
/// bottom into [columns] columns with `gap` between cells and rows. We use
/// this instead of `GridView` so each row can size itself to its tallest
/// card (cards have variable internal height).
class _MultiColumnGrid extends StatelessWidget {
  const _MultiColumnGrid({
    required this.columns,
    required this.gap,
    required this.children,
  });

  final int columns;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = 0; j < columns; j++) {
        final idx = i + j;
        if (j > 0) rowChildren.add(SizedBox(width: gap));
        rowChildren.add(
          Expanded(
            child: idx < children.length
                ? children[idx]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowChildren,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
