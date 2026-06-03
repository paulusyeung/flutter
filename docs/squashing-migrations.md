# Squashing Drift migrations to a single v1 schema

**Pre-launch only.** This throws away every upgrade path. It is safe *only* while the app is
unshipped: there are no installed databases to upgrade, and the runtime backstop
`isSchemaIntact()` (`lib/data/db/app_database.dart`) resets any drifted local DB to a fresh
`createAll()` on next launch. **Do not run this once real users exist.**

Run it (a) for the initial squash, and (b) once more right before the prod release, to collapse
whatever migrations accumulated in the meantime back into a single v1.

## Why

The schema accreted dozens of incremental `onUpgrade` steps plus a per-version schema-dump/test
matrix. With no users to upgrade, that history is dead weight. Collapsing to `schemaVersion = 1`
with an `onCreate`-only strategy leaves one schema definition built straight from the current Dart
table classes.

## Steps

1. **Code — make the schema `onCreate`-only** (`lib/data/db/app_database.dart`):
   - `int get schemaVersion => 1;`
   - `MigrationStrategy`: keep `onCreate` only — `createAll()` + `createPerformanceIndexes(this)` +
     `createClientFilterIndexes(this)`. Delete the `onUpgrade` callback.
   - If a per-step migration file exists (`lib/data/db/migrations.dart`), delete it and keep the two
     index helpers + `StandardEntityColumns` in `app_database.dart`. Drop `runMigrations` and any
     `_columnExists`-style step helpers.

2. **Regenerate codegen:**
   ```sh
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Reset the schema baseline** (run *after* `schemaVersion` is `1` so the dump captures v1):
   ```sh
   rm drift_schemas/*.json
   rm test/generated/schema_v*.dart test/generated/schema.dart
   dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/   # -> drift_schema_v1.json
   dart run drift_dev schema generate drift_schemas/ test/generated/             # -> schema_v1.dart + schema.dart
   ```

4. **Tests** — `test/data/db/migration_test.dart` keeps only fresh-install checks:
   - dump-consistency guard: `verifier.migrateAndValidate(AppDatabase(NativeDatabase.memory()), db.schemaVersion)`
     (open a *fresh* in-memory DB so `createAll()` runs, then validate against the v1 dump);
   - `isSchemaIntact` smoke test;
   - canary column checks (e.g. `nav_state.custom_theme_json`, `saved_views.icon`,
     `companies.first_day_of_week`);
   - the perf/filter index test (`PRAGMA index_list` + `EXPLAIN QUERY PLAN`).

   No historical `schema_vN` imports while there is a single version.

5. **Verify:**
   ```sh
   flutter analyze
   grep -rn "runMigrations\|db/migrations.dart" lib/ test/   # expect no matches
   flutter test test/data/db/
   flutter test
   ```

## Adding migrations again (between squashes — the normal drift flow)

Until the next squash, schema changes follow drift's standard stepwise workflow:

1. Bump `AppDatabase.schemaVersion` to N and add an `onUpgrade` step (re-introduce a
   `runMigrations` switchboard or an inline `onUpgrade` body).
2. `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/`
3. `dart run drift_dev schema generate drift_schemas/ test/generated/`
4. Add a `from → to` matrix test to `migration_test.dart`. See this file's git history (the
   pre-squash `migration_test.dart`) for the matrix idiom: `verifier.schemaAt(from)` → seed rows →
   open `AppDatabase` → `migrateAndValidate(db, db.schemaVersion)` → assert the new columns/data.
