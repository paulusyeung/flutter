/// Marker mixin every per-entity DAO applies so we can grep for queries that
/// bypass company scoping at lint time.
///
/// The CI test scans `lib/` for `.select(<Table>)` patterns outside of files
/// that mix this in (i.e. outside of `lib/data/db/`). Repositories never read
/// tables directly — they go through the DAO that scopes by company.
mixin CompanyScopedDao {}
