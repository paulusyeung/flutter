import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/bank_transaction_repository.dart';
import 'package:admin/data/services/bank_transactions_api.dart';
import 'package:admin/ui/features/transactions/view_models/transaction_edit_view_model.dart';

class _FakeBankTransactionsApi implements BankTransactionsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  TransactionEditViewModel makeVm() => TransactionEditViewModel(
    repo: BankTransactionRepository(db: db, api: _FakeBankTransactionsApi()),
    companyId: 'co',
    bankAccountRequiredMessage: 'Please select a bank account',
  );

  group('TransactionEditViewModel.validate (E5)', () {
    test('flags the server-required bank account when none is selected', () {
      final vm = makeVm();
      expect(vm.validate(), {
        'bank_integration_id': ['Please select a bank account'],
      });
      vm.dispose();
    });

    test('passes once a bank account is selected', () {
      final vm = makeVm();
      vm.setBankAccountId('acct_1');
      expect(vm.validate(), isEmpty);
      vm.dispose();
    });
  });
}
