import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/bank_transaction_api_model.dart';
import 'package:admin/data/repositories/bank_transaction_repository.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/data/services/bank_transactions_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/ui/core/list/search/date_column_filter_key.dart';
import 'package:admin/ui/features/transactions/view_models/transaction_list_view_model.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_filter_keys.dart';

/// Captures the query `filters` the repository hands the list endpoint so we
/// can pin the exact server param names (the dataflow VM → repo → api is the
/// real production path; only the HTTP edge is faked).
class _FakeBankTransactionsApi implements BankTransactionsApi {
  final List<Map<String, String>> listFilters = [];

  @override
  Future<
    ({BankTransactionListApi data, int? cursorUpdatedAt, String? cursorId})
  >
  list({
    required int page,
    int perPage = 50,
    String? search,
    int? sinceUpdatedAt,
    String? sinceId,
    Map<String, String> filters = const {},
  }) async {
    listFilters.add(Map<String, String>.from(filters));
    return (
      data: const BankTransactionListApi(data: []),
      cursorUpdatedAt: null,
      cursorId: null,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('TransactionListViewModel — bank-account scope (B1)', () {
    late AppDatabase db;
    late _FakeBankTransactionsApi api;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      api = _FakeBankTransactionsApi();
    });
    tearDown(() async {
      await db.close();
    });

    TransactionListViewModel makeVm({String? bankAccountId}) =>
        TransactionListViewModel(
          repo: BankTransactionRepository(db: db, api: api),
          companyId: 'co',
          navStateDao: db.navStateDao,
          userSettings: UserSettingsRepository(db: db),
          searchDebounce: const Duration(milliseconds: 1),
          persistDebounce: const Duration(milliseconds: 1),
          bankAccountId: bankAccountId,
        );

    test('embedded list sends the plural bank_integration_ids param '
        '(the singular form is silently ignored server-side)', () async {
      final vm = makeVm(bankAccountId: 'acct_1');
      addTearDown(vm.dispose);

      await vm.fetchPage(
        page: 1,
        search: null,
        states: const {EntityState.active},
        extraFilters: const {},
        ignoreCursor: false,
      );

      expect(api.listFilters, isNotEmpty);
      final sent = api.listFilters.last;
      expect(sent['bank_integration_ids'], 'acct_1');
      expect(sent.containsKey('bank_integration_id'), isFalse);
    });

    test('unscoped workspace list sends no bank-account filter', () async {
      final vm = makeVm();
      addTearDown(vm.dispose);

      await vm.fetchPage(
        page: 1,
        search: null,
        states: const {EntityState.active},
        extraFilters: const {},
        ignoreCursor: false,
      );

      expect(api.listFilters, isNotEmpty);
      final sent = api.listFilters.last;
      expect(sent.containsKey('bank_integration_ids'), isFalse);
      expect(sent.containsKey('bank_integration_id'), isFalse);
    });
  });

  group('buildTransactionFilterKeys — date range (P1)', () {
    test('exposes a transaction-date range filter routing to date_range', () {
      final keys = buildTransactionFilterKeys();
      final dateKeys = keys.whereType<DateColumnFilterKey>().toList();
      expect(dateKeys, hasLength(1));
      expect(dateKeys.single.serverKey, 'date');
      expect(dateKeys.single.rangeServerKey, 'date_range');
    });
  });
}
