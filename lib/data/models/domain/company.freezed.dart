// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Company {

 String get id; String get displayName; String get name; String get companyKey; String get sizeId; String get industryId; String get firstMonthOfYear; String get firstDayOfWeek; int get enabledModules; int get legalEntityId; String get subdomain; String get portalDomain; String get portalMode; Map<String, String> get customFields; Map<String, dynamic> get rawSettings; CompanySettings get settings; bool get enableApplyingPayments; bool get convertPaymentCurrency; int get enabledTaxRates; int get enabledItemTaxRates; int get enabledExpenseTaxRates; bool get calculateTaxes; TaxConfigApi? get taxData;// Top-level product configuration. Edited by Settings → Product Settings;
// round-trips through the outbox without touching the `settings` JSON.
 bool get trackInventory; bool get stockNotification; int get inventoryNotificationThreshold; bool get enableProductDiscount; bool get enableProductCost; bool get enableProductQuantity; bool get defaultQuantity; bool get showProductDetails; bool get fillProducts; bool get updateProducts; bool get convertProducts; bool get convertRateToClient;// Top-level workflow configuration. Edited by Settings → Workflow Settings
// alongside the cascade `settings.*` workflow toggles.
 bool get stopOnUnpaidRecurring; bool get useQuoteTermsOnConversion;// Top-level task configuration. Edited by Settings → Task Settings.
 bool get autoStartTasks; bool get showTaskEndDate; bool get showTasksTable; bool get invoiceTaskDatelog; bool get invoiceTaskTimelog; bool get invoiceTaskHours; bool get invoiceTaskItemDescription; bool get invoiceTaskProject; bool get invoiceTaskProjectHeader; bool get invoiceTaskLock; bool get invoiceTaskDocuments;// Top-level expense configuration. Edited by Settings → Expense Settings.
// Cascade `defaultExpensePaymentTypeId` lives on `CompanySettings`. The
// `inboundMailbox*` block is self-hosted only.
 bool get markExpensesInvoiceable; bool get markExpensesPaid; bool get convertExpenseCurrency; bool get invoiceExpenseDocuments; bool get notifyVendorWhenPaid; bool get calculateExpenseTaxByAmount; bool get expenseInclusiveTaxes; bool get expenseMailboxActive; String get expenseMailbox; bool get inboundMailboxAllowCompanyUsers; bool get inboundMailboxAllowVendors; bool get inboundMailboxAllowClients; String get inboundMailboxWhitelist; String get inboundMailboxBlacklist; bool get inboundMailboxAllowUnknown;// Account Management → Integrations: top-level analytics fields.
 String get googleAnalyticsKey; String get matomoId; String get matomoUrl;// Account Management → Security Settings: top-level company fields.
// Timeouts in milliseconds; 0 = never time out.
 int get sessionTimeout; int get defaultPasswordTimeout; bool get oauthPasswordRequired;// Account Management → Overview: top-level company toggles.
 bool get isDisabled; bool get markdownEnabled; bool get markdownEmailEnabled; bool get reportIncludeDrafts; bool get reportIncludeDeleted; List<Document> get documents; int get updatedAt; int get archivedAt;
/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanyCopyWith<Company> get copyWith => _$CompanyCopyWithImpl<Company>(this as Company, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Company&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.firstMonthOfYear, firstMonthOfYear) || other.firstMonthOfYear == firstMonthOfYear)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.portalDomain, portalDomain) || other.portalDomain == portalDomain)&&(identical(other.portalMode, portalMode) || other.portalMode == portalMode)&&const DeepCollectionEquality().equals(other.customFields, customFields)&&const DeepCollectionEquality().equals(other.rawSettings, rawSettings)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.enableApplyingPayments, enableApplyingPayments) || other.enableApplyingPayments == enableApplyingPayments)&&(identical(other.convertPaymentCurrency, convertPaymentCurrency) || other.convertPaymentCurrency == convertPaymentCurrency)&&(identical(other.enabledTaxRates, enabledTaxRates) || other.enabledTaxRates == enabledTaxRates)&&(identical(other.enabledItemTaxRates, enabledItemTaxRates) || other.enabledItemTaxRates == enabledItemTaxRates)&&(identical(other.enabledExpenseTaxRates, enabledExpenseTaxRates) || other.enabledExpenseTaxRates == enabledExpenseTaxRates)&&(identical(other.calculateTaxes, calculateTaxes) || other.calculateTaxes == calculateTaxes)&&(identical(other.taxData, taxData) || other.taxData == taxData)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory)&&(identical(other.stockNotification, stockNotification) || other.stockNotification == stockNotification)&&(identical(other.inventoryNotificationThreshold, inventoryNotificationThreshold) || other.inventoryNotificationThreshold == inventoryNotificationThreshold)&&(identical(other.enableProductDiscount, enableProductDiscount) || other.enableProductDiscount == enableProductDiscount)&&(identical(other.enableProductCost, enableProductCost) || other.enableProductCost == enableProductCost)&&(identical(other.enableProductQuantity, enableProductQuantity) || other.enableProductQuantity == enableProductQuantity)&&(identical(other.defaultQuantity, defaultQuantity) || other.defaultQuantity == defaultQuantity)&&(identical(other.showProductDetails, showProductDetails) || other.showProductDetails == showProductDetails)&&(identical(other.fillProducts, fillProducts) || other.fillProducts == fillProducts)&&(identical(other.updateProducts, updateProducts) || other.updateProducts == updateProducts)&&(identical(other.convertProducts, convertProducts) || other.convertProducts == convertProducts)&&(identical(other.convertRateToClient, convertRateToClient) || other.convertRateToClient == convertRateToClient)&&(identical(other.stopOnUnpaidRecurring, stopOnUnpaidRecurring) || other.stopOnUnpaidRecurring == stopOnUnpaidRecurring)&&(identical(other.useQuoteTermsOnConversion, useQuoteTermsOnConversion) || other.useQuoteTermsOnConversion == useQuoteTermsOnConversion)&&(identical(other.autoStartTasks, autoStartTasks) || other.autoStartTasks == autoStartTasks)&&(identical(other.showTaskEndDate, showTaskEndDate) || other.showTaskEndDate == showTaskEndDate)&&(identical(other.showTasksTable, showTasksTable) || other.showTasksTable == showTasksTable)&&(identical(other.invoiceTaskDatelog, invoiceTaskDatelog) || other.invoiceTaskDatelog == invoiceTaskDatelog)&&(identical(other.invoiceTaskTimelog, invoiceTaskTimelog) || other.invoiceTaskTimelog == invoiceTaskTimelog)&&(identical(other.invoiceTaskHours, invoiceTaskHours) || other.invoiceTaskHours == invoiceTaskHours)&&(identical(other.invoiceTaskItemDescription, invoiceTaskItemDescription) || other.invoiceTaskItemDescription == invoiceTaskItemDescription)&&(identical(other.invoiceTaskProject, invoiceTaskProject) || other.invoiceTaskProject == invoiceTaskProject)&&(identical(other.invoiceTaskProjectHeader, invoiceTaskProjectHeader) || other.invoiceTaskProjectHeader == invoiceTaskProjectHeader)&&(identical(other.invoiceTaskLock, invoiceTaskLock) || other.invoiceTaskLock == invoiceTaskLock)&&(identical(other.invoiceTaskDocuments, invoiceTaskDocuments) || other.invoiceTaskDocuments == invoiceTaskDocuments)&&(identical(other.markExpensesInvoiceable, markExpensesInvoiceable) || other.markExpensesInvoiceable == markExpensesInvoiceable)&&(identical(other.markExpensesPaid, markExpensesPaid) || other.markExpensesPaid == markExpensesPaid)&&(identical(other.convertExpenseCurrency, convertExpenseCurrency) || other.convertExpenseCurrency == convertExpenseCurrency)&&(identical(other.invoiceExpenseDocuments, invoiceExpenseDocuments) || other.invoiceExpenseDocuments == invoiceExpenseDocuments)&&(identical(other.notifyVendorWhenPaid, notifyVendorWhenPaid) || other.notifyVendorWhenPaid == notifyVendorWhenPaid)&&(identical(other.calculateExpenseTaxByAmount, calculateExpenseTaxByAmount) || other.calculateExpenseTaxByAmount == calculateExpenseTaxByAmount)&&(identical(other.expenseInclusiveTaxes, expenseInclusiveTaxes) || other.expenseInclusiveTaxes == expenseInclusiveTaxes)&&(identical(other.expenseMailboxActive, expenseMailboxActive) || other.expenseMailboxActive == expenseMailboxActive)&&(identical(other.expenseMailbox, expenseMailbox) || other.expenseMailbox == expenseMailbox)&&(identical(other.inboundMailboxAllowCompanyUsers, inboundMailboxAllowCompanyUsers) || other.inboundMailboxAllowCompanyUsers == inboundMailboxAllowCompanyUsers)&&(identical(other.inboundMailboxAllowVendors, inboundMailboxAllowVendors) || other.inboundMailboxAllowVendors == inboundMailboxAllowVendors)&&(identical(other.inboundMailboxAllowClients, inboundMailboxAllowClients) || other.inboundMailboxAllowClients == inboundMailboxAllowClients)&&(identical(other.inboundMailboxWhitelist, inboundMailboxWhitelist) || other.inboundMailboxWhitelist == inboundMailboxWhitelist)&&(identical(other.inboundMailboxBlacklist, inboundMailboxBlacklist) || other.inboundMailboxBlacklist == inboundMailboxBlacklist)&&(identical(other.inboundMailboxAllowUnknown, inboundMailboxAllowUnknown) || other.inboundMailboxAllowUnknown == inboundMailboxAllowUnknown)&&(identical(other.googleAnalyticsKey, googleAnalyticsKey) || other.googleAnalyticsKey == googleAnalyticsKey)&&(identical(other.matomoId, matomoId) || other.matomoId == matomoId)&&(identical(other.matomoUrl, matomoUrl) || other.matomoUrl == matomoUrl)&&(identical(other.sessionTimeout, sessionTimeout) || other.sessionTimeout == sessionTimeout)&&(identical(other.defaultPasswordTimeout, defaultPasswordTimeout) || other.defaultPasswordTimeout == defaultPasswordTimeout)&&(identical(other.oauthPasswordRequired, oauthPasswordRequired) || other.oauthPasswordRequired == oauthPasswordRequired)&&(identical(other.isDisabled, isDisabled) || other.isDisabled == isDisabled)&&(identical(other.markdownEnabled, markdownEnabled) || other.markdownEnabled == markdownEnabled)&&(identical(other.markdownEmailEnabled, markdownEmailEnabled) || other.markdownEmailEnabled == markdownEmailEnabled)&&(identical(other.reportIncludeDrafts, reportIncludeDrafts) || other.reportIncludeDrafts == reportIncludeDrafts)&&(identical(other.reportIncludeDeleted, reportIncludeDeleted) || other.reportIncludeDeleted == reportIncludeDeleted)&&const DeepCollectionEquality().equals(other.documents, documents)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,name,companyKey,sizeId,industryId,firstMonthOfYear,firstDayOfWeek,enabledModules,legalEntityId,subdomain,portalDomain,portalMode,const DeepCollectionEquality().hash(customFields),const DeepCollectionEquality().hash(rawSettings),settings,enableApplyingPayments,convertPaymentCurrency,enabledTaxRates,enabledItemTaxRates,enabledExpenseTaxRates,calculateTaxes,taxData,trackInventory,stockNotification,inventoryNotificationThreshold,enableProductDiscount,enableProductCost,enableProductQuantity,defaultQuantity,showProductDetails,fillProducts,updateProducts,convertProducts,convertRateToClient,stopOnUnpaidRecurring,useQuoteTermsOnConversion,autoStartTasks,showTaskEndDate,showTasksTable,invoiceTaskDatelog,invoiceTaskTimelog,invoiceTaskHours,invoiceTaskItemDescription,invoiceTaskProject,invoiceTaskProjectHeader,invoiceTaskLock,invoiceTaskDocuments,markExpensesInvoiceable,markExpensesPaid,convertExpenseCurrency,invoiceExpenseDocuments,notifyVendorWhenPaid,calculateExpenseTaxByAmount,expenseInclusiveTaxes,expenseMailboxActive,expenseMailbox,inboundMailboxAllowCompanyUsers,inboundMailboxAllowVendors,inboundMailboxAllowClients,inboundMailboxWhitelist,inboundMailboxBlacklist,inboundMailboxAllowUnknown,googleAnalyticsKey,matomoId,matomoUrl,sessionTimeout,defaultPasswordTimeout,oauthPasswordRequired,isDisabled,markdownEnabled,markdownEmailEnabled,reportIncludeDrafts,reportIncludeDeleted,const DeepCollectionEquality().hash(documents),updatedAt,archivedAt]);

@override
String toString() {
  return 'Company(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, rawSettings: $rawSettings, settings: $settings, enableApplyingPayments: $enableApplyingPayments, convertPaymentCurrency: $convertPaymentCurrency, enabledTaxRates: $enabledTaxRates, enabledItemTaxRates: $enabledItemTaxRates, enabledExpenseTaxRates: $enabledExpenseTaxRates, calculateTaxes: $calculateTaxes, taxData: $taxData, trackInventory: $trackInventory, stockNotification: $stockNotification, inventoryNotificationThreshold: $inventoryNotificationThreshold, enableProductDiscount: $enableProductDiscount, enableProductCost: $enableProductCost, enableProductQuantity: $enableProductQuantity, defaultQuantity: $defaultQuantity, showProductDetails: $showProductDetails, fillProducts: $fillProducts, updateProducts: $updateProducts, convertProducts: $convertProducts, convertRateToClient: $convertRateToClient, stopOnUnpaidRecurring: $stopOnUnpaidRecurring, useQuoteTermsOnConversion: $useQuoteTermsOnConversion, autoStartTasks: $autoStartTasks, showTaskEndDate: $showTaskEndDate, showTasksTable: $showTasksTable, invoiceTaskDatelog: $invoiceTaskDatelog, invoiceTaskTimelog: $invoiceTaskTimelog, invoiceTaskHours: $invoiceTaskHours, invoiceTaskItemDescription: $invoiceTaskItemDescription, invoiceTaskProject: $invoiceTaskProject, invoiceTaskProjectHeader: $invoiceTaskProjectHeader, invoiceTaskLock: $invoiceTaskLock, invoiceTaskDocuments: $invoiceTaskDocuments, markExpensesInvoiceable: $markExpensesInvoiceable, markExpensesPaid: $markExpensesPaid, convertExpenseCurrency: $convertExpenseCurrency, invoiceExpenseDocuments: $invoiceExpenseDocuments, notifyVendorWhenPaid: $notifyVendorWhenPaid, calculateExpenseTaxByAmount: $calculateExpenseTaxByAmount, expenseInclusiveTaxes: $expenseInclusiveTaxes, expenseMailboxActive: $expenseMailboxActive, expenseMailbox: $expenseMailbox, inboundMailboxAllowCompanyUsers: $inboundMailboxAllowCompanyUsers, inboundMailboxAllowVendors: $inboundMailboxAllowVendors, inboundMailboxAllowClients: $inboundMailboxAllowClients, inboundMailboxWhitelist: $inboundMailboxWhitelist, inboundMailboxBlacklist: $inboundMailboxBlacklist, inboundMailboxAllowUnknown: $inboundMailboxAllowUnknown, googleAnalyticsKey: $googleAnalyticsKey, matomoId: $matomoId, matomoUrl: $matomoUrl, sessionTimeout: $sessionTimeout, defaultPasswordTimeout: $defaultPasswordTimeout, oauthPasswordRequired: $oauthPasswordRequired, isDisabled: $isDisabled, markdownEnabled: $markdownEnabled, markdownEmailEnabled: $markdownEmailEnabled, reportIncludeDrafts: $reportIncludeDrafts, reportIncludeDeleted: $reportIncludeDeleted, documents: $documents, updatedAt: $updatedAt, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class $CompanyCopyWith<$Res>  {
  factory $CompanyCopyWith(Company value, $Res Function(Company) _then) = _$CompanyCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String name, String companyKey, String sizeId, String industryId, String firstMonthOfYear, String firstDayOfWeek, int enabledModules, int legalEntityId, String subdomain, String portalDomain, String portalMode, Map<String, String> customFields, Map<String, dynamic> rawSettings, CompanySettings settings, bool enableApplyingPayments, bool convertPaymentCurrency, int enabledTaxRates, int enabledItemTaxRates, int enabledExpenseTaxRates, bool calculateTaxes, TaxConfigApi? taxData, bool trackInventory, bool stockNotification, int inventoryNotificationThreshold, bool enableProductDiscount, bool enableProductCost, bool enableProductQuantity, bool defaultQuantity, bool showProductDetails, bool fillProducts, bool updateProducts, bool convertProducts, bool convertRateToClient, bool stopOnUnpaidRecurring, bool useQuoteTermsOnConversion, bool autoStartTasks, bool showTaskEndDate, bool showTasksTable, bool invoiceTaskDatelog, bool invoiceTaskTimelog, bool invoiceTaskHours, bool invoiceTaskItemDescription, bool invoiceTaskProject, bool invoiceTaskProjectHeader, bool invoiceTaskLock, bool invoiceTaskDocuments, bool markExpensesInvoiceable, bool markExpensesPaid, bool convertExpenseCurrency, bool invoiceExpenseDocuments, bool notifyVendorWhenPaid, bool calculateExpenseTaxByAmount, bool expenseInclusiveTaxes, bool expenseMailboxActive, String expenseMailbox, bool inboundMailboxAllowCompanyUsers, bool inboundMailboxAllowVendors, bool inboundMailboxAllowClients, String inboundMailboxWhitelist, String inboundMailboxBlacklist, bool inboundMailboxAllowUnknown, String googleAnalyticsKey, String matomoId, String matomoUrl, int sessionTimeout, int defaultPasswordTimeout, bool oauthPasswordRequired, bool isDisabled, bool markdownEnabled, bool markdownEmailEnabled, bool reportIncludeDrafts, bool reportIncludeDeleted, List<Document> documents, int updatedAt, int archivedAt
});


$CompanySettingsApiCopyWith<$Res> get settings;$TaxConfigApiCopyWith<$Res>? get taxData;

}
/// @nodoc
class _$CompanyCopyWithImpl<$Res>
    implements $CompanyCopyWith<$Res> {
  _$CompanyCopyWithImpl(this._self, this._then);

  final Company _self;
  final $Res Function(Company) _then;

/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? sizeId = null,Object? industryId = null,Object? firstMonthOfYear = null,Object? firstDayOfWeek = null,Object? enabledModules = null,Object? legalEntityId = null,Object? subdomain = null,Object? portalDomain = null,Object? portalMode = null,Object? customFields = null,Object? rawSettings = null,Object? settings = null,Object? enableApplyingPayments = null,Object? convertPaymentCurrency = null,Object? enabledTaxRates = null,Object? enabledItemTaxRates = null,Object? enabledExpenseTaxRates = null,Object? calculateTaxes = null,Object? taxData = freezed,Object? trackInventory = null,Object? stockNotification = null,Object? inventoryNotificationThreshold = null,Object? enableProductDiscount = null,Object? enableProductCost = null,Object? enableProductQuantity = null,Object? defaultQuantity = null,Object? showProductDetails = null,Object? fillProducts = null,Object? updateProducts = null,Object? convertProducts = null,Object? convertRateToClient = null,Object? stopOnUnpaidRecurring = null,Object? useQuoteTermsOnConversion = null,Object? autoStartTasks = null,Object? showTaskEndDate = null,Object? showTasksTable = null,Object? invoiceTaskDatelog = null,Object? invoiceTaskTimelog = null,Object? invoiceTaskHours = null,Object? invoiceTaskItemDescription = null,Object? invoiceTaskProject = null,Object? invoiceTaskProjectHeader = null,Object? invoiceTaskLock = null,Object? invoiceTaskDocuments = null,Object? markExpensesInvoiceable = null,Object? markExpensesPaid = null,Object? convertExpenseCurrency = null,Object? invoiceExpenseDocuments = null,Object? notifyVendorWhenPaid = null,Object? calculateExpenseTaxByAmount = null,Object? expenseInclusiveTaxes = null,Object? expenseMailboxActive = null,Object? expenseMailbox = null,Object? inboundMailboxAllowCompanyUsers = null,Object? inboundMailboxAllowVendors = null,Object? inboundMailboxAllowClients = null,Object? inboundMailboxWhitelist = null,Object? inboundMailboxBlacklist = null,Object? inboundMailboxAllowUnknown = null,Object? googleAnalyticsKey = null,Object? matomoId = null,Object? matomoUrl = null,Object? sessionTimeout = null,Object? defaultPasswordTimeout = null,Object? oauthPasswordRequired = null,Object? isDisabled = null,Object? markdownEnabled = null,Object? markdownEmailEnabled = null,Object? reportIncludeDrafts = null,Object? reportIncludeDeleted = null,Object? documents = null,Object? updatedAt = null,Object? archivedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,companyKey: null == companyKey ? _self.companyKey : companyKey // ignore: cast_nullable_to_non_nullable
as String,sizeId: null == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String,industryId: null == industryId ? _self.industryId : industryId // ignore: cast_nullable_to_non_nullable
as String,firstMonthOfYear: null == firstMonthOfYear ? _self.firstMonthOfYear : firstMonthOfYear // ignore: cast_nullable_to_non_nullable
as String,firstDayOfWeek: null == firstDayOfWeek ? _self.firstDayOfWeek : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
as String,enabledModules: null == enabledModules ? _self.enabledModules : enabledModules // ignore: cast_nullable_to_non_nullable
as int,legalEntityId: null == legalEntityId ? _self.legalEntityId : legalEntityId // ignore: cast_nullable_to_non_nullable
as int,subdomain: null == subdomain ? _self.subdomain : subdomain // ignore: cast_nullable_to_non_nullable
as String,portalDomain: null == portalDomain ? _self.portalDomain : portalDomain // ignore: cast_nullable_to_non_nullable
as String,portalMode: null == portalMode ? _self.portalMode : portalMode // ignore: cast_nullable_to_non_nullable
as String,customFields: null == customFields ? _self.customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,rawSettings: null == rawSettings ? _self.rawSettings : rawSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CompanySettings,enableApplyingPayments: null == enableApplyingPayments ? _self.enableApplyingPayments : enableApplyingPayments // ignore: cast_nullable_to_non_nullable
as bool,convertPaymentCurrency: null == convertPaymentCurrency ? _self.convertPaymentCurrency : convertPaymentCurrency // ignore: cast_nullable_to_non_nullable
as bool,enabledTaxRates: null == enabledTaxRates ? _self.enabledTaxRates : enabledTaxRates // ignore: cast_nullable_to_non_nullable
as int,enabledItemTaxRates: null == enabledItemTaxRates ? _self.enabledItemTaxRates : enabledItemTaxRates // ignore: cast_nullable_to_non_nullable
as int,enabledExpenseTaxRates: null == enabledExpenseTaxRates ? _self.enabledExpenseTaxRates : enabledExpenseTaxRates // ignore: cast_nullable_to_non_nullable
as int,calculateTaxes: null == calculateTaxes ? _self.calculateTaxes : calculateTaxes // ignore: cast_nullable_to_non_nullable
as bool,taxData: freezed == taxData ? _self.taxData : taxData // ignore: cast_nullable_to_non_nullable
as TaxConfigApi?,trackInventory: null == trackInventory ? _self.trackInventory : trackInventory // ignore: cast_nullable_to_non_nullable
as bool,stockNotification: null == stockNotification ? _self.stockNotification : stockNotification // ignore: cast_nullable_to_non_nullable
as bool,inventoryNotificationThreshold: null == inventoryNotificationThreshold ? _self.inventoryNotificationThreshold : inventoryNotificationThreshold // ignore: cast_nullable_to_non_nullable
as int,enableProductDiscount: null == enableProductDiscount ? _self.enableProductDiscount : enableProductDiscount // ignore: cast_nullable_to_non_nullable
as bool,enableProductCost: null == enableProductCost ? _self.enableProductCost : enableProductCost // ignore: cast_nullable_to_non_nullable
as bool,enableProductQuantity: null == enableProductQuantity ? _self.enableProductQuantity : enableProductQuantity // ignore: cast_nullable_to_non_nullable
as bool,defaultQuantity: null == defaultQuantity ? _self.defaultQuantity : defaultQuantity // ignore: cast_nullable_to_non_nullable
as bool,showProductDetails: null == showProductDetails ? _self.showProductDetails : showProductDetails // ignore: cast_nullable_to_non_nullable
as bool,fillProducts: null == fillProducts ? _self.fillProducts : fillProducts // ignore: cast_nullable_to_non_nullable
as bool,updateProducts: null == updateProducts ? _self.updateProducts : updateProducts // ignore: cast_nullable_to_non_nullable
as bool,convertProducts: null == convertProducts ? _self.convertProducts : convertProducts // ignore: cast_nullable_to_non_nullable
as bool,convertRateToClient: null == convertRateToClient ? _self.convertRateToClient : convertRateToClient // ignore: cast_nullable_to_non_nullable
as bool,stopOnUnpaidRecurring: null == stopOnUnpaidRecurring ? _self.stopOnUnpaidRecurring : stopOnUnpaidRecurring // ignore: cast_nullable_to_non_nullable
as bool,useQuoteTermsOnConversion: null == useQuoteTermsOnConversion ? _self.useQuoteTermsOnConversion : useQuoteTermsOnConversion // ignore: cast_nullable_to_non_nullable
as bool,autoStartTasks: null == autoStartTasks ? _self.autoStartTasks : autoStartTasks // ignore: cast_nullable_to_non_nullable
as bool,showTaskEndDate: null == showTaskEndDate ? _self.showTaskEndDate : showTaskEndDate // ignore: cast_nullable_to_non_nullable
as bool,showTasksTable: null == showTasksTable ? _self.showTasksTable : showTasksTable // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskDatelog: null == invoiceTaskDatelog ? _self.invoiceTaskDatelog : invoiceTaskDatelog // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskTimelog: null == invoiceTaskTimelog ? _self.invoiceTaskTimelog : invoiceTaskTimelog // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskHours: null == invoiceTaskHours ? _self.invoiceTaskHours : invoiceTaskHours // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskItemDescription: null == invoiceTaskItemDescription ? _self.invoiceTaskItemDescription : invoiceTaskItemDescription // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskProject: null == invoiceTaskProject ? _self.invoiceTaskProject : invoiceTaskProject // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskProjectHeader: null == invoiceTaskProjectHeader ? _self.invoiceTaskProjectHeader : invoiceTaskProjectHeader // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskLock: null == invoiceTaskLock ? _self.invoiceTaskLock : invoiceTaskLock // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskDocuments: null == invoiceTaskDocuments ? _self.invoiceTaskDocuments : invoiceTaskDocuments // ignore: cast_nullable_to_non_nullable
as bool,markExpensesInvoiceable: null == markExpensesInvoiceable ? _self.markExpensesInvoiceable : markExpensesInvoiceable // ignore: cast_nullable_to_non_nullable
as bool,markExpensesPaid: null == markExpensesPaid ? _self.markExpensesPaid : markExpensesPaid // ignore: cast_nullable_to_non_nullable
as bool,convertExpenseCurrency: null == convertExpenseCurrency ? _self.convertExpenseCurrency : convertExpenseCurrency // ignore: cast_nullable_to_non_nullable
as bool,invoiceExpenseDocuments: null == invoiceExpenseDocuments ? _self.invoiceExpenseDocuments : invoiceExpenseDocuments // ignore: cast_nullable_to_non_nullable
as bool,notifyVendorWhenPaid: null == notifyVendorWhenPaid ? _self.notifyVendorWhenPaid : notifyVendorWhenPaid // ignore: cast_nullable_to_non_nullable
as bool,calculateExpenseTaxByAmount: null == calculateExpenseTaxByAmount ? _self.calculateExpenseTaxByAmount : calculateExpenseTaxByAmount // ignore: cast_nullable_to_non_nullable
as bool,expenseInclusiveTaxes: null == expenseInclusiveTaxes ? _self.expenseInclusiveTaxes : expenseInclusiveTaxes // ignore: cast_nullable_to_non_nullable
as bool,expenseMailboxActive: null == expenseMailboxActive ? _self.expenseMailboxActive : expenseMailboxActive // ignore: cast_nullable_to_non_nullable
as bool,expenseMailbox: null == expenseMailbox ? _self.expenseMailbox : expenseMailbox // ignore: cast_nullable_to_non_nullable
as String,inboundMailboxAllowCompanyUsers: null == inboundMailboxAllowCompanyUsers ? _self.inboundMailboxAllowCompanyUsers : inboundMailboxAllowCompanyUsers // ignore: cast_nullable_to_non_nullable
as bool,inboundMailboxAllowVendors: null == inboundMailboxAllowVendors ? _self.inboundMailboxAllowVendors : inboundMailboxAllowVendors // ignore: cast_nullable_to_non_nullable
as bool,inboundMailboxAllowClients: null == inboundMailboxAllowClients ? _self.inboundMailboxAllowClients : inboundMailboxAllowClients // ignore: cast_nullable_to_non_nullable
as bool,inboundMailboxWhitelist: null == inboundMailboxWhitelist ? _self.inboundMailboxWhitelist : inboundMailboxWhitelist // ignore: cast_nullable_to_non_nullable
as String,inboundMailboxBlacklist: null == inboundMailboxBlacklist ? _self.inboundMailboxBlacklist : inboundMailboxBlacklist // ignore: cast_nullable_to_non_nullable
as String,inboundMailboxAllowUnknown: null == inboundMailboxAllowUnknown ? _self.inboundMailboxAllowUnknown : inboundMailboxAllowUnknown // ignore: cast_nullable_to_non_nullable
as bool,googleAnalyticsKey: null == googleAnalyticsKey ? _self.googleAnalyticsKey : googleAnalyticsKey // ignore: cast_nullable_to_non_nullable
as String,matomoId: null == matomoId ? _self.matomoId : matomoId // ignore: cast_nullable_to_non_nullable
as String,matomoUrl: null == matomoUrl ? _self.matomoUrl : matomoUrl // ignore: cast_nullable_to_non_nullable
as String,sessionTimeout: null == sessionTimeout ? _self.sessionTimeout : sessionTimeout // ignore: cast_nullable_to_non_nullable
as int,defaultPasswordTimeout: null == defaultPasswordTimeout ? _self.defaultPasswordTimeout : defaultPasswordTimeout // ignore: cast_nullable_to_non_nullable
as int,oauthPasswordRequired: null == oauthPasswordRequired ? _self.oauthPasswordRequired : oauthPasswordRequired // ignore: cast_nullable_to_non_nullable
as bool,isDisabled: null == isDisabled ? _self.isDisabled : isDisabled // ignore: cast_nullable_to_non_nullable
as bool,markdownEnabled: null == markdownEnabled ? _self.markdownEnabled : markdownEnabled // ignore: cast_nullable_to_non_nullable
as bool,markdownEmailEnabled: null == markdownEmailEnabled ? _self.markdownEmailEnabled : markdownEmailEnabled // ignore: cast_nullable_to_non_nullable
as bool,reportIncludeDrafts: null == reportIncludeDrafts ? _self.reportIncludeDrafts : reportIncludeDrafts // ignore: cast_nullable_to_non_nullable
as bool,reportIncludeDeleted: null == reportIncludeDeleted ? _self.reportIncludeDeleted : reportIncludeDeleted // ignore: cast_nullable_to_non_nullable
as bool,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompanySettingsApiCopyWith<$Res> get settings {
  
  return $CompanySettingsApiCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaxConfigApiCopyWith<$Res>? get taxData {
    if (_self.taxData == null) {
    return null;
  }

  return $TaxConfigApiCopyWith<$Res>(_self.taxData!, (value) {
    return _then(_self.copyWith(taxData: value));
  });
}
}


/// Adds pattern-matching-related methods to [Company].
extension CompanyPatterns on Company {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Company value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Company() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Company value)  $default,){
final _that = this;
switch (_that) {
case _Company():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Company value)?  $default,){
final _that = this;
switch (_that) {
case _Company() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String name,  String companyKey,  String sizeId,  String industryId,  String firstMonthOfYear,  String firstDayOfWeek,  int enabledModules,  int legalEntityId,  String subdomain,  String portalDomain,  String portalMode,  Map<String, String> customFields,  Map<String, dynamic> rawSettings,  CompanySettings settings,  bool enableApplyingPayments,  bool convertPaymentCurrency,  int enabledTaxRates,  int enabledItemTaxRates,  int enabledExpenseTaxRates,  bool calculateTaxes,  TaxConfigApi? taxData,  bool trackInventory,  bool stockNotification,  int inventoryNotificationThreshold,  bool enableProductDiscount,  bool enableProductCost,  bool enableProductQuantity,  bool defaultQuantity,  bool showProductDetails,  bool fillProducts,  bool updateProducts,  bool convertProducts,  bool convertRateToClient,  bool stopOnUnpaidRecurring,  bool useQuoteTermsOnConversion,  bool autoStartTasks,  bool showTaskEndDate,  bool showTasksTable,  bool invoiceTaskDatelog,  bool invoiceTaskTimelog,  bool invoiceTaskHours,  bool invoiceTaskItemDescription,  bool invoiceTaskProject,  bool invoiceTaskProjectHeader,  bool invoiceTaskLock,  bool invoiceTaskDocuments,  bool markExpensesInvoiceable,  bool markExpensesPaid,  bool convertExpenseCurrency,  bool invoiceExpenseDocuments,  bool notifyVendorWhenPaid,  bool calculateExpenseTaxByAmount,  bool expenseInclusiveTaxes,  bool expenseMailboxActive,  String expenseMailbox,  bool inboundMailboxAllowCompanyUsers,  bool inboundMailboxAllowVendors,  bool inboundMailboxAllowClients,  String inboundMailboxWhitelist,  String inboundMailboxBlacklist,  bool inboundMailboxAllowUnknown,  String googleAnalyticsKey,  String matomoId,  String matomoUrl,  int sessionTimeout,  int defaultPasswordTimeout,  bool oauthPasswordRequired,  bool isDisabled,  bool markdownEnabled,  bool markdownEmailEnabled,  bool reportIncludeDrafts,  bool reportIncludeDeleted,  List<Document> documents,  int updatedAt,  int archivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Company() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.rawSettings,_that.settings,_that.enableApplyingPayments,_that.convertPaymentCurrency,_that.enabledTaxRates,_that.enabledItemTaxRates,_that.enabledExpenseTaxRates,_that.calculateTaxes,_that.taxData,_that.trackInventory,_that.stockNotification,_that.inventoryNotificationThreshold,_that.enableProductDiscount,_that.enableProductCost,_that.enableProductQuantity,_that.defaultQuantity,_that.showProductDetails,_that.fillProducts,_that.updateProducts,_that.convertProducts,_that.convertRateToClient,_that.stopOnUnpaidRecurring,_that.useQuoteTermsOnConversion,_that.autoStartTasks,_that.showTaskEndDate,_that.showTasksTable,_that.invoiceTaskDatelog,_that.invoiceTaskTimelog,_that.invoiceTaskHours,_that.invoiceTaskItemDescription,_that.invoiceTaskProject,_that.invoiceTaskProjectHeader,_that.invoiceTaskLock,_that.invoiceTaskDocuments,_that.markExpensesInvoiceable,_that.markExpensesPaid,_that.convertExpenseCurrency,_that.invoiceExpenseDocuments,_that.notifyVendorWhenPaid,_that.calculateExpenseTaxByAmount,_that.expenseInclusiveTaxes,_that.expenseMailboxActive,_that.expenseMailbox,_that.inboundMailboxAllowCompanyUsers,_that.inboundMailboxAllowVendors,_that.inboundMailboxAllowClients,_that.inboundMailboxWhitelist,_that.inboundMailboxBlacklist,_that.inboundMailboxAllowUnknown,_that.googleAnalyticsKey,_that.matomoId,_that.matomoUrl,_that.sessionTimeout,_that.defaultPasswordTimeout,_that.oauthPasswordRequired,_that.isDisabled,_that.markdownEnabled,_that.markdownEmailEnabled,_that.reportIncludeDrafts,_that.reportIncludeDeleted,_that.documents,_that.updatedAt,_that.archivedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String name,  String companyKey,  String sizeId,  String industryId,  String firstMonthOfYear,  String firstDayOfWeek,  int enabledModules,  int legalEntityId,  String subdomain,  String portalDomain,  String portalMode,  Map<String, String> customFields,  Map<String, dynamic> rawSettings,  CompanySettings settings,  bool enableApplyingPayments,  bool convertPaymentCurrency,  int enabledTaxRates,  int enabledItemTaxRates,  int enabledExpenseTaxRates,  bool calculateTaxes,  TaxConfigApi? taxData,  bool trackInventory,  bool stockNotification,  int inventoryNotificationThreshold,  bool enableProductDiscount,  bool enableProductCost,  bool enableProductQuantity,  bool defaultQuantity,  bool showProductDetails,  bool fillProducts,  bool updateProducts,  bool convertProducts,  bool convertRateToClient,  bool stopOnUnpaidRecurring,  bool useQuoteTermsOnConversion,  bool autoStartTasks,  bool showTaskEndDate,  bool showTasksTable,  bool invoiceTaskDatelog,  bool invoiceTaskTimelog,  bool invoiceTaskHours,  bool invoiceTaskItemDescription,  bool invoiceTaskProject,  bool invoiceTaskProjectHeader,  bool invoiceTaskLock,  bool invoiceTaskDocuments,  bool markExpensesInvoiceable,  bool markExpensesPaid,  bool convertExpenseCurrency,  bool invoiceExpenseDocuments,  bool notifyVendorWhenPaid,  bool calculateExpenseTaxByAmount,  bool expenseInclusiveTaxes,  bool expenseMailboxActive,  String expenseMailbox,  bool inboundMailboxAllowCompanyUsers,  bool inboundMailboxAllowVendors,  bool inboundMailboxAllowClients,  String inboundMailboxWhitelist,  String inboundMailboxBlacklist,  bool inboundMailboxAllowUnknown,  String googleAnalyticsKey,  String matomoId,  String matomoUrl,  int sessionTimeout,  int defaultPasswordTimeout,  bool oauthPasswordRequired,  bool isDisabled,  bool markdownEnabled,  bool markdownEmailEnabled,  bool reportIncludeDrafts,  bool reportIncludeDeleted,  List<Document> documents,  int updatedAt,  int archivedAt)  $default,) {final _that = this;
switch (_that) {
case _Company():
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.rawSettings,_that.settings,_that.enableApplyingPayments,_that.convertPaymentCurrency,_that.enabledTaxRates,_that.enabledItemTaxRates,_that.enabledExpenseTaxRates,_that.calculateTaxes,_that.taxData,_that.trackInventory,_that.stockNotification,_that.inventoryNotificationThreshold,_that.enableProductDiscount,_that.enableProductCost,_that.enableProductQuantity,_that.defaultQuantity,_that.showProductDetails,_that.fillProducts,_that.updateProducts,_that.convertProducts,_that.convertRateToClient,_that.stopOnUnpaidRecurring,_that.useQuoteTermsOnConversion,_that.autoStartTasks,_that.showTaskEndDate,_that.showTasksTable,_that.invoiceTaskDatelog,_that.invoiceTaskTimelog,_that.invoiceTaskHours,_that.invoiceTaskItemDescription,_that.invoiceTaskProject,_that.invoiceTaskProjectHeader,_that.invoiceTaskLock,_that.invoiceTaskDocuments,_that.markExpensesInvoiceable,_that.markExpensesPaid,_that.convertExpenseCurrency,_that.invoiceExpenseDocuments,_that.notifyVendorWhenPaid,_that.calculateExpenseTaxByAmount,_that.expenseInclusiveTaxes,_that.expenseMailboxActive,_that.expenseMailbox,_that.inboundMailboxAllowCompanyUsers,_that.inboundMailboxAllowVendors,_that.inboundMailboxAllowClients,_that.inboundMailboxWhitelist,_that.inboundMailboxBlacklist,_that.inboundMailboxAllowUnknown,_that.googleAnalyticsKey,_that.matomoId,_that.matomoUrl,_that.sessionTimeout,_that.defaultPasswordTimeout,_that.oauthPasswordRequired,_that.isDisabled,_that.markdownEnabled,_that.markdownEmailEnabled,_that.reportIncludeDrafts,_that.reportIncludeDeleted,_that.documents,_that.updatedAt,_that.archivedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String name,  String companyKey,  String sizeId,  String industryId,  String firstMonthOfYear,  String firstDayOfWeek,  int enabledModules,  int legalEntityId,  String subdomain,  String portalDomain,  String portalMode,  Map<String, String> customFields,  Map<String, dynamic> rawSettings,  CompanySettings settings,  bool enableApplyingPayments,  bool convertPaymentCurrency,  int enabledTaxRates,  int enabledItemTaxRates,  int enabledExpenseTaxRates,  bool calculateTaxes,  TaxConfigApi? taxData,  bool trackInventory,  bool stockNotification,  int inventoryNotificationThreshold,  bool enableProductDiscount,  bool enableProductCost,  bool enableProductQuantity,  bool defaultQuantity,  bool showProductDetails,  bool fillProducts,  bool updateProducts,  bool convertProducts,  bool convertRateToClient,  bool stopOnUnpaidRecurring,  bool useQuoteTermsOnConversion,  bool autoStartTasks,  bool showTaskEndDate,  bool showTasksTable,  bool invoiceTaskDatelog,  bool invoiceTaskTimelog,  bool invoiceTaskHours,  bool invoiceTaskItemDescription,  bool invoiceTaskProject,  bool invoiceTaskProjectHeader,  bool invoiceTaskLock,  bool invoiceTaskDocuments,  bool markExpensesInvoiceable,  bool markExpensesPaid,  bool convertExpenseCurrency,  bool invoiceExpenseDocuments,  bool notifyVendorWhenPaid,  bool calculateExpenseTaxByAmount,  bool expenseInclusiveTaxes,  bool expenseMailboxActive,  String expenseMailbox,  bool inboundMailboxAllowCompanyUsers,  bool inboundMailboxAllowVendors,  bool inboundMailboxAllowClients,  String inboundMailboxWhitelist,  String inboundMailboxBlacklist,  bool inboundMailboxAllowUnknown,  String googleAnalyticsKey,  String matomoId,  String matomoUrl,  int sessionTimeout,  int defaultPasswordTimeout,  bool oauthPasswordRequired,  bool isDisabled,  bool markdownEnabled,  bool markdownEmailEnabled,  bool reportIncludeDrafts,  bool reportIncludeDeleted,  List<Document> documents,  int updatedAt,  int archivedAt)?  $default,) {final _that = this;
switch (_that) {
case _Company() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.rawSettings,_that.settings,_that.enableApplyingPayments,_that.convertPaymentCurrency,_that.enabledTaxRates,_that.enabledItemTaxRates,_that.enabledExpenseTaxRates,_that.calculateTaxes,_that.taxData,_that.trackInventory,_that.stockNotification,_that.inventoryNotificationThreshold,_that.enableProductDiscount,_that.enableProductCost,_that.enableProductQuantity,_that.defaultQuantity,_that.showProductDetails,_that.fillProducts,_that.updateProducts,_that.convertProducts,_that.convertRateToClient,_that.stopOnUnpaidRecurring,_that.useQuoteTermsOnConversion,_that.autoStartTasks,_that.showTaskEndDate,_that.showTasksTable,_that.invoiceTaskDatelog,_that.invoiceTaskTimelog,_that.invoiceTaskHours,_that.invoiceTaskItemDescription,_that.invoiceTaskProject,_that.invoiceTaskProjectHeader,_that.invoiceTaskLock,_that.invoiceTaskDocuments,_that.markExpensesInvoiceable,_that.markExpensesPaid,_that.convertExpenseCurrency,_that.invoiceExpenseDocuments,_that.notifyVendorWhenPaid,_that.calculateExpenseTaxByAmount,_that.expenseInclusiveTaxes,_that.expenseMailboxActive,_that.expenseMailbox,_that.inboundMailboxAllowCompanyUsers,_that.inboundMailboxAllowVendors,_that.inboundMailboxAllowClients,_that.inboundMailboxWhitelist,_that.inboundMailboxBlacklist,_that.inboundMailboxAllowUnknown,_that.googleAnalyticsKey,_that.matomoId,_that.matomoUrl,_that.sessionTimeout,_that.defaultPasswordTimeout,_that.oauthPasswordRequired,_that.isDisabled,_that.markdownEnabled,_that.markdownEmailEnabled,_that.reportIncludeDrafts,_that.reportIncludeDeleted,_that.documents,_that.updatedAt,_that.archivedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Company extends Company {
  const _Company({this.id = '', this.displayName = '', this.name = '', this.companyKey = '', this.sizeId = '', this.industryId = '', this.firstMonthOfYear = '', this.firstDayOfWeek = '', this.enabledModules = 0, this.legalEntityId = 0, this.subdomain = '', this.portalDomain = '', this.portalMode = '', final  Map<String, String> customFields = const <String, String>{}, final  Map<String, dynamic> rawSettings = const <String, dynamic>{}, this.settings = const CompanySettings(), this.enableApplyingPayments = false, this.convertPaymentCurrency = false, this.enabledTaxRates = 0, this.enabledItemTaxRates = 0, this.enabledExpenseTaxRates = 0, this.calculateTaxes = false, this.taxData, this.trackInventory = false, this.stockNotification = false, this.inventoryNotificationThreshold = 0, this.enableProductDiscount = false, this.enableProductCost = false, this.enableProductQuantity = false, this.defaultQuantity = false, this.showProductDetails = false, this.fillProducts = false, this.updateProducts = false, this.convertProducts = false, this.convertRateToClient = false, this.stopOnUnpaidRecurring = false, this.useQuoteTermsOnConversion = false, this.autoStartTasks = false, this.showTaskEndDate = false, this.showTasksTable = false, this.invoiceTaskDatelog = false, this.invoiceTaskTimelog = false, this.invoiceTaskHours = false, this.invoiceTaskItemDescription = false, this.invoiceTaskProject = false, this.invoiceTaskProjectHeader = false, this.invoiceTaskLock = false, this.invoiceTaskDocuments = false, this.markExpensesInvoiceable = false, this.markExpensesPaid = false, this.convertExpenseCurrency = false, this.invoiceExpenseDocuments = false, this.notifyVendorWhenPaid = false, this.calculateExpenseTaxByAmount = false, this.expenseInclusiveTaxes = false, this.expenseMailboxActive = false, this.expenseMailbox = '', this.inboundMailboxAllowCompanyUsers = false, this.inboundMailboxAllowVendors = false, this.inboundMailboxAllowClients = false, this.inboundMailboxWhitelist = '', this.inboundMailboxBlacklist = '', this.inboundMailboxAllowUnknown = false, this.googleAnalyticsKey = '', this.matomoId = '', this.matomoUrl = '', this.sessionTimeout = 0, this.defaultPasswordTimeout = 0, this.oauthPasswordRequired = false, this.isDisabled = false, this.markdownEnabled = false, this.markdownEmailEnabled = false, this.reportIncludeDrafts = false, this.reportIncludeDeleted = false, final  List<Document> documents = const <Document>[], this.updatedAt = 0, this.archivedAt = 0}): _customFields = customFields,_rawSettings = rawSettings,_documents = documents,super._();
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String name;
@override@JsonKey() final  String companyKey;
@override@JsonKey() final  String sizeId;
@override@JsonKey() final  String industryId;
@override@JsonKey() final  String firstMonthOfYear;
@override@JsonKey() final  String firstDayOfWeek;
@override@JsonKey() final  int enabledModules;
@override@JsonKey() final  int legalEntityId;
@override@JsonKey() final  String subdomain;
@override@JsonKey() final  String portalDomain;
@override@JsonKey() final  String portalMode;
 final  Map<String, String> _customFields;
@override@JsonKey() Map<String, String> get customFields {
  if (_customFields is EqualUnmodifiableMapView) return _customFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customFields);
}

 final  Map<String, dynamic> _rawSettings;
@override@JsonKey() Map<String, dynamic> get rawSettings {
  if (_rawSettings is EqualUnmodifiableMapView) return _rawSettings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_rawSettings);
}

@override@JsonKey() final  CompanySettings settings;
@override@JsonKey() final  bool enableApplyingPayments;
@override@JsonKey() final  bool convertPaymentCurrency;
@override@JsonKey() final  int enabledTaxRates;
@override@JsonKey() final  int enabledItemTaxRates;
@override@JsonKey() final  int enabledExpenseTaxRates;
@override@JsonKey() final  bool calculateTaxes;
@override final  TaxConfigApi? taxData;
// Top-level product configuration. Edited by Settings → Product Settings;
// round-trips through the outbox without touching the `settings` JSON.
@override@JsonKey() final  bool trackInventory;
@override@JsonKey() final  bool stockNotification;
@override@JsonKey() final  int inventoryNotificationThreshold;
@override@JsonKey() final  bool enableProductDiscount;
@override@JsonKey() final  bool enableProductCost;
@override@JsonKey() final  bool enableProductQuantity;
@override@JsonKey() final  bool defaultQuantity;
@override@JsonKey() final  bool showProductDetails;
@override@JsonKey() final  bool fillProducts;
@override@JsonKey() final  bool updateProducts;
@override@JsonKey() final  bool convertProducts;
@override@JsonKey() final  bool convertRateToClient;
// Top-level workflow configuration. Edited by Settings → Workflow Settings
// alongside the cascade `settings.*` workflow toggles.
@override@JsonKey() final  bool stopOnUnpaidRecurring;
@override@JsonKey() final  bool useQuoteTermsOnConversion;
// Top-level task configuration. Edited by Settings → Task Settings.
@override@JsonKey() final  bool autoStartTasks;
@override@JsonKey() final  bool showTaskEndDate;
@override@JsonKey() final  bool showTasksTable;
@override@JsonKey() final  bool invoiceTaskDatelog;
@override@JsonKey() final  bool invoiceTaskTimelog;
@override@JsonKey() final  bool invoiceTaskHours;
@override@JsonKey() final  bool invoiceTaskItemDescription;
@override@JsonKey() final  bool invoiceTaskProject;
@override@JsonKey() final  bool invoiceTaskProjectHeader;
@override@JsonKey() final  bool invoiceTaskLock;
@override@JsonKey() final  bool invoiceTaskDocuments;
// Top-level expense configuration. Edited by Settings → Expense Settings.
// Cascade `defaultExpensePaymentTypeId` lives on `CompanySettings`. The
// `inboundMailbox*` block is self-hosted only.
@override@JsonKey() final  bool markExpensesInvoiceable;
@override@JsonKey() final  bool markExpensesPaid;
@override@JsonKey() final  bool convertExpenseCurrency;
@override@JsonKey() final  bool invoiceExpenseDocuments;
@override@JsonKey() final  bool notifyVendorWhenPaid;
@override@JsonKey() final  bool calculateExpenseTaxByAmount;
@override@JsonKey() final  bool expenseInclusiveTaxes;
@override@JsonKey() final  bool expenseMailboxActive;
@override@JsonKey() final  String expenseMailbox;
@override@JsonKey() final  bool inboundMailboxAllowCompanyUsers;
@override@JsonKey() final  bool inboundMailboxAllowVendors;
@override@JsonKey() final  bool inboundMailboxAllowClients;
@override@JsonKey() final  String inboundMailboxWhitelist;
@override@JsonKey() final  String inboundMailboxBlacklist;
@override@JsonKey() final  bool inboundMailboxAllowUnknown;
// Account Management → Integrations: top-level analytics fields.
@override@JsonKey() final  String googleAnalyticsKey;
@override@JsonKey() final  String matomoId;
@override@JsonKey() final  String matomoUrl;
// Account Management → Security Settings: top-level company fields.
// Timeouts in milliseconds; 0 = never time out.
@override@JsonKey() final  int sessionTimeout;
@override@JsonKey() final  int defaultPasswordTimeout;
@override@JsonKey() final  bool oauthPasswordRequired;
// Account Management → Overview: top-level company toggles.
@override@JsonKey() final  bool isDisabled;
@override@JsonKey() final  bool markdownEnabled;
@override@JsonKey() final  bool markdownEmailEnabled;
@override@JsonKey() final  bool reportIncludeDrafts;
@override@JsonKey() final  bool reportIncludeDeleted;
 final  List<Document> _documents;
@override@JsonKey() List<Document> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

@override@JsonKey() final  int updatedAt;
@override@JsonKey() final  int archivedAt;

/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanyCopyWith<_Company> get copyWith => __$CompanyCopyWithImpl<_Company>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Company&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.firstMonthOfYear, firstMonthOfYear) || other.firstMonthOfYear == firstMonthOfYear)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.portalDomain, portalDomain) || other.portalDomain == portalDomain)&&(identical(other.portalMode, portalMode) || other.portalMode == portalMode)&&const DeepCollectionEquality().equals(other._customFields, _customFields)&&const DeepCollectionEquality().equals(other._rawSettings, _rawSettings)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.enableApplyingPayments, enableApplyingPayments) || other.enableApplyingPayments == enableApplyingPayments)&&(identical(other.convertPaymentCurrency, convertPaymentCurrency) || other.convertPaymentCurrency == convertPaymentCurrency)&&(identical(other.enabledTaxRates, enabledTaxRates) || other.enabledTaxRates == enabledTaxRates)&&(identical(other.enabledItemTaxRates, enabledItemTaxRates) || other.enabledItemTaxRates == enabledItemTaxRates)&&(identical(other.enabledExpenseTaxRates, enabledExpenseTaxRates) || other.enabledExpenseTaxRates == enabledExpenseTaxRates)&&(identical(other.calculateTaxes, calculateTaxes) || other.calculateTaxes == calculateTaxes)&&(identical(other.taxData, taxData) || other.taxData == taxData)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory)&&(identical(other.stockNotification, stockNotification) || other.stockNotification == stockNotification)&&(identical(other.inventoryNotificationThreshold, inventoryNotificationThreshold) || other.inventoryNotificationThreshold == inventoryNotificationThreshold)&&(identical(other.enableProductDiscount, enableProductDiscount) || other.enableProductDiscount == enableProductDiscount)&&(identical(other.enableProductCost, enableProductCost) || other.enableProductCost == enableProductCost)&&(identical(other.enableProductQuantity, enableProductQuantity) || other.enableProductQuantity == enableProductQuantity)&&(identical(other.defaultQuantity, defaultQuantity) || other.defaultQuantity == defaultQuantity)&&(identical(other.showProductDetails, showProductDetails) || other.showProductDetails == showProductDetails)&&(identical(other.fillProducts, fillProducts) || other.fillProducts == fillProducts)&&(identical(other.updateProducts, updateProducts) || other.updateProducts == updateProducts)&&(identical(other.convertProducts, convertProducts) || other.convertProducts == convertProducts)&&(identical(other.convertRateToClient, convertRateToClient) || other.convertRateToClient == convertRateToClient)&&(identical(other.stopOnUnpaidRecurring, stopOnUnpaidRecurring) || other.stopOnUnpaidRecurring == stopOnUnpaidRecurring)&&(identical(other.useQuoteTermsOnConversion, useQuoteTermsOnConversion) || other.useQuoteTermsOnConversion == useQuoteTermsOnConversion)&&(identical(other.autoStartTasks, autoStartTasks) || other.autoStartTasks == autoStartTasks)&&(identical(other.showTaskEndDate, showTaskEndDate) || other.showTaskEndDate == showTaskEndDate)&&(identical(other.showTasksTable, showTasksTable) || other.showTasksTable == showTasksTable)&&(identical(other.invoiceTaskDatelog, invoiceTaskDatelog) || other.invoiceTaskDatelog == invoiceTaskDatelog)&&(identical(other.invoiceTaskTimelog, invoiceTaskTimelog) || other.invoiceTaskTimelog == invoiceTaskTimelog)&&(identical(other.invoiceTaskHours, invoiceTaskHours) || other.invoiceTaskHours == invoiceTaskHours)&&(identical(other.invoiceTaskItemDescription, invoiceTaskItemDescription) || other.invoiceTaskItemDescription == invoiceTaskItemDescription)&&(identical(other.invoiceTaskProject, invoiceTaskProject) || other.invoiceTaskProject == invoiceTaskProject)&&(identical(other.invoiceTaskProjectHeader, invoiceTaskProjectHeader) || other.invoiceTaskProjectHeader == invoiceTaskProjectHeader)&&(identical(other.invoiceTaskLock, invoiceTaskLock) || other.invoiceTaskLock == invoiceTaskLock)&&(identical(other.invoiceTaskDocuments, invoiceTaskDocuments) || other.invoiceTaskDocuments == invoiceTaskDocuments)&&(identical(other.markExpensesInvoiceable, markExpensesInvoiceable) || other.markExpensesInvoiceable == markExpensesInvoiceable)&&(identical(other.markExpensesPaid, markExpensesPaid) || other.markExpensesPaid == markExpensesPaid)&&(identical(other.convertExpenseCurrency, convertExpenseCurrency) || other.convertExpenseCurrency == convertExpenseCurrency)&&(identical(other.invoiceExpenseDocuments, invoiceExpenseDocuments) || other.invoiceExpenseDocuments == invoiceExpenseDocuments)&&(identical(other.notifyVendorWhenPaid, notifyVendorWhenPaid) || other.notifyVendorWhenPaid == notifyVendorWhenPaid)&&(identical(other.calculateExpenseTaxByAmount, calculateExpenseTaxByAmount) || other.calculateExpenseTaxByAmount == calculateExpenseTaxByAmount)&&(identical(other.expenseInclusiveTaxes, expenseInclusiveTaxes) || other.expenseInclusiveTaxes == expenseInclusiveTaxes)&&(identical(other.expenseMailboxActive, expenseMailboxActive) || other.expenseMailboxActive == expenseMailboxActive)&&(identical(other.expenseMailbox, expenseMailbox) || other.expenseMailbox == expenseMailbox)&&(identical(other.inboundMailboxAllowCompanyUsers, inboundMailboxAllowCompanyUsers) || other.inboundMailboxAllowCompanyUsers == inboundMailboxAllowCompanyUsers)&&(identical(other.inboundMailboxAllowVendors, inboundMailboxAllowVendors) || other.inboundMailboxAllowVendors == inboundMailboxAllowVendors)&&(identical(other.inboundMailboxAllowClients, inboundMailboxAllowClients) || other.inboundMailboxAllowClients == inboundMailboxAllowClients)&&(identical(other.inboundMailboxWhitelist, inboundMailboxWhitelist) || other.inboundMailboxWhitelist == inboundMailboxWhitelist)&&(identical(other.inboundMailboxBlacklist, inboundMailboxBlacklist) || other.inboundMailboxBlacklist == inboundMailboxBlacklist)&&(identical(other.inboundMailboxAllowUnknown, inboundMailboxAllowUnknown) || other.inboundMailboxAllowUnknown == inboundMailboxAllowUnknown)&&(identical(other.googleAnalyticsKey, googleAnalyticsKey) || other.googleAnalyticsKey == googleAnalyticsKey)&&(identical(other.matomoId, matomoId) || other.matomoId == matomoId)&&(identical(other.matomoUrl, matomoUrl) || other.matomoUrl == matomoUrl)&&(identical(other.sessionTimeout, sessionTimeout) || other.sessionTimeout == sessionTimeout)&&(identical(other.defaultPasswordTimeout, defaultPasswordTimeout) || other.defaultPasswordTimeout == defaultPasswordTimeout)&&(identical(other.oauthPasswordRequired, oauthPasswordRequired) || other.oauthPasswordRequired == oauthPasswordRequired)&&(identical(other.isDisabled, isDisabled) || other.isDisabled == isDisabled)&&(identical(other.markdownEnabled, markdownEnabled) || other.markdownEnabled == markdownEnabled)&&(identical(other.markdownEmailEnabled, markdownEmailEnabled) || other.markdownEmailEnabled == markdownEmailEnabled)&&(identical(other.reportIncludeDrafts, reportIncludeDrafts) || other.reportIncludeDrafts == reportIncludeDrafts)&&(identical(other.reportIncludeDeleted, reportIncludeDeleted) || other.reportIncludeDeleted == reportIncludeDeleted)&&const DeepCollectionEquality().equals(other._documents, _documents)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,name,companyKey,sizeId,industryId,firstMonthOfYear,firstDayOfWeek,enabledModules,legalEntityId,subdomain,portalDomain,portalMode,const DeepCollectionEquality().hash(_customFields),const DeepCollectionEquality().hash(_rawSettings),settings,enableApplyingPayments,convertPaymentCurrency,enabledTaxRates,enabledItemTaxRates,enabledExpenseTaxRates,calculateTaxes,taxData,trackInventory,stockNotification,inventoryNotificationThreshold,enableProductDiscount,enableProductCost,enableProductQuantity,defaultQuantity,showProductDetails,fillProducts,updateProducts,convertProducts,convertRateToClient,stopOnUnpaidRecurring,useQuoteTermsOnConversion,autoStartTasks,showTaskEndDate,showTasksTable,invoiceTaskDatelog,invoiceTaskTimelog,invoiceTaskHours,invoiceTaskItemDescription,invoiceTaskProject,invoiceTaskProjectHeader,invoiceTaskLock,invoiceTaskDocuments,markExpensesInvoiceable,markExpensesPaid,convertExpenseCurrency,invoiceExpenseDocuments,notifyVendorWhenPaid,calculateExpenseTaxByAmount,expenseInclusiveTaxes,expenseMailboxActive,expenseMailbox,inboundMailboxAllowCompanyUsers,inboundMailboxAllowVendors,inboundMailboxAllowClients,inboundMailboxWhitelist,inboundMailboxBlacklist,inboundMailboxAllowUnknown,googleAnalyticsKey,matomoId,matomoUrl,sessionTimeout,defaultPasswordTimeout,oauthPasswordRequired,isDisabled,markdownEnabled,markdownEmailEnabled,reportIncludeDrafts,reportIncludeDeleted,const DeepCollectionEquality().hash(_documents),updatedAt,archivedAt]);

@override
String toString() {
  return 'Company(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, rawSettings: $rawSettings, settings: $settings, enableApplyingPayments: $enableApplyingPayments, convertPaymentCurrency: $convertPaymentCurrency, enabledTaxRates: $enabledTaxRates, enabledItemTaxRates: $enabledItemTaxRates, enabledExpenseTaxRates: $enabledExpenseTaxRates, calculateTaxes: $calculateTaxes, taxData: $taxData, trackInventory: $trackInventory, stockNotification: $stockNotification, inventoryNotificationThreshold: $inventoryNotificationThreshold, enableProductDiscount: $enableProductDiscount, enableProductCost: $enableProductCost, enableProductQuantity: $enableProductQuantity, defaultQuantity: $defaultQuantity, showProductDetails: $showProductDetails, fillProducts: $fillProducts, updateProducts: $updateProducts, convertProducts: $convertProducts, convertRateToClient: $convertRateToClient, stopOnUnpaidRecurring: $stopOnUnpaidRecurring, useQuoteTermsOnConversion: $useQuoteTermsOnConversion, autoStartTasks: $autoStartTasks, showTaskEndDate: $showTaskEndDate, showTasksTable: $showTasksTable, invoiceTaskDatelog: $invoiceTaskDatelog, invoiceTaskTimelog: $invoiceTaskTimelog, invoiceTaskHours: $invoiceTaskHours, invoiceTaskItemDescription: $invoiceTaskItemDescription, invoiceTaskProject: $invoiceTaskProject, invoiceTaskProjectHeader: $invoiceTaskProjectHeader, invoiceTaskLock: $invoiceTaskLock, invoiceTaskDocuments: $invoiceTaskDocuments, markExpensesInvoiceable: $markExpensesInvoiceable, markExpensesPaid: $markExpensesPaid, convertExpenseCurrency: $convertExpenseCurrency, invoiceExpenseDocuments: $invoiceExpenseDocuments, notifyVendorWhenPaid: $notifyVendorWhenPaid, calculateExpenseTaxByAmount: $calculateExpenseTaxByAmount, expenseInclusiveTaxes: $expenseInclusiveTaxes, expenseMailboxActive: $expenseMailboxActive, expenseMailbox: $expenseMailbox, inboundMailboxAllowCompanyUsers: $inboundMailboxAllowCompanyUsers, inboundMailboxAllowVendors: $inboundMailboxAllowVendors, inboundMailboxAllowClients: $inboundMailboxAllowClients, inboundMailboxWhitelist: $inboundMailboxWhitelist, inboundMailboxBlacklist: $inboundMailboxBlacklist, inboundMailboxAllowUnknown: $inboundMailboxAllowUnknown, googleAnalyticsKey: $googleAnalyticsKey, matomoId: $matomoId, matomoUrl: $matomoUrl, sessionTimeout: $sessionTimeout, defaultPasswordTimeout: $defaultPasswordTimeout, oauthPasswordRequired: $oauthPasswordRequired, isDisabled: $isDisabled, markdownEnabled: $markdownEnabled, markdownEmailEnabled: $markdownEmailEnabled, reportIncludeDrafts: $reportIncludeDrafts, reportIncludeDeleted: $reportIncludeDeleted, documents: $documents, updatedAt: $updatedAt, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class _$CompanyCopyWith<$Res> implements $CompanyCopyWith<$Res> {
  factory _$CompanyCopyWith(_Company value, $Res Function(_Company) _then) = __$CompanyCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String name, String companyKey, String sizeId, String industryId, String firstMonthOfYear, String firstDayOfWeek, int enabledModules, int legalEntityId, String subdomain, String portalDomain, String portalMode, Map<String, String> customFields, Map<String, dynamic> rawSettings, CompanySettings settings, bool enableApplyingPayments, bool convertPaymentCurrency, int enabledTaxRates, int enabledItemTaxRates, int enabledExpenseTaxRates, bool calculateTaxes, TaxConfigApi? taxData, bool trackInventory, bool stockNotification, int inventoryNotificationThreshold, bool enableProductDiscount, bool enableProductCost, bool enableProductQuantity, bool defaultQuantity, bool showProductDetails, bool fillProducts, bool updateProducts, bool convertProducts, bool convertRateToClient, bool stopOnUnpaidRecurring, bool useQuoteTermsOnConversion, bool autoStartTasks, bool showTaskEndDate, bool showTasksTable, bool invoiceTaskDatelog, bool invoiceTaskTimelog, bool invoiceTaskHours, bool invoiceTaskItemDescription, bool invoiceTaskProject, bool invoiceTaskProjectHeader, bool invoiceTaskLock, bool invoiceTaskDocuments, bool markExpensesInvoiceable, bool markExpensesPaid, bool convertExpenseCurrency, bool invoiceExpenseDocuments, bool notifyVendorWhenPaid, bool calculateExpenseTaxByAmount, bool expenseInclusiveTaxes, bool expenseMailboxActive, String expenseMailbox, bool inboundMailboxAllowCompanyUsers, bool inboundMailboxAllowVendors, bool inboundMailboxAllowClients, String inboundMailboxWhitelist, String inboundMailboxBlacklist, bool inboundMailboxAllowUnknown, String googleAnalyticsKey, String matomoId, String matomoUrl, int sessionTimeout, int defaultPasswordTimeout, bool oauthPasswordRequired, bool isDisabled, bool markdownEnabled, bool markdownEmailEnabled, bool reportIncludeDrafts, bool reportIncludeDeleted, List<Document> documents, int updatedAt, int archivedAt
});


@override $CompanySettingsApiCopyWith<$Res> get settings;@override $TaxConfigApiCopyWith<$Res>? get taxData;

}
/// @nodoc
class __$CompanyCopyWithImpl<$Res>
    implements _$CompanyCopyWith<$Res> {
  __$CompanyCopyWithImpl(this._self, this._then);

  final _Company _self;
  final $Res Function(_Company) _then;

/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? sizeId = null,Object? industryId = null,Object? firstMonthOfYear = null,Object? firstDayOfWeek = null,Object? enabledModules = null,Object? legalEntityId = null,Object? subdomain = null,Object? portalDomain = null,Object? portalMode = null,Object? customFields = null,Object? rawSettings = null,Object? settings = null,Object? enableApplyingPayments = null,Object? convertPaymentCurrency = null,Object? enabledTaxRates = null,Object? enabledItemTaxRates = null,Object? enabledExpenseTaxRates = null,Object? calculateTaxes = null,Object? taxData = freezed,Object? trackInventory = null,Object? stockNotification = null,Object? inventoryNotificationThreshold = null,Object? enableProductDiscount = null,Object? enableProductCost = null,Object? enableProductQuantity = null,Object? defaultQuantity = null,Object? showProductDetails = null,Object? fillProducts = null,Object? updateProducts = null,Object? convertProducts = null,Object? convertRateToClient = null,Object? stopOnUnpaidRecurring = null,Object? useQuoteTermsOnConversion = null,Object? autoStartTasks = null,Object? showTaskEndDate = null,Object? showTasksTable = null,Object? invoiceTaskDatelog = null,Object? invoiceTaskTimelog = null,Object? invoiceTaskHours = null,Object? invoiceTaskItemDescription = null,Object? invoiceTaskProject = null,Object? invoiceTaskProjectHeader = null,Object? invoiceTaskLock = null,Object? invoiceTaskDocuments = null,Object? markExpensesInvoiceable = null,Object? markExpensesPaid = null,Object? convertExpenseCurrency = null,Object? invoiceExpenseDocuments = null,Object? notifyVendorWhenPaid = null,Object? calculateExpenseTaxByAmount = null,Object? expenseInclusiveTaxes = null,Object? expenseMailboxActive = null,Object? expenseMailbox = null,Object? inboundMailboxAllowCompanyUsers = null,Object? inboundMailboxAllowVendors = null,Object? inboundMailboxAllowClients = null,Object? inboundMailboxWhitelist = null,Object? inboundMailboxBlacklist = null,Object? inboundMailboxAllowUnknown = null,Object? googleAnalyticsKey = null,Object? matomoId = null,Object? matomoUrl = null,Object? sessionTimeout = null,Object? defaultPasswordTimeout = null,Object? oauthPasswordRequired = null,Object? isDisabled = null,Object? markdownEnabled = null,Object? markdownEmailEnabled = null,Object? reportIncludeDrafts = null,Object? reportIncludeDeleted = null,Object? documents = null,Object? updatedAt = null,Object? archivedAt = null,}) {
  return _then(_Company(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,companyKey: null == companyKey ? _self.companyKey : companyKey // ignore: cast_nullable_to_non_nullable
as String,sizeId: null == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String,industryId: null == industryId ? _self.industryId : industryId // ignore: cast_nullable_to_non_nullable
as String,firstMonthOfYear: null == firstMonthOfYear ? _self.firstMonthOfYear : firstMonthOfYear // ignore: cast_nullable_to_non_nullable
as String,firstDayOfWeek: null == firstDayOfWeek ? _self.firstDayOfWeek : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
as String,enabledModules: null == enabledModules ? _self.enabledModules : enabledModules // ignore: cast_nullable_to_non_nullable
as int,legalEntityId: null == legalEntityId ? _self.legalEntityId : legalEntityId // ignore: cast_nullable_to_non_nullable
as int,subdomain: null == subdomain ? _self.subdomain : subdomain // ignore: cast_nullable_to_non_nullable
as String,portalDomain: null == portalDomain ? _self.portalDomain : portalDomain // ignore: cast_nullable_to_non_nullable
as String,portalMode: null == portalMode ? _self.portalMode : portalMode // ignore: cast_nullable_to_non_nullable
as String,customFields: null == customFields ? _self._customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,rawSettings: null == rawSettings ? _self._rawSettings : rawSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CompanySettings,enableApplyingPayments: null == enableApplyingPayments ? _self.enableApplyingPayments : enableApplyingPayments // ignore: cast_nullable_to_non_nullable
as bool,convertPaymentCurrency: null == convertPaymentCurrency ? _self.convertPaymentCurrency : convertPaymentCurrency // ignore: cast_nullable_to_non_nullable
as bool,enabledTaxRates: null == enabledTaxRates ? _self.enabledTaxRates : enabledTaxRates // ignore: cast_nullable_to_non_nullable
as int,enabledItemTaxRates: null == enabledItemTaxRates ? _self.enabledItemTaxRates : enabledItemTaxRates // ignore: cast_nullable_to_non_nullable
as int,enabledExpenseTaxRates: null == enabledExpenseTaxRates ? _self.enabledExpenseTaxRates : enabledExpenseTaxRates // ignore: cast_nullable_to_non_nullable
as int,calculateTaxes: null == calculateTaxes ? _self.calculateTaxes : calculateTaxes // ignore: cast_nullable_to_non_nullable
as bool,taxData: freezed == taxData ? _self.taxData : taxData // ignore: cast_nullable_to_non_nullable
as TaxConfigApi?,trackInventory: null == trackInventory ? _self.trackInventory : trackInventory // ignore: cast_nullable_to_non_nullable
as bool,stockNotification: null == stockNotification ? _self.stockNotification : stockNotification // ignore: cast_nullable_to_non_nullable
as bool,inventoryNotificationThreshold: null == inventoryNotificationThreshold ? _self.inventoryNotificationThreshold : inventoryNotificationThreshold // ignore: cast_nullable_to_non_nullable
as int,enableProductDiscount: null == enableProductDiscount ? _self.enableProductDiscount : enableProductDiscount // ignore: cast_nullable_to_non_nullable
as bool,enableProductCost: null == enableProductCost ? _self.enableProductCost : enableProductCost // ignore: cast_nullable_to_non_nullable
as bool,enableProductQuantity: null == enableProductQuantity ? _self.enableProductQuantity : enableProductQuantity // ignore: cast_nullable_to_non_nullable
as bool,defaultQuantity: null == defaultQuantity ? _self.defaultQuantity : defaultQuantity // ignore: cast_nullable_to_non_nullable
as bool,showProductDetails: null == showProductDetails ? _self.showProductDetails : showProductDetails // ignore: cast_nullable_to_non_nullable
as bool,fillProducts: null == fillProducts ? _self.fillProducts : fillProducts // ignore: cast_nullable_to_non_nullable
as bool,updateProducts: null == updateProducts ? _self.updateProducts : updateProducts // ignore: cast_nullable_to_non_nullable
as bool,convertProducts: null == convertProducts ? _self.convertProducts : convertProducts // ignore: cast_nullable_to_non_nullable
as bool,convertRateToClient: null == convertRateToClient ? _self.convertRateToClient : convertRateToClient // ignore: cast_nullable_to_non_nullable
as bool,stopOnUnpaidRecurring: null == stopOnUnpaidRecurring ? _self.stopOnUnpaidRecurring : stopOnUnpaidRecurring // ignore: cast_nullable_to_non_nullable
as bool,useQuoteTermsOnConversion: null == useQuoteTermsOnConversion ? _self.useQuoteTermsOnConversion : useQuoteTermsOnConversion // ignore: cast_nullable_to_non_nullable
as bool,autoStartTasks: null == autoStartTasks ? _self.autoStartTasks : autoStartTasks // ignore: cast_nullable_to_non_nullable
as bool,showTaskEndDate: null == showTaskEndDate ? _self.showTaskEndDate : showTaskEndDate // ignore: cast_nullable_to_non_nullable
as bool,showTasksTable: null == showTasksTable ? _self.showTasksTable : showTasksTable // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskDatelog: null == invoiceTaskDatelog ? _self.invoiceTaskDatelog : invoiceTaskDatelog // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskTimelog: null == invoiceTaskTimelog ? _self.invoiceTaskTimelog : invoiceTaskTimelog // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskHours: null == invoiceTaskHours ? _self.invoiceTaskHours : invoiceTaskHours // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskItemDescription: null == invoiceTaskItemDescription ? _self.invoiceTaskItemDescription : invoiceTaskItemDescription // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskProject: null == invoiceTaskProject ? _self.invoiceTaskProject : invoiceTaskProject // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskProjectHeader: null == invoiceTaskProjectHeader ? _self.invoiceTaskProjectHeader : invoiceTaskProjectHeader // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskLock: null == invoiceTaskLock ? _self.invoiceTaskLock : invoiceTaskLock // ignore: cast_nullable_to_non_nullable
as bool,invoiceTaskDocuments: null == invoiceTaskDocuments ? _self.invoiceTaskDocuments : invoiceTaskDocuments // ignore: cast_nullable_to_non_nullable
as bool,markExpensesInvoiceable: null == markExpensesInvoiceable ? _self.markExpensesInvoiceable : markExpensesInvoiceable // ignore: cast_nullable_to_non_nullable
as bool,markExpensesPaid: null == markExpensesPaid ? _self.markExpensesPaid : markExpensesPaid // ignore: cast_nullable_to_non_nullable
as bool,convertExpenseCurrency: null == convertExpenseCurrency ? _self.convertExpenseCurrency : convertExpenseCurrency // ignore: cast_nullable_to_non_nullable
as bool,invoiceExpenseDocuments: null == invoiceExpenseDocuments ? _self.invoiceExpenseDocuments : invoiceExpenseDocuments // ignore: cast_nullable_to_non_nullable
as bool,notifyVendorWhenPaid: null == notifyVendorWhenPaid ? _self.notifyVendorWhenPaid : notifyVendorWhenPaid // ignore: cast_nullable_to_non_nullable
as bool,calculateExpenseTaxByAmount: null == calculateExpenseTaxByAmount ? _self.calculateExpenseTaxByAmount : calculateExpenseTaxByAmount // ignore: cast_nullable_to_non_nullable
as bool,expenseInclusiveTaxes: null == expenseInclusiveTaxes ? _self.expenseInclusiveTaxes : expenseInclusiveTaxes // ignore: cast_nullable_to_non_nullable
as bool,expenseMailboxActive: null == expenseMailboxActive ? _self.expenseMailboxActive : expenseMailboxActive // ignore: cast_nullable_to_non_nullable
as bool,expenseMailbox: null == expenseMailbox ? _self.expenseMailbox : expenseMailbox // ignore: cast_nullable_to_non_nullable
as String,inboundMailboxAllowCompanyUsers: null == inboundMailboxAllowCompanyUsers ? _self.inboundMailboxAllowCompanyUsers : inboundMailboxAllowCompanyUsers // ignore: cast_nullable_to_non_nullable
as bool,inboundMailboxAllowVendors: null == inboundMailboxAllowVendors ? _self.inboundMailboxAllowVendors : inboundMailboxAllowVendors // ignore: cast_nullable_to_non_nullable
as bool,inboundMailboxAllowClients: null == inboundMailboxAllowClients ? _self.inboundMailboxAllowClients : inboundMailboxAllowClients // ignore: cast_nullable_to_non_nullable
as bool,inboundMailboxWhitelist: null == inboundMailboxWhitelist ? _self.inboundMailboxWhitelist : inboundMailboxWhitelist // ignore: cast_nullable_to_non_nullable
as String,inboundMailboxBlacklist: null == inboundMailboxBlacklist ? _self.inboundMailboxBlacklist : inboundMailboxBlacklist // ignore: cast_nullable_to_non_nullable
as String,inboundMailboxAllowUnknown: null == inboundMailboxAllowUnknown ? _self.inboundMailboxAllowUnknown : inboundMailboxAllowUnknown // ignore: cast_nullable_to_non_nullable
as bool,googleAnalyticsKey: null == googleAnalyticsKey ? _self.googleAnalyticsKey : googleAnalyticsKey // ignore: cast_nullable_to_non_nullable
as String,matomoId: null == matomoId ? _self.matomoId : matomoId // ignore: cast_nullable_to_non_nullable
as String,matomoUrl: null == matomoUrl ? _self.matomoUrl : matomoUrl // ignore: cast_nullable_to_non_nullable
as String,sessionTimeout: null == sessionTimeout ? _self.sessionTimeout : sessionTimeout // ignore: cast_nullable_to_non_nullable
as int,defaultPasswordTimeout: null == defaultPasswordTimeout ? _self.defaultPasswordTimeout : defaultPasswordTimeout // ignore: cast_nullable_to_non_nullable
as int,oauthPasswordRequired: null == oauthPasswordRequired ? _self.oauthPasswordRequired : oauthPasswordRequired // ignore: cast_nullable_to_non_nullable
as bool,isDisabled: null == isDisabled ? _self.isDisabled : isDisabled // ignore: cast_nullable_to_non_nullable
as bool,markdownEnabled: null == markdownEnabled ? _self.markdownEnabled : markdownEnabled // ignore: cast_nullable_to_non_nullable
as bool,markdownEmailEnabled: null == markdownEmailEnabled ? _self.markdownEmailEnabled : markdownEmailEnabled // ignore: cast_nullable_to_non_nullable
as bool,reportIncludeDrafts: null == reportIncludeDrafts ? _self.reportIncludeDrafts : reportIncludeDrafts // ignore: cast_nullable_to_non_nullable
as bool,reportIncludeDeleted: null == reportIncludeDeleted ? _self.reportIncludeDeleted : reportIncludeDeleted // ignore: cast_nullable_to_non_nullable
as bool,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompanySettingsApiCopyWith<$Res> get settings {
  
  return $CompanySettingsApiCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of Company
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaxConfigApiCopyWith<$Res>? get taxData {
    if (_self.taxData == null) {
    return null;
  }

  return $TaxConfigApiCopyWith<$Res>(_self.taxData!, (value) {
    return _then(_self.copyWith(taxData: value));
  });
}
}

// dart format on
