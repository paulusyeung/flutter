// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_invoice_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringInvoiceDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecurringInvoicesTable get recurringInvoices =>
      attachedDatabase.recurringInvoices;
  RecurringInvoiceDaoManager get managers => RecurringInvoiceDaoManager(this);
}

class RecurringInvoiceDaoManager {
  final _$RecurringInvoiceDaoMixin _db;
  RecurringInvoiceDaoManager(this._db);
  $$RecurringInvoicesTableTableManager get recurringInvoices =>
      $$RecurringInvoicesTableTableManager(
        _db.attachedDatabase,
        _db.recurringInvoices,
      );
}
