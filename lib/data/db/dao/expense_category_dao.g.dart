// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_category_dao.dart';

// ignore_for_file: type=lint
mixin _$ExpenseCategoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExpenseCategoriesTable get expenseCategories =>
      attachedDatabase.expenseCategories;
  ExpenseCategoryDaoManager get managers => ExpenseCategoryDaoManager(this);
}

class ExpenseCategoryDaoManager {
  final _$ExpenseCategoryDaoMixin _db;
  ExpenseCategoryDaoManager(this._db);
  $$ExpenseCategoriesTableTableManager get expenseCategories =>
      $$ExpenseCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.expenseCategories,
      );
}
