import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:admin/app/router.dart';
import 'package:admin/data/models/domain/activity.dart';
import 'package:admin/l10n/localization.dart';

/// The rendered sentence for an [Activity] plus the tap recognizers it
/// created. The host widget must [dispose] the recognizers (a `TextSpan`
/// recognizer is not auto-disposed).
class ActivitySpans {
  const ActivitySpans(this.spans, this.recognizers);

  final List<InlineSpan> spans;
  final List<TapGestureRecognizer> recognizers;

  void dispose() {
    for (final r in recognizers) {
      r.dispose();
    }
  }
}

/// Turn an [Activity] into a human-readable, link-bearing sentence by
/// substituting the `activity_<type>` localized template's `:token`s with
/// the record's resolved label objects — mirroring the React app and the
/// legacy admin-portal `getDescription`.
///
/// - type 10 → `activity_10_online` when a contact is present else
///   `activity_10_manual` (online payments are contact-initiated).
/// - type 54 with a contact → swap `:user`→`:contact` (contact-initiated).
/// - Routable refs render as accent links (tap → `goEntityRecord`); the
///   acting `user` and amount tokens render bold-but-static; `:notes` shows
///   the raw note; a token the server omitted falls back to its localized
///   noun so a literal `:token` never leaks.
/// - Missing template → `activity_unknown` ("Activity #N").
ActivitySpans buildActivitySpans(
  BuildContext context,
  Activity a, {
  required TextStyle base,
  required TextStyle link,
  required TextStyle strong,
}) {
  final l = Localization.of(context);
  var key = 'activity_${a.activityTypeId}';
  if (a.activityTypeId == 10) {
    key = a.refs.containsKey('contact')
        ? 'activity_10_online'
        : 'activity_10_manual';
  }
  var raw = l?.lookup(key) ?? '';
  final hasTemplate = raw.isNotEmpty && raw != key;
  if (!hasTemplate) {
    return ActivitySpans([
      TextSpan(
        text: context.tr('activity_unknown', {'id': '${a.activityTypeId}'}),
        style: base,
      ),
    ], const []);
  }
  if (a.activityTypeId == 54 && a.refs.containsKey('contact')) {
    raw = raw.replaceAll(':user', ':contact');
  }

  final spans = <InlineSpan>[];
  final recs = <TapGestureRecognizer>[];
  final re = RegExp(r':([a-z_]+)');
  var last = 0;
  for (final m in re.allMatches(raw)) {
    if (m.start > last) {
      spans.add(TextSpan(text: raw.substring(last, m.start), style: base));
    }
    final token = m.group(1)!;
    if (token == 'notes') {
      spans.add(TextSpan(text: a.notes, style: strong));
    } else {
      final ref = a.refs[token];
      if (ref == null) {
        // Server omitted this related entity — show its localized noun
        // (e.g. ":client" → "Client") instead of a raw token.
        spans.add(TextSpan(text: context.tr(token), style: base));
      } else if (ref.isLink) {
        final rec = TapGestureRecognizer()
          ..onTap = () => goEntityRecord(context, ref.type!, ref.id);
        recs.add(rec);
        spans.add(TextSpan(text: ref.label, style: link, recognizer: rec));
      } else {
        spans.add(TextSpan(text: ref.label, style: strong));
      }
    }
    last = m.end;
  }
  if (last < raw.length) {
    spans.add(TextSpan(text: raw.substring(last), style: base));
  }
  return ActivitySpans(spans, recs);
}
