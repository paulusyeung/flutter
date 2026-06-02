import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/domain/entity_type.dart';

/// Locks in the bitmask values the server contract relies on. Drifting a
/// value here breaks the Account Management → Enabled Modules screen AND
/// the sidebar visibility check downstream of `company.enabled_modules`.
void main() {
  group('enabled_modules', () {
    test('bitmask values match admin-portal kModule* constants', () {
      expect(EnabledModule.recurringInvoices.bitmask, 1);
      expect(EnabledModule.credits.bitmask, 2);
      expect(EnabledModule.quotes.bitmask, 4);
      expect(EnabledModule.tasks.bitmask, 8);
      expect(EnabledModule.expenses.bitmask, 16);
      expect(EnabledModule.projects.bitmask, 32);
      expect(EnabledModule.vendors.bitmask, 64);
      expect(EnabledModule.documents.bitmask, 128);
      expect(EnabledModule.transactions.bitmask, 256);
      expect(EnabledModule.recurringExpenses.bitmask, 512);
      expect(EnabledModule.invoices.bitmask, 4096);
      expect(EnabledModule.purchaseOrders.bitmask, 16384);
    });

    test('isModuleEnabled detects set bits', () {
      // 4096 (invoices) + 4 (quotes) + 8 (tasks) = 4108.
      const mask = 4096 | 4 | 8;
      expect(isModuleEnabled(mask, EnabledModule.invoices), isTrue);
      expect(isModuleEnabled(mask, EnabledModule.quotes), isTrue);
      expect(isModuleEnabled(mask, EnabledModule.tasks), isTrue);
      expect(isModuleEnabled(mask, EnabledModule.credits), isFalse);
      expect(isModuleEnabled(mask, EnabledModule.vendors), isFalse);
    });

    test('toggleModule is a true XOR — enable then disable round-trips', () {
      const start = 4096; // invoices on, everything else off.
      final enabled = toggleModule(start, EnabledModule.quotes);
      expect(isModuleEnabled(enabled, EnabledModule.quotes), isTrue);
      expect(isModuleEnabled(enabled, EnabledModule.invoices), isTrue);
      final disabled = toggleModule(enabled, EnabledModule.quotes);
      expect(disabled, start);
    });

    test('kEnabledModulesOrder has every module exactly once', () {
      final bitmasks = kEnabledModulesOrder.map((m) => m.bitmask).toSet();
      expect(bitmasks.length, kEnabledModulesOrder.length);
      expect(kEnabledModulesOrder.length, 12);
    });
  });

  group('moduleForEntityType', () {
    test('maps each gated entity to its module; payment shares invoices', () {
      expect(moduleForEntityType(EntityType.invoice), EnabledModule.invoices);
      expect(moduleForEntityType(EntityType.payment), EnabledModule.invoices);
      expect(
        moduleForEntityType(EntityType.recurringInvoice),
        EnabledModule.recurringInvoices,
      );
      expect(moduleForEntityType(EntityType.quote), EnabledModule.quotes);
      expect(moduleForEntityType(EntityType.credit), EnabledModule.credits);
      expect(moduleForEntityType(EntityType.project), EnabledModule.projects);
      expect(moduleForEntityType(EntityType.task), EnabledModule.tasks);
      expect(moduleForEntityType(EntityType.vendor), EnabledModule.vendors);
      expect(
        moduleForEntityType(EntityType.purchaseOrder),
        EnabledModule.purchaseOrders,
      );
      expect(moduleForEntityType(EntityType.expense), EnabledModule.expenses);
      expect(
        moduleForEntityType(EntityType.recurringExpense),
        EnabledModule.recurringExpenses,
      );
      expect(
        moduleForEntityType(EntityType.transaction),
        EnabledModule.transactions,
      );
      expect(moduleForEntityType(EntityType.document), EnabledModule.documents);
    });

    test('always-on entities have no gating module', () {
      for (final t in [
        EntityType.client,
        EntityType.product,
        EntityType.user,
        EntityType.group,
        EntityType.companyGateway,
        EntityType.paymentTerm,
        EntityType.company,
        EntityType.taskStatus,
        EntityType.expenseCategory,
      ]) {
        expect(
          moduleForEntityType(t),
          isNull,
          reason: '$t should be always-on',
        );
      }
    });

    test('every EntityType resolves without throwing', () {
      for (final t in EntityType.values) {
        moduleForEntityType(t); // switch must be exhaustive / total.
      }
    });
  });

  group('isEntityModuleEnabledForCompany', () {
    test('always-on entities are enabled regardless of mask', () {
      expect(isEntityModuleEnabledForCompany(EntityType.client, 0), isTrue);
      expect(isEntityModuleEnabledForCompany(EntityType.product, 0), isTrue);
    });

    test('gated entity follows its bit; payment follows invoices', () {
      const invoicesOnly = 4096;
      expect(
        isEntityModuleEnabledForCompany(EntityType.invoice, invoicesOnly),
        isTrue,
      );
      expect(
        isEntityModuleEnabledForCompany(EntityType.payment, invoicesOnly),
        isTrue,
      );
      expect(
        isEntityModuleEnabledForCompany(EntityType.quote, invoicesOnly),
        isFalse,
      );
      // mask 4 (quotes) — quote on, invoice off (non-zero ⇒ exact bits).
      expect(isEntityModuleEnabledForCompany(EntityType.invoice, 4), isFalse);
    });

    test('all-off mask (0) gates every module entity', () {
      // 0 = every module switched off (Settings → Enabled Modules); gated
      // entities are hidden, only always-on entities remain.
      for (final t in [
        EntityType.invoice,
        EntityType.payment,
        EntityType.quote,
        EntityType.task,
        EntityType.expense,
        EntityType.transaction,
      ]) {
        expect(
          isEntityModuleEnabledForCompany(t, 0),
          isFalse,
          reason: '$t must be gated when every module is off (mask 0)',
        );
      }
      // Always-on entities still show with everything off.
      expect(isEntityModuleEnabledForCompany(EntityType.client, 0), isTrue);
      expect(isEntityModuleEnabledForCompany(EntityType.product, 0), isTrue);
    });
  });

  group('moduleForWireName — server contract (admin-portal kModules)', () {
    test('singular / plural / item variants resolve to the same module', () {
      expect(moduleForWireName('invoice'), EnabledModule.invoices);
      expect(moduleForWireName('invoices'), EnabledModule.invoices);
      expect(moduleForWireName('invoice_items'), EnabledModule.invoices);
      expect(moduleForWireName('payment'), EnabledModule.invoices);
      expect(
        moduleForWireName('recurring_invoice'),
        EnabledModule.recurringInvoices,
      );
      expect(
        moduleForWireName('recurring_invoices'),
        EnabledModule.recurringInvoices,
      );
      expect(moduleForWireName('quote'), EnabledModule.quotes);
      expect(moduleForWireName('credit'), EnabledModule.credits);
      expect(moduleForWireName('project'), EnabledModule.projects);
      expect(moduleForWireName('task'), EnabledModule.tasks);
      expect(moduleForWireName('vendor'), EnabledModule.vendors);
      expect(moduleForWireName('purchase_order'), EnabledModule.purchaseOrders);
      expect(moduleForWireName('expense'), EnabledModule.expenses);
      expect(
        moduleForWireName('recurring_expense'),
        EnabledModule.recurringExpenses,
      );
      expect(moduleForWireName('transaction'), EnabledModule.transactions);
      expect(moduleForWireName('bank_transaction'), isNull);
      expect(moduleForWireName('document'), EnabledModule.documents);
    });

    test('non-gated wire names are always-on', () {
      for (final n in [
        'client',
        'clients',
        'client_contacts',
        'product',
        'products',
        'activities',
      ]) {
        expect(moduleForWireName(n), isNull, reason: '$n should be always-on');
      }
    });

    test('isWireModuleEnabledForCompany honours the mask', () {
      const quotesOnly = 4;
      expect(isWireModuleEnabledForCompany('quote', quotesOnly), isTrue);
      expect(isWireModuleEnabledForCompany('invoice', quotesOnly), isFalse);
      expect(isWireModuleEnabledForCompany('client', 0), isTrue);
    });

    test('all-off mask (0) gates gated wire names', () {
      expect(isWireModuleEnabledForCompany('invoice', 0), isFalse);
      expect(isWireModuleEnabledForCompany('quote', 0), isFalse);
      expect(isWireModuleEnabledForCompany('task', 0), isFalse);
      // Always-on wire names still resolve as enabled.
      expect(isWireModuleEnabledForCompany('client', 0), isTrue);
    });
  });
}
