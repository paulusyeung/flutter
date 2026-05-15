import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// Visual variant for [PlanGateBanner]. `inset` is the card form (sits inside
/// a page body, padded as a section header); `stripe` is the full-width
/// edge-to-edge form used directly below a TabBar.
enum PlanGateStyle { inset, stripe }

/// Tier the surface is gated behind. Drives the displayed wording and the
/// visibility predicate the banner uses to auto-hide itself.
enum PlanGateLevel { pro, enterprise }

/// Reusable upgrade-nudge banner for plan-gated settings surfaces.
///
/// Replaces the two divergent inline banners (`_PlanGateBanner` in
/// `templates_reminders_body.dart` and `_ProPlanBanner` in
/// `custom_fields_shell.dart`) with a single component:
///
/// - Listens to `services.auth.session` so the banner appears / disappears
///   live when a `/refresh` flips the plan.
/// - Hides itself when the user already has access (so call sites can drop
///   it in unconditionally without a wrapping `if`).
/// - Owner-aware copy: non-owners cannot act on the upgrade, so they see
///   `owner_upgrade_to_paid_plan` with no link CTA.
/// - CTA helper [openUpgradeFlow] launches `ninjaPortalUrl` externally when
///   set, otherwise navigates to `/settings/account_management/plan`.
class PlanGateBanner extends StatelessWidget {
  const PlanGateBanner({
    required this.style,
    this.level = PlanGateLevel.pro,
    super.key,
  });

  final PlanGateStyle style;
  final PlanGateLevel level;

  @override
  Widget build(BuildContext context) {
    final session = context.read<Services>().auth.session;
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: session,
      builder: (context, value, _) {
        if (value == null || _hasAccess(value)) {
          return const SizedBox.shrink();
        }
        return _body(context, value);
      },
    );
  }

  bool _hasAccess(AuthSession s) =>
      level == PlanGateLevel.enterprise ? s.isEnterprisePlan : s.isProPlan;

  Widget _body(BuildContext context, AuthSession session) {
    // Default to owner-style copy + CTA when we don't yet know the role
    // (fresh login, cold restore before /refresh populates `companies`).
    // The non-owner copy is more restrictive — only show it when we're
    // certain the user can't act on the upgrade.
    final me = session.currentCompany;
    final isOwner = me == null ? true : me.isOwner;
    switch (style) {
      case PlanGateStyle.inset:
        return _InsetCard(level: level, isOwner: isOwner);
      case PlanGateStyle.stripe:
        return _StripeBar(level: level, isOwner: isOwner);
    }
  }
}

/// Opens the user's upgrade flow.
///
/// Hosted users with a populated `ninjaPortalUrl` go to the pre-signed billing
/// portal externally; otherwise the user lands on the in-app Plan screen,
/// which itself surfaces the "Manage Plan" button once the URL arrives via
/// `/refresh`. Matches the hand-off pattern in `plan_screen.dart`'s
/// `_openExternal`.
Future<void> openUpgradeFlow(BuildContext context) async {
  final services = context.read<Services>();
  final url = services.auth.session.value?.ninjaPortalUrl ?? '';
  if (url.isNotEmpty) {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {
      // fall through to the in-app destination
    }
  }
  if (!context.mounted) return;
  context.go('/settings/account_management/plan');
}

class _InsetCard extends StatelessWidget {
  const _InsetCard({required this.level, required this.isOwner});

  final PlanGateLevel level;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final t = context.inTheme;
    final theme = Theme.of(context);
    final messageKey = _insetMessageKey(level, isOwner: isOwner);
    // `Semantics(container: true)` collapses the icon + body text + button into
    // a single semantic node for assistive tech, so the screen reader
    // announces "Upgrade required, button: Manage Plan" instead of three
    // disconnected reads.
    return Semantics(
      container: true,
      label: context.tr(messageKey),
      child: Padding(
        padding: EdgeInsets.only(bottom: InSpacing.lg(context)),
        child: Container(
          decoration: BoxDecoration(
            color: t.accentSoft,
            borderRadius: BorderRadius.circular(InRadii.r3),
            border: Border.all(color: t.border),
          ),
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: t.accent),
              const SizedBox(width: InSpacing.sm),
              Expanded(
                child: Text(
                  context.tr(messageKey),
                  style: theme.textTheme.bodyMedium?.copyWith(color: t.ink),
                ),
              ),
              if (isOwner) ...[
                const SizedBox(width: InSpacing.sm),
                OutlinedButton(
                  onPressed: () => unawaited(openUpgradeFlow(context)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                  ),
                  child: Text(context.tr('plan_change')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StripeBar extends StatelessWidget {
  const _StripeBar({required this.level, required this.isOwner});

  final PlanGateLevel level;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(color: tokens.ink);
    final messageKey = _stripeMessageKey(level, isOwner: isOwner);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        border: Border(bottom: BorderSide(color: tokens.border, width: 1)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: tokens.ink),
          const SizedBox(width: InSpacing.sm),
          Expanded(child: Text(context.tr(messageKey), style: bodyStyle)),
          if (isOwner) ...[
            SizedBox(width: InSpacing.md(context)),
            LinkText(
              label: context.tr('plan_change'),
              style: bodyStyle,
              color: tokens.accent,
              onTap: () => unawaited(openUpgradeFlow(context)),
            ),
          ],
        ],
      ),
    );
  }
}

String _insetMessageKey(PlanGateLevel level, {required bool isOwner}) {
  if (!isOwner) return 'owner_upgrade_to_paid_plan';
  return level == PlanGateLevel.enterprise
      ? 'enterprise_plan_features'
      : 'upgrade_to_paid_plan';
}

String _stripeMessageKey(PlanGateLevel level, {required bool isOwner}) {
  if (!isOwner) return 'owner_upgrade_to_paid_plan';
  return level == PlanGateLevel.enterprise
      ? 'enterprise_plan_features'
      : 'start_free_trial_message';
}
