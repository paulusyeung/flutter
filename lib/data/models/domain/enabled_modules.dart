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
  const EnabledModule._({
    required this.bitmask,
    required this.labelKey,
  });

  /// Bitwise flag combined into `company.enabled_modules` (sum of enabled
  /// modules). Values match admin-portal `kModule*` constants.
  final int bitmask;

  /// Localization key for the human-readable module name.
  final String labelKey;

  static const recurringInvoices =
      EnabledModule._(bitmask: 1, labelKey: 'recurring_invoices');
  static const credits =
      EnabledModule._(bitmask: 2, labelKey: 'credits');
  static const quotes =
      EnabledModule._(bitmask: 4, labelKey: 'quotes');
  static const tasks =
      EnabledModule._(bitmask: 8, labelKey: 'tasks');
  static const expenses =
      EnabledModule._(bitmask: 16, labelKey: 'expenses');
  static const projects =
      EnabledModule._(bitmask: 32, labelKey: 'projects');
  static const vendors =
      EnabledModule._(bitmask: 64, labelKey: 'vendors');
  static const documents =
      EnabledModule._(bitmask: 128, labelKey: 'documents');
  static const transactions =
      EnabledModule._(bitmask: 256, labelKey: 'transactions');
  static const recurringExpenses =
      EnabledModule._(bitmask: 512, labelKey: 'recurring_expenses');
  static const invoices =
      EnabledModule._(bitmask: 4096, labelKey: 'invoices');
  static const purchaseOrders =
      EnabledModule._(bitmask: 16384, labelKey: 'purchase_orders');
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
