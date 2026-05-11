import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

/// Shared chrome for the 6 Company Details sub-routes:
///   * holds the [CompanyDetailsViewModel] so every tab edits one draft
///   * renders the AppBar with the Save action
///   * renders a horizontal tab strip wired to the sub-routes
///
/// Mounted as a `ShellRoute` around the `/settings/company_details` branch.
class CompanyDetailsShell extends StatefulWidget {
  const CompanyDetailsShell({super.key, required this.child});

  final Widget child;

  @override
  State<CompanyDetailsShell> createState() => _CompanyDetailsShellState();
}

class _CompanyDetailsShellState extends State<CompanyDetailsShell> {
  late CompanyDetailsViewModel _vm;
  late final SettingsLevelController _levelController;
  late final Services _services;
  String _currentCompanyId = '';

  static const _tabs = <(String pathSuffix, String labelKey)>[
    ('', 'details'),
    ('/address', 'address'),
    ('/logo', 'logo'),
    ('/defaults', 'defaults'),
    ('/documents', 'documents'),
    ('/custom_fields', 'custom_fields'),
  ];

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _currentCompanyId = _services.auth.session.value?.currentCompanyId ?? '';
    _vm = CompanyDetailsViewModel(
      repo: _services.company,
      companyId: _currentCompanyId,
    );
    _vm.load();
    _levelController = SettingsLevelController();
    _services.auth.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    _vm.dispose();
    _levelController.dispose();
    super.dispose();
  }

  /// Replace the in-progress VM when the user switches companies. The old
  /// draft is intentionally discarded — it belongs to the previous tenant
  /// and would be invalid against the new one's id.
  void _onSessionChanged() {
    final next = _services.auth.session.value?.currentCompanyId ?? '';
    if (next == _currentCompanyId) return;
    setState(() {
      _vm.dispose();
      _currentCompanyId = next;
      _vm = CompanyDetailsViewModel(repo: _services.company, companyId: next);
      _vm.load();
    });
  }

  int _indexFor(String path) {
    for (var i = _tabs.length - 1; i >= 0; i--) {
      final suffix = _tabs[i].$1;
      if (suffix.isEmpty) {
        if (path == '/settings/company_details') return i;
      } else if (path.endsWith(suffix)) {
        return i;
      }
    }
    return 0;
  }

  void _onTabSelected(BuildContext context, int index) {
    const base = '/settings/company_details';
    final suffix = _tabs[index].$1;
    context.go('$base$suffix');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _vm),
        ChangeNotifierProvider.value(value: _levelController),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = Breakpoints.isWide(constraints);
          final path = GoRouterState.of(context).uri.path;
          final index = _indexFor(path);
          return Scaffold(
            drawer: wide ? null : const AppDrawer(),
            appBar: AppBar(
              title: Text(context.tr('company_details')),
              leading: wide ? null : const DrawerHamburger(),
              automaticallyImplyLeading: !wide,
              actions: [
                ListenableBuilder(
                  listenable: _vm,
                  builder: (context, _) {
                    final canSave = _vm.isDirty && !_vm.isSaving;
                    return TextButton(
                      onPressed: canSave ? () => _save(context) : null,
                      child: _vm.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.tr('save')),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _TabStrip(
                  tabs: [for (final (_, key) in _tabs) context.tr(key)],
                  selectedIndex: index,
                  onSelected: (i) => _onTabSelected(context, i),
                ),
              ),
            ),
            body: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) {
                if (!_vm.isLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                final err = _vm.loadError;
                if (err != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LoadErrorBanner(message: err),
                      Expanded(child: widget.child),
                    ],
                  );
                }
                return widget.child;
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final successText = context.tr('saved_settings');
    final errorFallback = context.tr('error_refresh_page');
    final result = await _vm.save();
    if (!mounted) return;
    final text = result != null
        ? successText
        // The VM stashes the raw exception text on `submitError`; surface
        // it so the user (or dev tester) sees what actually broke instead
        // of a generic banner.
        : '$errorFallback${_vm.submitError == null ? '' : ' — ${_vm.submitError}'}';
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }
}

/// Inline error banner shown above the tab body when `vm.loadError` is set.
/// The form below it still renders against whatever subset of the settings
/// the typed parse could recover, so the user can read + edit the parts
/// that work while the developer chases down the bad field.
class _LoadErrorBanner extends StatelessWidget {
  const _LoadErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('error_refresh_page'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal strip of tab buttons. Each tab is a Material `InkWell` with a
/// bottom indicator on the selected one. Renders inside the AppBar's
/// `bottom` slot.
class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      child: SizedBox(
        height: 48,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _TabButton(
                  label: tabs[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
