import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/activity_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'activity.freezed.dart';

/// Clean domain model for an activity / comment row. Read-only — the server
/// is authoritative; the client never enqueues an Activity-shaped mutation.
/// Comments are appended via the `addComment` outbox mutation kind which
/// targets `/api/v1/activities/notes`.
@freezed
abstract class Activity with _$Activity {
  const Activity._();

  const factory Activity({
    required String id,
    required int activityTypeId,
    required String notes,
    required DateTime createdAt,
    required String ip,
    String? userLabel,
    String? clientLabel,
    String? invoiceLabel,
  }) = _Activity;

  bool get isComment => activityTypeId == kCommentActivityTypeId;

  factory Activity.fromApi(ActivityApi a) => Activity(
    id: a.id,
    activityTypeId: a.activityTypeId,
    notes: a.notes,
    createdAt: epochSecondsToUtc(a.createdAt),
    ip: a.ip,
    userLabel: a.user?.label.isEmpty ?? true ? null : a.user!.label,
    clientLabel: a.client?.label.isEmpty ?? true ? null : a.client!.label,
    invoiceLabel: a.invoice?.label.isEmpty ?? true ? null : a.invoice!.label,
  );
}
