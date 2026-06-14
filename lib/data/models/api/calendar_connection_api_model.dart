import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_connection_api_model.freezed.dart';
part 'calendar_connection_api_model.g.dart';

/// A user's calendar connection as returned by `GET /api/v1/calendar_connection`
/// (the inner `data.calendar_connection` object). The server envelope is `null`
/// when no provider is connected — [CalendarConnectionRepository] maps that to a
/// disconnected sentinel.
///
/// We read **`connected`** (bool) here, NOT a `status` string: the
/// `{status:'CONNECTED', email}` form is the separate `/refresh` user-embed
/// (`CalendarConnection::toResponseObject` server-side), which this client does
/// not consume — the dedicated endpoint is richer (`provider` / `email` /
/// `calendars`) and avoids threading state through the `User` model + Drift.
@freezed
abstract class CalendarConnection with _$CalendarConnection {
  const factory CalendarConnection({
    @Default(false) bool connected,
    String? provider,
    String? email,
    @JsonKey(name: 'expires_at') int? expiresAt,
    @Default(<CalendarInfo>[]) List<CalendarInfo> calendars,
  }) = _CalendarConnection;

  factory CalendarConnection.fromJson(Map<String, dynamic> json) =>
      _$CalendarConnectionFromJson(json);
}

/// One calendar exposed by the connected provider. `selected` is meaningful
/// only on the `GET …/calendars` listing (whether it's part of the user's
/// saved selection); the connection's own `calendars` list omits it.
@freezed
abstract class CalendarInfo with _$CalendarInfo {
  const factory CalendarInfo({
    @JsonKey(name: 'calendar_id') @Default('') String calendarId,
    @Default('') String name,
    @Default(false) bool primary,
    @Default(false) bool writable,
    @Default(false) bool selected,
  }) = _CalendarInfo;

  factory CalendarInfo.fromJson(Map<String, dynamic> json) =>
      _$CalendarInfoFromJson(json);
}

/// A normalized calendar event from `GET …/events`. `start` / `end` are kept
/// as the raw provider strings — an ISO-8601 instant for timed events, a bare
/// `YYYY-MM-DD` for all-day events — and parsed by the convert flow, which is
/// timezone-aware (see [CalendarEventX]).
@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    @Default('') String id,
    @JsonKey(name: 'calendar_event_id') @Default('') String calendarEventId,
    @Default('') String provider,
    @JsonKey(name: 'provider_event_id') @Default('') String providerEventId,
    @JsonKey(name: 'calendar_id') @Default('') String calendarId,
    @JsonKey(name: 'calendar_name') @Default('') String calendarName,
    @Default('') String title,
    @Default('') String description,
    @Default('') String location,
    @Default('') String start,
    @Default('') String end,
    @JsonKey(name: 'all_day') @Default(false) bool allDay,
    @Default('') String status,
    @Default('') String updated,
  }) = _CalendarEvent;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);
}

extension CalendarEventX on CalendarEvent {
  /// Start as a local [DateTime] (null if unparseable). Timed events parse the
  /// ISO instant and convert to local; all-day events anchor at local midnight
  /// on their floating wall-clock date (no timezone shift).
  DateTime? get startLocal => _parse(start);

  /// End as a local [DateTime] (null if unparseable). See [startLocal].
  DateTime? get endLocal => _parse(end);

  DateTime? _parse(String raw) {
    if (raw.isEmpty) return null;
    if (allDay) {
      final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
      if (m != null) {
        return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
      }
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  /// `YYYY-MM-DD` key used to bucket the event into a calendar cell. Derived
  /// AFTER converting timed events to local time, so an event late in the UTC
  /// day lands on the correct local day (mirrors React's date-key logic).
  String get dayKey {
    final d = startLocal;
    if (d == null) {
      final m = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(start);
      return m?.group(1) ?? start;
    }
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$mm-$dd';
  }

  bool get isCancelled => status == 'cancelled';
}
