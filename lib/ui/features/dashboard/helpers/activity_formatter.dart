import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_activity.dart';
import 'package:admin/l10n/localization.dart';

/// Renders a `DashboardActivity` into a (title, meta, tone, icon) tuple the
/// activity card consumes.
///
/// The title is the localized `activity_N` string with `:user`/`:contact`/
/// `:client`/`:invoice`/... tokens replaced. Unknown activity types fall back
/// to "Activity #N" so the card never renders raw template strings.
class ActivityRender {
  const ActivityRender({
    required this.title,
    required this.meta,
    required this.tone,
    required this.icon,
  });

  final String title;
  final String meta;
  final ActivityTone tone;
  final IconData icon;
}

/// Status colors map for activity circles. Indexed by [ActivityTone].
enum ActivityTone { paid, sent, viewed, draft, expense, neutral }

class ActivityFormatter {
  ActivityFormatter(this.context);

  final BuildContext context;

  ActivityRender format(DashboardActivity a) {
    final l = Localization.of(context);
    final key = 'activity_${a.activityTypeId}';
    final raw = l?.lookup(key) ?? '';
    final hasTemplate = raw.isNotEmpty && raw != key;

    String resolved;
    if (hasTemplate) {
      resolved = raw
          .replaceAll(':user', _labelFor(a.userId, 'user'))
          .replaceAll(':contact', _labelFor(a.contactId, 'contact'))
          .replaceAll(':client', _labelFor(a.clientId, 'client'))
          .replaceAll(':invoice', _labelFor(a.invoiceId, 'invoice'))
          .replaceAll(':quote', _labelFor(a.quoteId, 'quote'))
          .replaceAll(':payment', _labelFor(a.paymentId, 'payment'))
          .replaceAll(':expense', _labelFor(a.expenseId, 'expense'))
          .replaceAll(
            ':recurring_invoice',
            _labelFor(a.recurringInvoiceId, 'recurring invoice'),
          );
    } else {
      resolved = context.tr('activity_unknown', {
        'id': a.activityTypeId.toString(),
      });
    }

    final tone = _toneFor(a.activityTypeId);
    final icon = _iconFor(tone);
    final meta = _relativeTime(
      DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(a.createdAt * 1000),
      ),
    );
    return ActivityRender(title: resolved, meta: meta, tone: tone, icon: icon);
  }

  /// Approximate mapping from `activity_type_id` → tone. Drawn from
  /// Invoice Ninja's activity catalog — covers the top dozen common types.
  ActivityTone _toneFor(int id) {
    // 1=created_client, 2=archived_client, 3=deleted_client → neutral
    // 4=created_invoice, 5=updated_invoice → draft
    // 6=emailed_invoice → sent
    // 10=viewed_invoice → viewed
    // 11=marked_paid → paid; 19=paid_invoice → paid
    // 23=updated_quote, 24=emailed_quote → sent
    // 25=viewed_quote → viewed
    // 26=approved_quote, 30=archived_quote → paid
    // 36=created_expense → expense
    switch (id) {
      case 6:
      case 24:
      case 32:
        return ActivityTone.sent;
      case 10:
      case 25:
        return ActivityTone.viewed;
      case 11:
      case 19:
      case 22:
      case 26:
      case 27:
        return ActivityTone.paid;
      case 36:
      case 37:
        return ActivityTone.expense;
      case 4:
      case 5:
      case 23:
        return ActivityTone.draft;
    }
    return ActivityTone.neutral;
  }

  IconData _iconFor(ActivityTone tone) {
    switch (tone) {
      case ActivityTone.paid:
        return Icons.check_circle_outline;
      case ActivityTone.sent:
        return Icons.send_outlined;
      case ActivityTone.viewed:
        return Icons.visibility_outlined;
      case ActivityTone.draft:
        return Icons.edit_outlined;
      case ActivityTone.expense:
        return Icons.receipt_long_outlined;
      case ActivityTone.neutral:
        return Icons.circle_outlined;
    }
  }

  /// Build a placeholder label for missing references. Real labels need
  /// joined invoice/client lookups which M1 doesn't have — we surface a
  /// readable placeholder (localized to the active locale) so the activity
  /// text still parses.
  String _labelFor(String? id, String fallbackKey) => context.tr(fallbackKey);

  String _relativeTime(Duration d) {
    if (d.inSeconds < 60) return context.tr('just_now').toLowerCase();
    if (d.inMinutes < 60) {
      return context.tr('minutes_ago_short', {
        'count': d.inMinutes.toString(),
      });
    }
    if (d.inHours < 24) {
      return context.tr('hours_ago_short', {'count': d.inHours.toString()});
    }
    if (d.inDays < 7) {
      return context.tr('days_ago_short', {'count': d.inDays.toString()});
    }
    return context.tr('weeks_ago_short', {
      'count': (d.inDays ~/ 7).toString(),
    });
  }
}

/// Resolve the tone-soft / tone-fg pair for the activity circle.
(Color bg, Color fg) activityToneColors(InTheme t, ActivityTone tone) {
  switch (tone) {
    case ActivityTone.paid:
      return (t.paidSoft, t.paid);
    case ActivityTone.sent:
      return (t.sentSoft, t.sent);
    case ActivityTone.viewed:
      return (t.partialSoft, t.partial);
    case ActivityTone.draft:
      return (t.draftSoft, t.draft);
    case ActivityTone.expense:
      return (t.overdueSoft, t.overdue);
    case ActivityTone.neutral:
      return (t.surfaceAlt, t.ink3);
  }
}
