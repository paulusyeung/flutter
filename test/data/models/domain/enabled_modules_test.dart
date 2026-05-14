import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/enabled_modules.dart';

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
}
