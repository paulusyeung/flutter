import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/design_tokens.dart';
import '../../../../app/services.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../l10n/localization.dart';
import 'company_avatar.dart';
import 'confirm_pending_outbox.dart';

/// Overlay content: list of companies, a placeholder "New company" action,
/// and the only Sign out entry in the new shell.
///
/// Used by `showCompanyPicker` — either inside a desktop popup or a mobile
/// modal bottom sheet. Closes itself with `Navigator.of(context).maybePop()`.
class CompanyPicker extends StatefulWidget {
  const CompanyPicker({this.fillWidth = false, super.key});

  /// Modal bottom sheets want the picker to take their full width; the
  /// desktop popup wants a fixed 320 px.
  final bool fillWidth;

  @override
  State<CompanyPicker> createState() => _CompanyPickerState();
}

class _CompanyPickerState extends State<CompanyPicker> {
  final _activeRowKey = GlobalKey();
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    // Scroll the active company into view once the list is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _activeRowKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 120),
          alignment: 0.5,
        );
      }
    });
  }

  Future<void> _pick(AuthCompany c, AuthSession session) async {
    if (_switching) return;
    if (c.id == session.currentCompanyId) {
      unawaited(Navigator.of(context).maybePop());
      return;
    }
    final result = await confirmPendingOutboxIfAny(
      context,
      companyId: session.currentCompanyId,
    );
    if (result == OutboxConfirmResult.cancelled || !mounted) return;
    setState(() => _switching = true);
    try {
      await context.read<Services>().auth.switchCompany(c.id);
      // Reset the route to the clients list so the user doesn't land on a
      // now-stale entity URL (e.g. `/clients/<old-id>/edit`) belonging to
      // the previous company. The shell's KeyedSubtree handles same-route
      // refreshes; this handles the route-also-needs-to-change case.
      // `maybeOf` because widget tests pump the picker without a router.
      if (mounted) GoRouter.maybeOf(context)?.go('/clients');
    } finally {
      if (mounted) {
        setState(() => _switching = false);
        unawaited(Navigator.of(context).maybePop());
      }
    }
  }

  Future<void> _signOut(AuthSession session) async {
    if (_switching) return;
    final result = await confirmPendingOutboxIfAny(
      context,
      companyId: session.currentCompanyId,
    );
    if (result == OutboxConfirmResult.cancelled || !mounted) return;
    setState(() => _switching = true);
    await context.read<Services>().auth.logout();
    // Router redirects to /login. Close the picker overlay first so it
    // doesn't sit over the login screen.
    if (mounted) {
      setState(() => _switching = false);
      unawaited(Navigator.of(context).maybePop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final auth = context.read<Services>().auth;
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: auth.session,
      builder: (context, session, _) {
        if (session == null) return const SizedBox.shrink();
        final companies = session.companies;
        final width = widget.fillWidth ? double.infinity : 320.0;
        return Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(InRadii.r3),
              boxShadow: widget.fillWidth ? null : tokens.shadow2,
              border: Border.all(color: tokens.border),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: companies.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: companies.length,
                          itemBuilder: (context, i) {
                            final c = companies[i];
                            final isActive = c.id == session.currentCompanyId;
                            return _CompanyRow(
                              key: isActive ? _activeRowKey : null,
                              company: c,
                              isActive: isActive,
                              onTap: _switching ? null : () => _pick(c, session),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 6),
                Divider(height: 1, color: tokens.border),
                const SizedBox(height: 6),
                _ActionRow(
                  icon: Icons.add,
                  label: context.tr('new_company'),
                  onTap: () => _comingSoon(context),
                ),
                const SizedBox(height: 6),
                Divider(height: 1, color: tokens.border),
                const SizedBox(height: 6),
                _ActionRow(
                  icon: Icons.logout,
                  label: context.tr('logout'),
                  onTap: _switching ? null : () => _signOut(session),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void _comingSoon(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(context.tr('coming_soon'))));
}

class _CompanyRow extends StatelessWidget {
  const _CompanyRow({
    required this.company,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final AuthCompany company;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Material(
      color: isActive ? tokens.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(InRadii.r2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InRadii.r2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              CompanyAvatar(
                name: company.displayName,
                seed: company.id,
                size: 28,
                logoUrl: company.logoUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                    if (isActive)
                      Text(
                        context.tr('active'),
                        style: TextStyle(fontSize: 11, color: tokens.ink3),
                      ),
                  ],
                ),
              ),
              if (isActive) Icon(Icons.check, size: 16, color: tokens.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(InRadii.r2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 14, color: tokens.ink3),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, color: tokens.ink2)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        context.tr('no_companies'),
        style: TextStyle(fontSize: 12.5, color: tokens.ink3),
      ),
    );
  }
}
