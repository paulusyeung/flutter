import 'package:admin/domain/entity_type.dart';

/// Bitmask values for the `company.enabled_modules` flag. Mirrors the
/// `kModule*` constants in admin-portal's `lib/constants.dart` exactly — the
/// numeric values are part of the server contract; the on-disk row, the API
/// payload, and the sidebar visibility logic all interoperate via these
/// integers.
///
/// Settings → Account Management → Enabled Modules renders one toggle per
/// entry in [kEnabledModulesOrder]. Toggling XORs the value against
/// `company.enabled_modules`.
class EnabledModule {
  const EnabledModule._({required this.bitmask, required this.labelKey});

  /// Bitwise flag combined into `company.enabled_modules` (sum of enabled
  /// modules). Values match admin-portal `kModule*` constants.
  final int bitmask;

  /// Localization key for the human-readable module name.
  final String labelKey;

  static const recurringInvoices = EnabledModule._(
    bitmask: 1,
    labelKey: 'recurring_invoices',
  );
  static const credits = EnabledModule._(bitmask: 2, labelKey: 'credits');
  static const quotes = EnabledModule._(bitmask: 4, labelKey: 'quotes');
  static const tasks = EnabledModule._(bitmask: 8, labelKey: 'tasks');
  static const expenses = EnabledModule._(bitmask: 16, labelKey: 'expenses');
  static const projects = EnabledModule._(bitmask: 32, labelKey: 'projects');
  static const vendors = EnabledModule._(bitmask: 64, labelKey: 'vendors');
  static const documents = EnabledModule._(bitmask: 128, labelKey: 'documents');
  static const transactions = EnabledModule._(
    bitmask: 256,
    labelKey: 'transactions',
  );
  static const recurringExpenses = EnabledModule._(
    bitmask: 512,
    labelKey: 'recurring_expenses',
  );
  static const invoices = EnabledModule._(bitmask: 4096, labelKey: 'invoices');
  static const purchaseOrders = EnabledModule._(
    bitmask: 16384,
    labelKey: 'purchase_orders',
  );
}

/// Render order on the Enabled Modules screen. Matches admin-portal's
/// presentation order so users porting from the old app see the same list
/// shape.
const List<EnabledModule> kEnabledModulesOrder = <EnabledModule>[
  EnabledModule.invoices,
  EnabledModule.recurringInvoices,
  EnabledModule.quotes,
  EnabledModule.credits,
  EnabledModule.projects,
  EnabledModule.tasks,
  EnabledModule.vendors,
  EnabledModule.purchaseOrders,
  EnabledModule.expenses,
  EnabledModule.recurringExpenses,
  EnabledModule.transactions,
  EnabledModule.documents,
];

/// True when the given bitmask is currently set on `enabledModules`.
bool isModuleEnabled(int enabledModules, EnabledModule module) =>
    (enabledModules & module.bitmask) != 0;

/// Toggle the given module's bit on the mask. Used by the screen's
/// `SwitchListTile.onChanged` to compute the new bitmask before saving.
int toggleModule(int enabledModules, EnabledModule module) =>
    enabledModules ^ module.bitmask;

/// The [EnabledModule] that gates an [EntityType], or `null` when the entity
/// is always available regardless of the company's module configuration
/// (client, product, and every settings-only / singleton entity).
///
/// `payment` intentionally shares the invoices module — that's the server
/// contract (admin-portal's `isModuleEnabled` treats invoice + payment as one).
EnabledModule? moduleForEntityType(EntityType type) => switch (type) {
  EntityType.invoice => EnabledModule.invoices,
  EntityType.payment => EnabledModule.invoices,
  EntityType.recurringInvoice => EnabledModule.recurringInvoices,
  EntityType.quote => EnabledModule.quotes,
  EntityType.credit => EnabledModule.credits,
  EntityType.project => EnabledModule.projects,
  EntityType.task => EnabledModule.tasks,
  EntityType.vendor => EnabledModule.vendors,
  EntityType.purchaseOrder => EnabledModule.purchaseOrders,
  EntityType.expense => EnabledModule.expenses,
  EntityType.recurringExpense => EnabledModule.recurringExpenses,
  EntityType.transaction => EnabledModule.transactions,
  EntityType.document => EnabledModule.documents,
  _ => null,
};

/// True when [type] is usable for a company with the given [enabledModules]
/// mask. Always-on entities (mapping returns `null`) are enabled regardless of
/// the mask. A `0` mask means every module is switched off (Settings → Account
/// Management → Enabled Modules), so every module-gated entity is gated — only
/// always-on entities remain.
///
/// `0` is a real "all off" value, not "unhydrated": the server always sends a
/// real mask (`/login` returns e.g. 32767), and a company that has
/// authenticated since the `enabled_modules` column existed always has its mask
/// persisted. The pure [isModuleEnabled] / [toggleModule] primitives keep
/// exact-bit semantics for the Enabled Modules toggle screen.
bool isEntityModuleEnabledForCompany(EntityType type, int enabledModules) {
  final module = moduleForEntityType(type);
  return module == null || isModuleEnabled(enabledModules, module);
}

/// Maps the API "wire" strings used by import/export/schedule pickers to their
/// gating [EnabledModule]. Keys cover the singular, plural, and `_items`
/// variants those static lists use. `null` ⇒ always-on / not module-gated
/// (clients, products, contacts, activities, bank transactions are not gated
/// by a toggle here). Bit values are the server contract — mirrors
/// admin-portal's `kModules`.
const Map<String, EnabledModule> _wireModuleByName = <String, EnabledModule>{
  'invoice': EnabledModule.invoices,
  'invoices': EnabledModule.invoices,
  'invoice_items': EnabledModule.invoices,
  'payment': EnabledModule.invoices,
  'payments': EnabledModule.invoices,
  'recurring_invoice': EnabledModule.recurringInvoices,
  'recurring_invoices': EnabledModule.recurringInvoices,
  'quote': EnabledModule.quotes,
  'quotes': EnabledModule.quotes,
  'quote_items': EnabledModule.quotes,
  'credit': EnabledModule.credits,
  'credits': EnabledModule.credits,
  'project': EnabledModule.projects,
  'projects': EnabledModule.projects,
  'task': EnabledModule.tasks,
  'tasks': EnabledModule.tasks,
  'vendor': EnabledModule.vendors,
  'vendors': EnabledModule.vendors,
  'purchase_order': EnabledModule.purchaseOrders,
  'purchase_orders': EnabledModule.purchaseOrders,
  'purchase_order_items': EnabledModule.purchaseOrders,
  'expense': EnabledModule.expenses,
  'expenses': EnabledModule.expenses,
  'recurring_expense': EnabledModule.recurringExpenses,
  'recurring_expenses': EnabledModule.recurringExpenses,
  'transaction': EnabledModule.transactions,
  'transactions': EnabledModule.transactions,
  'document': EnabledModule.documents,
  'documents': EnabledModule.documents,
};

/// The [EnabledModule] gating a wire-string entity name, or `null` when it is
/// always available. See [_wireModuleByName].
EnabledModule? moduleForWireName(String name) => _wireModuleByName[name];

/// True when the wire-string entity [name] is usable under [enabledModules].
/// A `0` mask gates every module-bound wire name; always-on names (mapping →
/// `null`) stay enabled.
bool isWireModuleEnabledForCompany(String name, int enabledModules) {
  final module = moduleForWireName(name);
  return module == null || isModuleEnabled(enabledModules, module);
}
