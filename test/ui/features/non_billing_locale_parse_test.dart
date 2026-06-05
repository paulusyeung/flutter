import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/expense_repository.dart';
import 'package:admin/data/repositories/payment_repository.dart';
import 'package:admin/data/repositories/project_repository.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/data/services/expenses_api.dart';
import 'package:admin/data/services/payments_api.dart';
import 'package:admin/data/services/projects_api.dart';
import 'package:admin/data/services/tasks_api.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';
import 'package:admin/ui/features/payments/view_models/payment_edit_view_model.dart';
import 'package:admin/ui/features/projects/view_models/project_edit_view_model.dart';
import 'package:admin/ui/features/tasks/view_models/task_edit_view_model.dart';

/// Regression: the non-billing edit VMs parsed numeric user input with raw
/// `Decimal.tryParse` / `double.tryParse`, which return null for `"12,50"` —
/// silently storing `0` for comma-decimal-locale users. They must route
/// through `parseDecimal` / `parseDouble` with the company's comma setting.
class _FakeExpensesApi implements ExpensesApi {
  @override
  Object? noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _FakePaymentsApi implements PaymentsApi {
  @override
  Object? noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _FakeProjectsApi implements ProjectsApi {
  @override
  Object? noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _FakeTasksApi implements TasksApi {
  @override
  Object? noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  final d125 = Decimal.parse('12.5');
  final d15 = Decimal.parse('1.5');

  group('expenses', () {
    ExpenseEditViewModel vm({required bool useComma}) => ExpenseEditViewModel(
      repo: ExpenseRepository(db: db, api: _FakeExpensesApi()),
      companyId: 'co',
      useCommaAsDecimalPlace: useComma,
    );

    test('comma locale: amount / foreign / rate / tax parse', () {
      final m = vm(useComma: true);
      m.setAmount('12,50');
      expect(m.draft.amount, d125);
      m.setForeignAmount('1,5');
      expect(m.draft.foreignAmount, d15);
      m.setTaxRate1('19,5');
      expect(m.draft.taxRate1, Decimal.parse('19.5'));
      m.setTaxAmount1('2,25');
      expect(m.draft.taxAmount1, Decimal.parse('2.25'));
      m.setExchangeRate('1,5');
      expect(m.draft.exchangeRate, d15);
    });

    test('comma locale: empty exchange rate falls back to 1, not 0', () {
      final m = vm(useComma: true)..setExchangeRate('');
      expect(m.draft.exchangeRate, Decimal.one);
    });

    test('dot locale: plain decimals still parse', () {
      final m = vm(useComma: false)..setAmount('12.5');
      expect(m.draft.amount, d125);
    });
  });

  group('payments', () {
    PaymentEditViewModel vm({required bool useComma}) => PaymentEditViewModel(
      repo: PaymentRepository(db: db, api: _FakePaymentsApi()),
      companyId: 'co',
      useCommaAsDecimalPlace: useComma,
    );

    test('comma locale: amount + exchange rate parse', () {
      final m = vm(useComma: true)..setAmount('12,50');
      expect(m.draft.amount, d125);
      m.setExchangeRate('1,5');
      expect(m.draft.exchangeRate, d15);
    });
  });

  group('projects', () {
    ProjectEditViewModel vm({required bool useComma}) => ProjectEditViewModel(
      repo: ProjectRepository(db: db, api: _FakeProjectsApi()),
      companyId: 'co',
      useCommaAsDecimalPlace: useComma,
    );

    test('comma locale: task rate (Decimal) + budgeted hours (double)', () {
      final m = vm(useComma: true)..setTaskRate('1,5');
      expect(m.draft.taskRate, d15);
      m.setBudgetedHours('10,5');
      expect(m.draft.budgetedHours, 10.5);
    });
  });

  group('tasks', () {
    TaskEditViewModel vm({required bool useComma}) => TaskEditViewModel(
      repo: TaskRepository(db: db, api: _FakeTasksApi()),
      companyId: 'co',
      now: () => DateTime.utc(2026, 1, 1),
      useCommaAsDecimalPlace: useComma,
    );

    test('comma locale: rate parses', () {
      final m = vm(useComma: true)..setRate('1,5');
      expect(m.draft.rate, d15);
    });
  });
}
