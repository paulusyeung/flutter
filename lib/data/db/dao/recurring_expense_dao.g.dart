// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_expense_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringExpenseDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecurringExpensesTable get recurringExpenses =>
      attachedDatabase.recurringExpenses;
  RecurringExpenseDaoManager get managers => RecurringExpenseDaoManager(this);
}

class RecurringExpenseDaoManager {
  final _$RecurringExpenseDaoMixin _db;
  RecurringExpenseDaoManager(this._db);
  $$RecurringExpensesTableTableManager get recurringExpenses =>
      $$RecurringExpensesTableTableManager(
        _db.attachedDatabase,
        _db.recurringExpenses,
      );
}
