import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/domain/upgrade/upgrade_launcher.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Search keys for the Plan tab. Colocated so the search catalog stays in
/// sync with what this screen actually renders.
const kAccountManagementPlanSearchKeys = <String>[
  'plan',
  'free',
  'pro',
  'enterprise',
  'free_trial',
  'change_plan',
  'expires_on',
  'days_left',
];

/// Account Management → Plan. Read-mostly surface. The server pre-computes
/// `ninja_portal_url` (per-user hosted-billing URL); the screen displays the
/// current plan state and routes hosted users to that URL for upgrades /
/// downgrades / payment-method management. We do not render plan tiles or
/// payment methods in-app — the hosted page already does both natively and
/// pulling them client-side requires `account_key` plumbing that's not worth
/// the round-trip.
///
/// Self-hosted users see a "Licensed" state and route to the existing
/// Purchase / Apply License flow on Overview (Phase 2 work).
class AccountManagementPlanScreen extends StatelessWidget {
  const AccountManagementPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<Services>().auth.session;
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: session,
      builder: (context, value, _) {
        if (value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SettingsFormShell(
          sections: [
            _PlanStatusCard(session: value),
            if (value.isHosted) _HostedActionsCard(session: value),
          ],
        );
      },
    );
  }
}

class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;

    final planLabel = session.plan.isEmpty
        ? context.tr('free')
        : context.tr(session.plan);
    final headline = session.isTrial
        ? '$planLabel • ${context.tr('free_trial')}'
        : planLabel;

    return FormSection(
      title: context.tr('plan'),
      spacing: 0,
      children: [
        Text(
          headline,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: tokens.ink,
          ),
        ),
        if (session.isHosted && session.planExpires.isNotEmpty &&
            !session.isTrial &&
            session.plan.isNotEmpty) ...[
          SizedBox(height: InSpacing.sm),
          Text(
            '${context.tr('expires_on')} ${session.planExpires.split(' ').first}',
            style: theme.textTheme.bodyMedium?.copyWith(color: tokens.ink2),
          ),
        ],
        if (session.isTrial) ...[
          SizedBox(height: InSpacing.md(context)),
          _TrialProgress(session: session),
        ],
        // Self-hosted: nothing more to render on this card — the license
        // section on Overview owns Purchase/Apply License, and there's no
        // hosted-billing portal to link to.
      ],
    );
  }
}

class _TrialProgress extends StatelessWidget {
  const _TrialProgress({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final total = session.numTrialDays <= 0 ? 1 : session.numTrialDays;
    final remaining = session.trialDaysRemaining;
    final progress = ((total - remaining) / total).clamp(0.0, 1.0);
    final label = context
        .tr('days_left')
        .replaceAll(':days', remaining.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(InRadii.r1),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: tokens.border,
          ),
        ),
        SizedBox(height: InSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink2),
        ),
      ],
    );
  }
}

class _HostedActionsCard extends StatelessWidget {
  const _HostedActionsCard({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final hasPortalUrl = session.ninjaPortalUrl.isNotEmpty;
    // Decide button label: free → "Upgrade Plan"; paid → "Change Plan";
    // trial → "Upgrade Plan" so the user knows they're paying.
    final labelKey = session.isPaidPlanSlug && !session.isTrial
        ? 'change_plan'
        : 'upgrade_plan';

    return FormSection(
      title: context.tr('change_plan'),
      children: [
        Text(
          context.tr('use_mobile_to_manage_plan'),
          style: TextStyle(color: tokens.ink2),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: InSpacing.md(context),
            runSpacing: InSpacing.sm,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(context.tr(labelKey)),
                // Single platform-conditional seam: store IAP on
                // iOS/Android, portal on web/desktop. Always enabled — the
                // launcher resolves its own destination/fallback.
                onPressed: () => launchUpgrade(context),
              ),
            ],
          ),
        ),
        if (!hasPortalUrl)
          Padding(
            padding: EdgeInsets.only(top: InSpacing.sm),
            child: Text(
              context.tr('error_refresh_page'),
              style: TextStyle(color: tokens.ink3),
            ),
          ),
      ],
    );
  }
}

