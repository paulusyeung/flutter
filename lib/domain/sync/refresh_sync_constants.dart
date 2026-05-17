/// Tuning constants for the `/api/v1/refresh` delta-sync engine. Mirrors the
/// legacy admin-portal's sync cadence (its `lib/constants.dart`):
///   * `kMillisecondsToTimerRefreshData = 5 min`
///   * `kUpdatedAtBufferSeconds = 600`
///   * `kMillisecondsToRefreshStaticData = 24 h`
///
/// Kept in one place so the auth layer and the foreground refresh scheduler
/// agree on the numbers.
library;

/// Subtracted from a company's stored `last_sync_at` before it's sent as the
/// `updated_at` query param, so a clock skew / in-flight write that landed
/// server-side around the previous refresh isn't missed. v1 used 600 s.
const int kUpdatedAtBufferSeconds = 600;

/// The static catalog (currencies, countries, …) changes rarely. A delta
/// refresh only re-requests it (`include_static=true`) when the cached blob
/// is older than this. v1 used 24 h.
const Duration kStaticsStaleAfter = Duration(hours: 24);

/// Foreground auto-refresh period. While the app is active and authenticated
/// the scheduler fires a delta refresh on this cadence. v1 used 5 min.
const Duration kRefreshInterval = Duration(minutes: 5);

/// Hard floor between any two scheduler-driven refreshes, regardless of what
/// triggered them (timer tick or app-resume), so a resume right after a tick
/// doesn't double-fire.
const Duration kMinRefreshGap = Duration(minutes: 5);
