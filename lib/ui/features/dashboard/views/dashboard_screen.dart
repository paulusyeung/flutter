import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/activity_card.dart';
import 'package:admin/ui/features/dashboard/widgets/chart_card.dart';
import 'package:admin/ui/features/dashboard/widgets/dashboard_top_bar.dart';
import 'package:admin/ui/features/dashboard/widgets/freshness_label.dart';
import 'package:admin/ui/features/dashboard/widgets/kpi_row.dart';
import 'package:admin/ui/features/dashboard/widgets/needs_your_attention_card.dart';
import 'package:admin/ui/features/dashboard/widgets/recent_payments_card.dart';
import 'package:admin/ui/features/dashboard/widgets/upcoming_invoices_card.dart';
import 'package:admin/ui/features/dashboard/widgets/upcoming_quotes_card.dart';
import 'package:admin/ui/features/dashboard/widgets/upcoming_recurring_invoices_card.dart';
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
  late String _companyName;
  Formatter? _formatter;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    final session = _services.auth.session.value!;
    _companyId = session.currentCompanyId;
    final company = session.currentCompany;
    _companyName = company?.displayName.isNotEmpty == true
        ? company!.displayName
        : (company?.name ?? 'Dashboard');
    _vm = _buildVm();
    _services.auth.session.addListener(_onSessionChanged);
    _loadFormatter();
  }

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
    final company = s.currentCompany;
    setState(() {
      _companyId = s.currentCompanyId;
      _companyName = company?.displayName.isNotEmpty == true
          ? company!.displayName
          : (company?.name ?? 'Dashboard');
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

  Future<void> _safeNavigate(String route) async {
    try {
      context.go(route);
    } catch (_) {
      _showSnack('Details arrive in the next update.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    final tokens = context.inTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        return Scaffold(
          backgroundColor: tokens.bg,
          drawer: wide ? null : const AppDrawer(),
          body: SafeArea(
            child: Column(
              children: [
                DashboardTopBar(
                  vm: _vm,
                  companyName: _companyName,
                  onRefresh: _vm.refresh,
                  onNewInvoice: () => _safeNavigate('/invoices/new'),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _vm.refresh,
                    child: _formatter == null
                        ? const Center(child: CircularProgressIndicator())
                        : _buildScroll(context, constraints),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScroll(BuildContext context, BoxConstraints outer) {
    final width = outer.maxWidth;
    final formatter = _formatter!;
    final children = <Widget>[
      KpiRow(vm: _vm, formatter: formatter),
      const SizedBox(height: InSpacing.lg),
      _chartAndActivity(context, width, formatter),
      const SizedBox(height: InSpacing.lg),
      NeedsYourAttentionCard(
        section: _vm.pastDue,
        formatter: formatter,
        onRowTap: (row) => _safeNavigate('/invoices/${row.id}'),
        onViewAll: () => _safeNavigate('/invoices'),
        onRetry: () => _vm.retry(DashboardKind.pastDue),
      ),
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
      UpcomingInvoicesCard(
        section: _vm.upcomingInvoices,
        formatter: formatter,
        onRowTap: (row) => _safeNavigate('/invoices/${row.id}'),
        onViewAll: () => _safeNavigate('/invoices'),
        onRetry: () => _vm.retry(DashboardKind.upcomingInvoices),
      ),
      RecentPaymentsCard(
        section: _vm.recentPayments,
        formatter: formatter,
        onRowTap: (row) => _safeNavigate('/payments/${row.id}'),
        onViewAll: () => _safeNavigate('/payments'),
        onRetry: () => _vm.retry(DashboardKind.recentPayments),
      ),
      UpcomingQuotesCard(
        section: _vm.upcomingQuotes,
        formatter: formatter,
        onRowTap: (row) => _safeNavigate('/quotes/${row.id}'),
        onViewAll: () => _safeNavigate('/quotes'),
        onRetry: () => _vm.retry(DashboardKind.upcomingQuotes),
      ),
      ExpiredQuotesCard(
        section: _vm.expiredQuotes,
        formatter: formatter,
        onRowTap: (row) => _safeNavigate('/quotes/${row.id}'),
        onViewAll: () => _safeNavigate('/quotes'),
        onRetry: () => _vm.retry(DashboardKind.expiredQuotes),
      ),
      UpcomingRecurringInvoicesCard(
        section: _vm.upcomingRecurring,
        formatter: formatter,
        onRowTap: (row) => _safeNavigate('/recurring_invoices/${row.id}'),
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
