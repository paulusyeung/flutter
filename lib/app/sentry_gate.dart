/// Single source of truth for the Sentry send/drop policy, mirroring v1
/// admin-portal's `beforeSend` gate: an error event is transmitted ONLY
/// when the active account opted in via `account.report_errors`. Pure +
/// top-level so the policy is unit-testable in isolation (the project's
/// "pure fn for testability" pattern); `main.dart`'s `beforeSend` consults
/// this and returns `null` to drop when it yields false.
///
/// Default-deny by construction: callers pass `false` when there is no
/// session / the flag is absent, so events are dropped unless explicitly
/// opted in (privacy-safe, matches v1).
bool sentryShouldSend({required bool reportErrors}) => reportErrors;
