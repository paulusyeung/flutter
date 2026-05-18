import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:admin/data/services/token_storage.dart' show kSecureStorage;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:admin/data/db/dao/bank_account_dao.dart';
import 'package:admin/data/db/dao/bank_transaction_dao.dart';
import 'package:admin/data/db/dao/client_dao.dart';
import 'package:admin/data/db/dao/companies_dao.dart';
import 'package:admin/data/db/dao/company_gateway_dao.dart';
import 'package:admin/data/db/dao/product_dao.dart';
import 'package:admin/data/db/dao/dashboard_cache_dao.dart';
import 'package:admin/data/db/dao/drafts_dao.dart';
import 'package:admin/data/db/dao/expense_category_dao.dart';
import 'package:admin/data/db/dao/expense_dao.dart';
import 'package:admin/data/db/dao/credit_dao.dart';
import 'package:admin/data/db/dao/purchase_order_dao.dart';
import 'package:admin/data/db/dao/recurring_invoice_dao.dart';
import 'package:admin/data/db/dao/group_setting_dao.dart';
import 'package:admin/data/db/dao/id_remap_dao.dart';
import 'package:admin/data/db/dao/invoice_dao.dart';
import 'package:admin/data/db/dao/quote_dao.dart';
import 'package:admin/data/db/dao/nav_state_dao.dart';
import 'package:admin/data/db/dao/outbox_dao.dart';
import 'package:admin/data/db/dao/payment_dao.dart';
import 'package:admin/data/db/dao/payment_term_dao.dart';
import 'package:admin/data/db/dao/project_dao.dart';
import 'package:admin/data/db/dao/recurring_expense_dao.dart';
import 'package:admin/data/db/dao/saved_views_dao.dart';
import 'package:admin/data/db/dao/payment_link_dao.dart';
import 'package:admin/data/db/dao/schedule_dao.dart';
import 'package:admin/data/db/dao/statics_dao.dart';
import 'package:admin/data/db/dao/sync_state_dao.dart';
import 'package:admin/data/db/dao/system_log_dao.dart';
import 'package:admin/data/db/dao/task_dao.dart';
import 'package:admin/data/db/dao/task_status_dao.dart';
import 'package:admin/data/db/dao/tax_rate_dao.dart';
import 'package:admin/data/db/dao/token_dao.dart';
import 'package:admin/data/db/dao/transaction_rule_dao.dart';
import 'package:admin/data/db/dao/user_dao.dart';
import 'package:admin/data/db/dao/webhook_dao.dart';
import 'package:admin/data/db/dao/user_settings_dao.dart';
import 'package:admin/data/db/dao/design_dao.dart';
import 'package:admin/data/db/dao/vendor_dao.dart';
import 'package:admin/data/db/migrations.dart';
import 'package:admin/data/db/tables/bank_accounts_table.dart';
import 'package:admin/data/db/tables/bank_transactions_table.dart';
import 'package:admin/data/db/tables/clients_table.dart';
import 'package:admin/data/db/tables/companies_table.dart';
import 'package:admin/data/db/tables/company_gateways_table.dart';
import 'package:admin/data/db/tables/dashboard_cache_table.dart';
import 'package:admin/data/db/tables/designs_table.dart';
import 'package:admin/data/db/tables/documents_table.dart';
import 'package:admin/data/db/tables/drafts_table.dart';
import 'package:admin/data/db/tables/expense_categories_table.dart';
import 'package:admin/data/db/tables/expenses_table.dart';
import 'package:admin/data/db/tables/group_settings_table.dart';
import 'package:admin/data/db/tables/id_remap_table.dart';
import 'package:admin/data/db/tables/credits_table.dart';
import 'package:admin/data/db/tables/purchase_orders_table.dart';
import 'package:admin/data/db/tables/recurring_invoices_table.dart';
import 'package:admin/data/db/tables/invoices_table.dart';
import 'package:admin/data/db/tables/quotes_table.dart';
import 'package:admin/data/db/tables/nav_state_table.dart';
import 'package:admin/data/db/tables/outbox_table.dart';
import 'package:admin/data/db/tables/payment_terms_table.dart';
import 'package:admin/data/db/tables/payments_table.dart';
import 'package:admin/data/db/tables/products_table.dart';
import 'package:admin/data/db/tables/projects_table.dart';
import 'package:admin/data/db/tables/recurring_expenses_table.dart';
import 'package:admin/data/db/tables/saved_views_table.dart';
import 'package:admin/data/db/tables/payment_links_table.dart';
import 'package:admin/data/db/tables/schedules_table.dart';
import 'package:admin/data/db/tables/statics_table.dart';
import 'package:admin/data/db/tables/sync_state_table.dart';
import 'package:admin/data/db/tables/system_logs_table.dart';
import 'package:admin/data/db/tables/task_statuses_table.dart';
import 'package:admin/data/db/tables/tasks_table.dart';
import 'package:admin/data/db/tables/tax_rates_table.dart';
import 'package:admin/data/db/tables/tokens_table.dart';
import 'package:admin/data/db/tables/transaction_rules_table.dart';
import 'package:admin/data/db/tables/user_settings_table.dart';
import 'package:admin/data/db/tables/user_table.dart';
import 'package:admin/data/db/tables/vendors_table.dart';
import 'package:admin/data/db/tables/webhooks_table.dart';

part 'app_database.g.dart';

final _log = Logger('AppDatabase');

@DriftDatabase(
  tables: [
    Clients,
    Products,
    Outbox,
    IdRemap,
    SyncStateRows,
    Statics,
    Drafts,
    NavState,
    Companies,
    Accounts,
    Documents,
    UserSettings,
    Users,
    DashboardCache,
    SavedViews,
    GroupSettings,
    Tasks,
    TaskStatuses,
    Projects,
    CompanyGateways,
    PaymentTerms,
    TaxRates,
    ExpenseCategories,
    Vendors,
    Expenses,
    RecurringExpenses,
    Designs,
    PaymentLinks,
    Schedules,
    Invoices,
    Quotes,
    Credits,
    PurchaseOrders,
    RecurringInvoices,
    BankAccounts,
    BankTransactions,
    TransactionRules,
    Payments,
    SystemLogs,
    Webhooks,
    Tokens,
  ],
  daos: [
    ClientDao,
    ProductDao,
    CompanyGatewayDao,
    OutboxDao,
    IdRemapDao,
    SyncStateDao,
    StaticsDao,
    DraftsDao,
    NavStateDao,
    CompaniesDao,
    UserSettingsDao,
    UserDao,
    DashboardCacheDao,
    SavedViewsDao,
    GroupSettingDao,
    TaskDao,
    TaskStatusDao,
    ProjectDao,
    PaymentTermDao,
    TaxRateDao,
    ExpenseCategoryDao,
    VendorDao,
    ExpenseDao,
    RecurringExpenseDao,
    DesignDao,
    PaymentLinkDao,
    ScheduleDao,
    InvoiceDao,
    QuoteDao,
    CreditDao,
    PurchaseOrderDao,
    RecurringInvoiceDao,
    BankAccountDao,
    BankTransactionDao,
    TransactionRuleDao,
    PaymentDao,
    SystemLogDao,
    WebhookDao,
    TokenDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 56;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Fresh installs skip `onUpgrade`, so the performance indexes the
      // v50 migration step adds for upgraders must also be created here.
      // `CREATE INDEX IF NOT EXISTS` keeps both paths idempotent.
      await createPerformanceIndexes(this);
      await createClientFilterIndexes(this);
    },
    onUpgrade: (m, from, to) async {
      await runMigrations(this, m, from, to);
    },
  );

  /// Wipe every table. Used by `logout()` and "Reset local data".
  ///
  /// Loops over [allTables] — Drift's generated list of every `@DriftTable`
  /// declared on the database — so a new entity added to the
  /// `@DriftDatabase(tables: …)` list is cleared automatically without
  /// touching this method.
  Future<void> wipe() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  /// Wipe rows for a single company across every `company_id`-scoped table.
  /// Used by Danger Zone → Purge / Delete so a destructive op on company A
  /// doesn't silently nuke pending edits on company B.
  ///
  /// Discovery is automatic: any `@DriftTable` whose `$columns` includes a
  /// column named `company_id` gets a `DELETE … WHERE company_id = ?` —
  /// adding a new company-scoped entity needs no edits here. The `companies`
  /// table itself is intentionally NOT scoped this way (the row belongs to
  /// the account record, not "to itself"), so it's never touched here. Use
  /// `companiesDao` if you need to remove the row.
  Future<void> wipeForCompany(String companyId) async {
    await transaction(() async {
      for (final table in allTables) {
        final hasCompanyId = table.$columns.any((c) => c.name == 'company_id');
        if (!hasCompanyId) continue;
        // `table.actualTableName` is the Drift-generated identifier from a
        // `@DriftTable` annotation — never user input — so the inline
        // interpolation here is safe. `companyId` is bound through the `?`
        // placeholder, so SQL injection there is impossible regardless.
        await customStatement(
          'DELETE FROM ${table.actualTableName} WHERE company_id = ?',
          [companyId],
        );
      }
    });
  }
}

/// Open the app database with recovery if the file is corrupt or its schema
/// has drifted from what the generated code expects.
///
/// Two failure modes trigger recovery (rename `<name>` → `<name>.broken.<ts>`
/// + open fresh + return `wasReset: true` so `main` routes the user to
/// `/login`):
///   1. Open / probe fails (corrupt sqlite file, irreconcilable downgrade).
///   2. Open succeeds but a table is missing a column the code expects —
///      i.e. a prior schema migration didn't fully apply on this device.
///      Without this backstop a missing column surfaces as a fatal
///      `SqliteException` deep inside login (`_persistAndActivate` INSERT)
///      with no path forward for the user. Caught here, the user just sees
///      "/login" and a fresh sync.
/// Where the SQLCipher key lives in the OS keychain. v1 — bump on format
/// changes (e.g. moving from raw-bytes to a passphrase-derived key).
const _kDbEncryptionKeyName = 'invoiceninja.db.key.v1';

/// Fetch the per-install database encryption key, generating one on first
/// launch. The key is 256 random bits, hex-encoded, stored in the platform
/// keychain via [FlutterSecureStorage] (same trust boundary as auth tokens).
///
/// Returned as a hex string suitable for the raw-bytes form of `PRAGMA key`
/// — `"x'<hex>'"` — so SQLCipher uses it directly without PBKDF2 derivation.
Future<String> _getOrCreateDbKey() async {
  // kSecureStorage pins iOS/macOS Keychain accessibility to
  // first_unlock_this_device — see token_storage.dart for the rationale.
  // Both call sites (auth tokens, this DB key) MUST use the same instance
  // so they land in the same keychain compartment.
  const secure = kSecureStorage;
  final existing = await secure.read(key: _kDbEncryptionKeyName);
  if (existing != null && existing.length == 64) return existing;
  final rng = Random.secure();
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  try {
    await secure.write(key: _kDbEncryptionKeyName, value: hex);
  } on PlatformException catch (e) {
    // errSecDuplicateItem (-25299) on macOS: an orphan item exists under
    // the same account name but our read() couldn't see its value. Common
    // after dev-build code-signing churn (the previous build wrote the
    // key under a different signing identity / accessibility flag than the
    // one we read with). We can't recover the existing key — delete the
    // orphan and retry. The SQLite file encrypted with the old key becomes
    // unreadable, but `openWithRecovery` below already handles that by
    // renaming it to `.broken.<ts>` and starting fresh. Better a fresh DB
    // than a blank window.
    if (e.code == '-25299' ||
        (e.message?.contains('already exists in the keychain') ?? false)) {
      await secure.delete(key: _kDbEncryptionKeyName);
      await secure.write(key: _kDbEncryptionKeyName, value: hex);
    } else {
      rethrow;
    }
  }
  return hex;
}

Future<({AppDatabase db, bool wasReset})> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'invoiceninja.sqlite'));
  final key = await _getOrCreateDbKey();

  Future<AppDatabase> openFresh() async {
    final executor = NativeDatabase.createInBackground(
      file,
      // SQLite3MultipleCiphers (bundled via `hooks: user_defines: sqlite3:
      // source: sqlite3mc` in pubspec.yaml) reads existing SQLCipher 4
      // databases when these three pragmas run before any other query.
      // Raw-bytes form via `x'…'` skips PBKDF2 (we already generate 256
      // random bits).
      setup: (database) {
        database.execute("PRAGMA cipher = 'sqlcipher'");
        database.execute('PRAGMA legacy = 4');
        database.execute("PRAGMA key = \"x'$key'\"");
      },
    );
    return AppDatabase(executor);
  }

  Future<({AppDatabase db, bool wasReset})> resetAndReopen() async {
    if (await file.exists()) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      await file.rename(p.join(dir.path, 'invoiceninja.sqlite.broken.$ts'));
    }
    // Keep at most the two most-recent `.broken.*` snapshots so a device
    // that hits repeated corruption doesn't accumulate encrypted PII forever.
    // Two is enough for support to compare "this failure" against "the
    // previous one"; older snapshots are unrecoverable anyway.
    await pruneBrokenDbFiles(dir);
    final db = await openFresh();
    return (db: db, wasReset: true);
  }

  try {
    final db = await openFresh();
    // Force a trivial query so a corrupt file (or wrong key — `PRAGMA key`
    // doesn't fail eagerly, the first read does) surfaces here, not later.
    // This also drives the lazy connection open + runs any pending
    // migrations.
    await db.customSelect('SELECT 1').getSingleOrNull();
    if (!await isSchemaIntact(db)) {
      _log.severe('Drift schema drift detected; resetting local data');
      await db.close();
      return resetAndReopen();
    }
    return (db: db, wasReset: false);
  } catch (e, st) {
    _log.severe('Drift open failed; recovering by resetting local data', e, st);
    return resetAndReopen();
  }
}

/// Delete `invoiceninja.sqlite.broken.<ts>` files in [dir], keeping the
/// [keep] most-recent ones (by filename timestamp suffix, ties broken by
/// modification time). Errors are logged but swallowed — sweep failure
/// must never block startup.
///
/// Exposed for tests; production calls it from `resetAndReopen` whenever a
/// new broken snapshot is created.
Future<void> pruneBrokenDbFiles(Directory dir, {int keep = 2}) async {
  try {
    if (!await dir.exists()) return;
    final candidates = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File &&
          p.basename(entity.path).startsWith('invoiceninja.sqlite.broken.')) {
        candidates.add(entity);
      }
    }
    if (candidates.length <= keep) return;
    // Sort newest first by the ts suffix; fall back to mtime when the
    // suffix can't be parsed (defensive — we always write a numeric ts).
    int tsOf(File f) {
      final suffix = p.basename(f.path).split('.').last;
      return int.tryParse(suffix) ??
          f.statSync().modified.millisecondsSinceEpoch;
    }

    candidates.sort((a, b) => tsOf(b).compareTo(tsOf(a)));
    for (final stale in candidates.skip(keep)) {
      try {
        await stale.delete();
      } catch (e) {
        _log.warning('Failed to delete stale broken DB ${stale.path}: $e');
      }
    }
  } catch (e, st) {
    _log.warning('pruneBrokenDbFiles failed', e, st);
  }
}

/// Checks every declared table's column set against what SQLite reports
/// via `PRAGMA table_info`. Returns false if any expected column or table
/// is missing — i.e. a prior schema migration didn't land on this device.
///
/// Cheaper and more reliable than `SELECT col, col, ... LIMIT 0` probes:
/// SQLite's legacy "double-quoted string fallback" (a misspelled column in
/// `SELECT "foo"` silently resolves to the string literal `'foo'`) means
/// the SELECT-probe variant misses missing columns entirely.
///
/// Exposed (not private) so integration tests can verify the drift-detection
/// path without needing the platform-specific path_provider glue around the
/// real [openAppDatabase].
Future<bool> isSchemaIntact(AppDatabase db) async {
  try {
    for (final table in db.allTables) {
      final rows = await db
          .customSelect('PRAGMA table_info(${table.actualTableName})')
          .get();
      if (rows.isEmpty) {
        _log.severe('Table missing: ${table.actualTableName}');
        return false;
      }
      final actual = rows.map((r) => r.data['name'] as String).toSet();
      for (final expected in table.columnsByName.keys) {
        if (!actual.contains(expected)) {
          _log.severe('Column missing: ${table.actualTableName}.$expected');
          return false;
        }
      }
    }
    return true;
  } catch (e, st) {
    _log.severe('Drift schema validation failed', e, st);
    return false;
  }
}
