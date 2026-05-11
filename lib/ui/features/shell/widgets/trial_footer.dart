import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/l10n/localization.dart';

/// Small trial-info card pinned to the bottom of the sidebar. Auto-hides
/// when there isn't a trial to advertise.
class TrialFooter extends StatelessWidget {
  const TrialFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final dao = context.read<Services>().db.companiesDao;
    final tokens = context.inTheme;
    return StreamBuilder<AccountRow?>(
      stream: dao.watchAccount(),
      builder: (context, snap) {
        final account = snap.data;
        if (account == null || account.numTrialDays <= 0) {
          return const SizedBox.shrink();
        }
        final days = account.numTrialDays;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              borderRadius: BorderRadius.circular(InRadii.r2),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    days == 1
                        ? 'trial_days_left_singular'
                        : 'trial_days_left_plural',
                    {'count': days.toString()},
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('upgrade_pitch'),
                  style: TextStyle(fontSize: 11.5, color: tokens.ink3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
