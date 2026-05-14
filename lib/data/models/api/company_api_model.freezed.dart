// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompanyApi {

 String get id;@JsonKey(name: 'display_name') String get displayName; String get name;@JsonKey(name: 'company_key') String get companyKey;@JsonKey(name: 'size_id') String get sizeId;@JsonKey(name: 'industry_id') String get industryId;@JsonKey(name: 'first_month_of_year') String get firstMonthOfYear;@JsonKey(name: 'first_day_of_week') String get firstDayOfWeek;@JsonKey(name: 'enabled_modules') int get enabledModules;@JsonKey(name: 'legal_entity_id') int get legalEntityId;@JsonKey(name: 'subdomain') String get subdomain;@JsonKey(name: 'portal_domain') String get portalDomain;@JsonKey(name: 'portal_mode') String get portalMode;@JsonKey(name: 'custom_fields') Map<String, String> get customFields; Map<String, dynamic> get settings;@JsonKey(name: 'enable_applying_payments') bool get enableApplyingPayments;@JsonKey(name: 'convert_payment_currency') bool get convertPaymentCurrency;// ── Tax configuration ────────────────────────────────────────────────
// The three count fields, `calculate_taxes` and `tax_data` live at
// company top-level, not in settings — matching the server contract
// and the legacy admin-portal / React clients.
@JsonKey(name: 'enabled_tax_rates') int get enabledTaxRates;@JsonKey(name: 'enabled_item_tax_rates') int get enabledItemTaxRates;@JsonKey(name: 'enabled_expense_tax_rates') int get enabledExpenseTaxRates;@JsonKey(name: 'calculate_taxes') bool get calculateTaxes;@JsonKey(name: 'tax_data') TaxConfigApi? get taxData;// ── Product configuration ───────────────────────────────────────────
// Top-level company fields edited by Settings → Product Settings.
// Defaults stay false/0 so a fresh CompanyApi constructor doesn't
// invent values; `Company.fromApi` always overlays whatever the wire
// sent.
@JsonKey(name: 'track_inventory') bool get trackInventory;@JsonKey(name: 'stock_notification') bool get stockNotification;@JsonKey(name: 'inventory_notification_threshold') int get inventoryNotificationThreshold;@JsonKey(name: 'enable_product_discount') bool get enableProductDiscount;@JsonKey(name: 'enable_product_cost') bool get enableProductCost;@JsonKey(name: 'enable_product_quantity') bool get enableProductQuantity;@JsonKey(name: 'default_quantity') bool get defaultQuantity;@JsonKey(name: 'show_product_details') bool get showProductDetails;@JsonKey(name: 'fill_products') bool get fillProducts;@JsonKey(name: 'update_products') bool get updateProducts;@JsonKey(name: 'convert_products') bool get convertProducts;@JsonKey(name: 'convert_rate_to_client') bool get convertRateToClient;// ── Workflow ────────────────────────────────────────────────────────
// Top-level company fields edited by Settings → Workflow Settings.
// Only the company-scope rows on that page; the per-entity workflow
// toggles live under `settings.*` (auto_email_invoice, lock_invoices,
// etc.) on `CompanySettingsApi`.
@JsonKey(name: 'stop_on_unpaid_recurring') bool get stopOnUnpaidRecurring;@JsonKey(name: 'use_quote_terms_on_conversion') bool get useQuoteTermsOnConversion;// ── Task configuration ──────────────────────────────────────────────
// Top-level company fields edited by Settings → Task Settings. Per-entity
// task toggles (`default_task_rate`, `task_round_up`, …) live on
// `CompanySettingsApi`. `invoiceTaskProjectHeader`: false = service,
// true = description (parity with legacy admin-portal).
@JsonKey(name: 'auto_start_tasks') bool get autoStartTasks;@JsonKey(name: 'show_task_end_date') bool get showTaskEndDate;@JsonKey(name: 'show_tasks_table') bool get showTasksTable;@JsonKey(name: 'invoice_task_datelog') bool get invoiceTaskDatelog;@JsonKey(name: 'invoice_task_timelog') bool get invoiceTaskTimelog;@JsonKey(name: 'invoice_task_hours') bool get invoiceTaskHours;@JsonKey(name: 'invoice_task_item_description') bool get invoiceTaskItemDescription;@JsonKey(name: 'invoice_task_project') bool get invoiceTaskProject;@JsonKey(name: 'invoice_task_project_header') bool get invoiceTaskProjectHeader;@JsonKey(name: 'invoice_task_lock') bool get invoiceTaskLock;@JsonKey(name: 'invoice_task_documents') bool get invoiceTaskDocuments; List<DocumentApi> get documents;@JsonKey(name: 'updated_at') int get updatedAt;@JsonKey(name: 'archived_at') int get archivedAt;
/// Create a copy of CompanyApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanyApiCopyWith<CompanyApi> get copyWith => _$CompanyApiCopyWithImpl<CompanyApi>(this as CompanyApi, _$identity);

  /// Serializes this CompanyApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanyApi&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.firstMonthOfYear, firstMonthOfYear) || other.firstMonthOfYear == firstMonthOfYear)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.portalDomain, portalDomain) || other.portalDomain == portalDomain)&&(identical(other.portalMode, portalMode) || other.portalMode == portalMode)&&const DeepCollectionEquality().equals(other.customFields, customFields)&&const DeepCollectionEquality().equals(other.settings, settings)&&(identical(other.enableApplyingPayments, enableApplyingPayments) || other.enableApplyingPayments == enableApplyingPayments)&&(identical(other.convertPaymentCurrency, convertPaymentCurrency) || other.convertPaymentCurrency == convertPaymentCurrency)&&(identical(other.enabledTaxRates, enabledTaxRates) || other.enabledTaxRates == enabledTaxRates)&&(identical(other.enabledItemTaxRates, enabledItemTaxRates) || other.enabledItemTaxRates == enabledItemTaxRates)&&(identical(other.enabledExpenseTaxRates, enabledExpenseTaxRates) || other.enabledExpenseTaxRates == enabledExpenseTaxRates)&&(identical(other.calculateTaxes, calculateTaxes) || other.calculateTaxes == calculateTaxes)&&(identical(other.taxData, taxData) || other.taxData == taxData)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory)&&(identical(other.stockNotification, stockNotification) || other.stockNotification == stockNotification)&&(identical(other.inventoryNotificationThreshold, inventoryNotificationThreshold) || other.inventoryNotificationThreshold == inventoryNotificationThreshold)&&(identical(other.enableProductDiscount, enableProductDiscount) || other.enableProductDiscount == enableProductDiscount)&&(identical(other.enableProductCost, enableProductCost) || other.enableProductCost == enableProductCost)&&(identical(other.enableProductQuantity, enableProductQuantity) || other.enableProductQuantity == enableProductQuantity)&&(identical(other.defaultQuantity, defaultQuantity) || other.defaultQuantity == defaultQuantity)&&(identical(other.showProductDetails, showProductDetails) || other.showProductDetails == showProductDetails)&&(identical(other.fillProducts, fillProducts) || other.fillProducts == fillProducts)&&(identical(other.updateProducts, updateProducts) || other.updateProducts == updateProducts)&&(identical(other.convertProducts, convertProducts) || other.convertProducts == convertProducts)&&(identical(other.convertRateToClient, convertRateToClient) || other.convertRateToClient == convertRateToClient)&&(identical(other.stopOnUnpaidRecurring, stopOnUnpaidRecurring) || other.stopOnUnpaidRecurring == stopOnUnpaidRecurring)&&(identical(other.useQuoteTermsOnConversion, useQuoteTermsOnConversion) || other.useQuoteTermsOnConversion == useQuoteTermsOnConversion)&&(identical(other.autoStartTasks, autoStartTasks) || other.autoStartTasks == autoStartTasks)&&(identical(other.showTaskEndDate, showTaskEndDate) || other.showTaskEndDate == showTaskEndDate)&&(identical(other.showTasksTable, showTasksTable) || other.showTasksTable == showTasksTable)&&(identical(other.invoiceTaskDatelog, invoiceTaskDatelog) || other.invoiceTaskDatelog == invoiceTaskDatelog)&&(identical(other.invoiceTaskTimelog, invoiceTaskTimelog) || other.invoiceTaskTimelog == invoiceTaskTimelog)&&(identical(other.invoiceTaskHours, invoiceTaskHours) || other.invoiceTaskHours == invoiceTaskHours)&&(identical(other.invoiceTaskItemDescription, invoiceTaskItemDescription) || other.invoiceTaskItemDescription == invoiceTaskItemDescription)&&(identical(other.invoiceTaskProject, invoiceTaskProject) || other.invoiceTaskProject == invoiceTaskProject)&&(identical(other.invoiceTaskProjectHeader, invoiceTaskProjectHeader) || other.invoiceTaskProjectHeader == invoiceTaskProjectHeader)&&(identical(other.invoiceTaskLock, invoiceTaskLock) || other.invoiceTaskLock == invoiceTaskLock)&&(identical(other.invoiceTaskDocuments, invoiceTaskDocuments) || other.invoiceTaskDocuments == invoiceTaskDocuments)&&const DeepCollectionEquality().equals(other.documents, documents)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,name,companyKey,sizeId,industryId,firstMonthOfYear,firstDayOfWeek,enabledModules,legalEntityId,subdomain,portalDomain,portalMode,const DeepCollectionEquality().hash(customFields),const DeepCollectionEquality().hash(settings),enableApplyingPayments,convertPaymentCurrency,enabledTaxRates,enabledItemTaxRates,enabledExpenseTaxRates,calculateTaxes,taxData,trackInventory,stockNotification,inventoryNotificationThreshold,enableProductDiscount,enableProductCost,enableProductQuantity,defaultQuantity,showProductDetails,fillProducts,updateProducts,convertProducts,convertRateToClient,stopOnUnpaidRecurring,useQuoteTermsOnConversion,autoStartTasks,showTaskEndDate,showTasksTable,invoiceTaskDatelog,invoiceTaskTimelog,invoiceTaskHours,invoiceTaskItemDescription,invoiceTaskProject,invoiceTaskProjectHeader,invoiceTaskLock,invoiceTaskDocuments,const DeepCollectionEquality().hash(documents),updatedAt,archivedAt]);

@override
String toString() {
  return 'CompanyApi(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, settings: $settings, enableApplyingPayments: $enableApplyingPayments, convertPaymentCurrency: $convertPaymentCurrency, enabledTaxRates: $enabledTaxRates, enabledItemTaxRates: $enabledItemTaxRates, enabledExpenseTaxRates: $enabledExpenseTaxRates, calculateTaxes: $calculateTaxes, taxData: $taxData, trackInventory: $trackInventory, stockNotification: $stockNotification, inventoryNotificationThreshold: $inventoryNotificationThreshold, enableProductDiscount: $enableProductDiscount, enableProductCost: $enableProductCost, enableProductQuantity: $enableProductQuantity, defaultQuantity: $defaultQuantity, showProductDetails: $showProductDetails, fillProducts: $fillProducts, updateProducts: $updateProducts, convertProducts: $convertProducts, convertRateToClient: $convertRateToClient, stopOnUnpaidRecurring: $stopOnUnpaidRecurring, useQuoteTermsOnConversion: $useQuoteTermsOnConversion, autoStartTasks: $autoStartTasks, showTaskEndDate: $showTaskEndDate, showTasksTable: $showTasksTable, invoiceTaskDatelog: $invoiceTaskDatelog, invoiceTaskTimelog: $invoiceTaskTimelog, invoiceTaskHours: $invoiceTaskHours, invoiceTaskItemDescription: $invoiceTaskItemDescription, invoiceTaskProject: $invoiceTaskProject, invoiceTaskProjectHeader: $invoiceTaskProjectHeader, invoiceTaskLock: $invoiceTaskLock, invoiceTaskDocuments: $invoiceTaskDocuments, documents: $documents, updatedAt: $updatedAt, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class $CompanyApiCopyWith<$Res>  {
  factory $CompanyApiCopyWith(CompanyApi value, $Res Function(CompanyApi) _then) = _$CompanyApiCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'display_name') String displayName, String name,@JsonKey(name: 'company_key') String companyKey,@JsonKey(name: 'size_id') String sizeId,@JsonKey(name: 'industry_id') String industryId,@JsonKey(name: 'first_month_of_year') String firstMonthOfYear,@JsonKey(name: 'first_day_of_week') String firstDayOfWeek,@JsonKey(name: 'enabled_modules') int enabledModules,@JsonKey(name: 'legal_entity_id') int legalEntityId,@JsonKey(name: 'subdomain') String subdomain,@JsonKey(name: 'portal_domain') String portalDomain,@JsonKey(name: 'portal_mode') String portalMode,@JsonKey(name: 'custom_fields') Map<String, String> customFields, Map<String, dynamic> settings,@JsonKey(name: 'enable_applying_payments') bool enableApplyingPayments,@JsonKey(name: 'convert_payment_currency') bool convertPaymentCurrency,@JsonKey(name: 'enabled_tax_rates') int enabledTaxRates,@JsonKey(name: 'enabled_item_tax_rates') int enabledItemTaxRates,@JsonKey(name: 'enabled_expense_tax_rates') int enabledExpenseTaxRates,@JsonKey(name: 'calculate_taxes') bool calculateTaxes,@JsonKey(name: 'tax_data') TaxConfigApi? taxData,@JsonKey(name: 'track_inventory') bool trackInventory,@JsonKey(name: 'stock_notification') bool stockNotification,@JsonKey(name: 'inventory_notification_threshold') int inventoryNotificationThreshold,@JsonKey(name: 'enable_product_discount') bool enableProductDiscount,@JsonKey(name: 'enable_product_cost') bool enableProductCost,@JsonKey(name: 'enable_product_quantity') bool enableProductQuantity,@JsonKey(name: 'default_quantity') bool defaultQuantity,@JsonKey(name: 'show_product_details') bool showProductDetails,@JsonKey(name: 'fill_products') bool fillProducts,@JsonKey(name: 'update_products') bool updateProducts,@JsonKey(name: 'convert_products') bool convertProducts,@JsonKey(name: 'convert_rate_to_client') bool convertRateToClient,@JsonKey(name: 'stop_on_unpaid_recurring') bool stopOnUnpaidRecurring,@JsonKey(name: 'use_quote_terms_on_conversion') bool useQuoteTermsOnConversion,@JsonKey(name: 'auto_start_tasks') bool autoStartTasks,@JsonKey(name: 'show_task_end_date') bool showTaskEndDate,@JsonKey(name: 'show_tasks_table') bool showTasksTable,@JsonKey(name: 'invoice_task_datelog') bool invoiceTaskDatelog,@JsonKey(name: 'invoice_task_timelog') bool invoiceTaskTimelog,@JsonKey(name: 'invoice_task_hours') bool invoiceTaskHours,@JsonKey(name: 'invoice_task_item_description') bool invoiceTaskItemDescription,@JsonKey(name: 'invoice_task_project') bool invoiceTaskProject,@JsonKey(name: 'invoice_task_project_header') bool invoiceTaskProjectHeader,@JsonKey(name: 'invoice_task_lock') bool invoiceTaskLock,@JsonKey(name: 'invoice_task_documents') bool invoiceTaskDocuments, List<DocumentApi> documents,@JsonKey(name: 'updated_at') int updatedAt,@JsonKey(name: 'archived_at') int archivedAt
});


$TaxConfigApiCopyWith<$Res>? get taxData;

}
/// @nodoc
class _$CompanyApiCopyWithImpl<$Res>
    implements $CompanyApiCopyWith<$Res> {
  _$CompanyApiCopyWithImpl(this._self, this._then);

  final CompanyApi _self;
  final $Res Function(CompanyApi) _then;

/// Create a copy of CompanyApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? sizeId = null,Object? industryId = null,Object? firstMonthOfYear = null,Object? firstDayOfWeek = null,Object? enabledModules = null,Object? legalEntityId = null,Object? subdomain = null,Object? portalDomain = null,Object? portalMode = null,Object? customFields = null,Object? settings = null,Object? enableApplyingPayments = null,Object? convertPaymentCurrency = null,Object? enabledTaxRates = null,Object? enabledItemTaxRates = null,Object? enabledExpenseTaxRates = null,Object? calculateTaxes = null,Object? taxData = freezed,Object? trackInventory = null,Object? stockNotification = null,Object? inventoryNotificationThreshold = null,Object? enableProductDiscount = null,Object? enableProductCost = null,Object? enableProductQuantity = null,Object? defaultQuantity = null,Object? showProductDetails = null,Object? fillProducts = null,Object? updateProducts = null,Object? convertProducts = null,Object? convertRateToClient = null,Object? stopOnUnpaidRecurring = null,Object? useQuoteTermsOnConversion = null,Object? autoStartTasks = null,Object? showTaskEndDate = null,Object? showTasksTable = null,Object? invoiceTaskDatelog = null,Object? invoiceTaskTimelog = null,Object? invoiceTaskHours = null,Object? invoiceTaskItemDescription = null,Object? invoiceTaskProject = null,Object? invoiceTaskProjectHeader = null,Object? invoiceTaskLock = null,Object? invoiceTaskDocuments = null,Object? documents = null,Object? updatedAt = null,Object? archivedAt = null,}) {
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
as Map<String, String>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,enableApplyingPayments: null == enableApplyingPayments ? _self.enableApplyingPayments : enableApplyingPayments // ignore: cast_nullable_to_non_nullable
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
as bool,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<DocumentApi>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CompanyApi
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


/// Adds pattern-matching-related methods to [CompanyApi].
extension CompanyApiPatterns on CompanyApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompanyApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompanyApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompanyApi value)  $default,){
final _that = this;
switch (_that) {
case _CompanyApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompanyApi value)?  $default,){
final _that = this;
switch (_that) {
case _CompanyApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'display_name')  String displayName,  String name, @JsonKey(name: 'company_key')  String companyKey, @JsonKey(name: 'size_id')  String sizeId, @JsonKey(name: 'industry_id')  String industryId, @JsonKey(name: 'first_month_of_year')  String firstMonthOfYear, @JsonKey(name: 'first_day_of_week')  String firstDayOfWeek, @JsonKey(name: 'enabled_modules')  int enabledModules, @JsonKey(name: 'legal_entity_id')  int legalEntityId, @JsonKey(name: 'subdomain')  String subdomain, @JsonKey(name: 'portal_domain')  String portalDomain, @JsonKey(name: 'portal_mode')  String portalMode, @JsonKey(name: 'custom_fields')  Map<String, String> customFields,  Map<String, dynamic> settings, @JsonKey(name: 'enable_applying_payments')  bool enableApplyingPayments, @JsonKey(name: 'convert_payment_currency')  bool convertPaymentCurrency, @JsonKey(name: 'enabled_tax_rates')  int enabledTaxRates, @JsonKey(name: 'enabled_item_tax_rates')  int enabledItemTaxRates, @JsonKey(name: 'enabled_expense_tax_rates')  int enabledExpenseTaxRates, @JsonKey(name: 'calculate_taxes')  bool calculateTaxes, @JsonKey(name: 'tax_data')  TaxConfigApi? taxData, @JsonKey(name: 'track_inventory')  bool trackInventory, @JsonKey(name: 'stock_notification')  bool stockNotification, @JsonKey(name: 'inventory_notification_threshold')  int inventoryNotificationThreshold, @JsonKey(name: 'enable_product_discount')  bool enableProductDiscount, @JsonKey(name: 'enable_product_cost')  bool enableProductCost, @JsonKey(name: 'enable_product_quantity')  bool enableProductQuantity, @JsonKey(name: 'default_quantity')  bool defaultQuantity, @JsonKey(name: 'show_product_details')  bool showProductDetails, @JsonKey(name: 'fill_products')  bool fillProducts, @JsonKey(name: 'update_products')  bool updateProducts, @JsonKey(name: 'convert_products')  bool convertProducts, @JsonKey(name: 'convert_rate_to_client')  bool convertRateToClient, @JsonKey(name: 'stop_on_unpaid_recurring')  bool stopOnUnpaidRecurring, @JsonKey(name: 'use_quote_terms_on_conversion')  bool useQuoteTermsOnConversion, @JsonKey(name: 'auto_start_tasks')  bool autoStartTasks, @JsonKey(name: 'show_task_end_date')  bool showTaskEndDate, @JsonKey(name: 'show_tasks_table')  bool showTasksTable, @JsonKey(name: 'invoice_task_datelog')  bool invoiceTaskDatelog, @JsonKey(name: 'invoice_task_timelog')  bool invoiceTaskTimelog, @JsonKey(name: 'invoice_task_hours')  bool invoiceTaskHours, @JsonKey(name: 'invoice_task_item_description')  bool invoiceTaskItemDescription, @JsonKey(name: 'invoice_task_project')  bool invoiceTaskProject, @JsonKey(name: 'invoice_task_project_header')  bool invoiceTaskProjectHeader, @JsonKey(name: 'invoice_task_lock')  bool invoiceTaskLock, @JsonKey(name: 'invoice_task_documents')  bool invoiceTaskDocuments,  List<DocumentApi> documents, @JsonKey(name: 'updated_at')  int updatedAt, @JsonKey(name: 'archived_at')  int archivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompanyApi() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.settings,_that.enableApplyingPayments,_that.convertPaymentCurrency,_that.enabledTaxRates,_that.enabledItemTaxRates,_that.enabledExpenseTaxRates,_that.calculateTaxes,_that.taxData,_that.trackInventory,_that.stockNotification,_that.inventoryNotificationThreshold,_that.enableProductDiscount,_that.enableProductCost,_that.enableProductQuantity,_that.defaultQuantity,_that.showProductDetails,_that.fillProducts,_that.updateProducts,_that.convertProducts,_that.convertRateToClient,_that.stopOnUnpaidRecurring,_that.useQuoteTermsOnConversion,_that.autoStartTasks,_that.showTaskEndDate,_that.showTasksTable,_that.invoiceTaskDatelog,_that.invoiceTaskTimelog,_that.invoiceTaskHours,_that.invoiceTaskItemDescription,_that.invoiceTaskProject,_that.invoiceTaskProjectHeader,_that.invoiceTaskLock,_that.invoiceTaskDocuments,_that.documents,_that.updatedAt,_that.archivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'display_name')  String displayName,  String name, @JsonKey(name: 'company_key')  String companyKey, @JsonKey(name: 'size_id')  String sizeId, @JsonKey(name: 'industry_id')  String industryId, @JsonKey(name: 'first_month_of_year')  String firstMonthOfYear, @JsonKey(name: 'first_day_of_week')  String firstDayOfWeek, @JsonKey(name: 'enabled_modules')  int enabledModules, @JsonKey(name: 'legal_entity_id')  int legalEntityId, @JsonKey(name: 'subdomain')  String subdomain, @JsonKey(name: 'portal_domain')  String portalDomain, @JsonKey(name: 'portal_mode')  String portalMode, @JsonKey(name: 'custom_fields')  Map<String, String> customFields,  Map<String, dynamic> settings, @JsonKey(name: 'enable_applying_payments')  bool enableApplyingPayments, @JsonKey(name: 'convert_payment_currency')  bool convertPaymentCurrency, @JsonKey(name: 'enabled_tax_rates')  int enabledTaxRates, @JsonKey(name: 'enabled_item_tax_rates')  int enabledItemTaxRates, @JsonKey(name: 'enabled_expense_tax_rates')  int enabledExpenseTaxRates, @JsonKey(name: 'calculate_taxes')  bool calculateTaxes, @JsonKey(name: 'tax_data')  TaxConfigApi? taxData, @JsonKey(name: 'track_inventory')  bool trackInventory, @JsonKey(name: 'stock_notification')  bool stockNotification, @JsonKey(name: 'inventory_notification_threshold')  int inventoryNotificationThreshold, @JsonKey(name: 'enable_product_discount')  bool enableProductDiscount, @JsonKey(name: 'enable_product_cost')  bool enableProductCost, @JsonKey(name: 'enable_product_quantity')  bool enableProductQuantity, @JsonKey(name: 'default_quantity')  bool defaultQuantity, @JsonKey(name: 'show_product_details')  bool showProductDetails, @JsonKey(name: 'fill_products')  bool fillProducts, @JsonKey(name: 'update_products')  bool updateProducts, @JsonKey(name: 'convert_products')  bool convertProducts, @JsonKey(name: 'convert_rate_to_client')  bool convertRateToClient, @JsonKey(name: 'stop_on_unpaid_recurring')  bool stopOnUnpaidRecurring, @JsonKey(name: 'use_quote_terms_on_conversion')  bool useQuoteTermsOnConversion, @JsonKey(name: 'auto_start_tasks')  bool autoStartTasks, @JsonKey(name: 'show_task_end_date')  bool showTaskEndDate, @JsonKey(name: 'show_tasks_table')  bool showTasksTable, @JsonKey(name: 'invoice_task_datelog')  bool invoiceTaskDatelog, @JsonKey(name: 'invoice_task_timelog')  bool invoiceTaskTimelog, @JsonKey(name: 'invoice_task_hours')  bool invoiceTaskHours, @JsonKey(name: 'invoice_task_item_description')  bool invoiceTaskItemDescription, @JsonKey(name: 'invoice_task_project')  bool invoiceTaskProject, @JsonKey(name: 'invoice_task_project_header')  bool invoiceTaskProjectHeader, @JsonKey(name: 'invoice_task_lock')  bool invoiceTaskLock, @JsonKey(name: 'invoice_task_documents')  bool invoiceTaskDocuments,  List<DocumentApi> documents, @JsonKey(name: 'updated_at')  int updatedAt, @JsonKey(name: 'archived_at')  int archivedAt)  $default,) {final _that = this;
switch (_that) {
case _CompanyApi():
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.settings,_that.enableApplyingPayments,_that.convertPaymentCurrency,_that.enabledTaxRates,_that.enabledItemTaxRates,_that.enabledExpenseTaxRates,_that.calculateTaxes,_that.taxData,_that.trackInventory,_that.stockNotification,_that.inventoryNotificationThreshold,_that.enableProductDiscount,_that.enableProductCost,_that.enableProductQuantity,_that.defaultQuantity,_that.showProductDetails,_that.fillProducts,_that.updateProducts,_that.convertProducts,_that.convertRateToClient,_that.stopOnUnpaidRecurring,_that.useQuoteTermsOnConversion,_that.autoStartTasks,_that.showTaskEndDate,_that.showTasksTable,_that.invoiceTaskDatelog,_that.invoiceTaskTimelog,_that.invoiceTaskHours,_that.invoiceTaskItemDescription,_that.invoiceTaskProject,_that.invoiceTaskProjectHeader,_that.invoiceTaskLock,_that.invoiceTaskDocuments,_that.documents,_that.updatedAt,_that.archivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'display_name')  String displayName,  String name, @JsonKey(name: 'company_key')  String companyKey, @JsonKey(name: 'size_id')  String sizeId, @JsonKey(name: 'industry_id')  String industryId, @JsonKey(name: 'first_month_of_year')  String firstMonthOfYear, @JsonKey(name: 'first_day_of_week')  String firstDayOfWeek, @JsonKey(name: 'enabled_modules')  int enabledModules, @JsonKey(name: 'legal_entity_id')  int legalEntityId, @JsonKey(name: 'subdomain')  String subdomain, @JsonKey(name: 'portal_domain')  String portalDomain, @JsonKey(name: 'portal_mode')  String portalMode, @JsonKey(name: 'custom_fields')  Map<String, String> customFields,  Map<String, dynamic> settings, @JsonKey(name: 'enable_applying_payments')  bool enableApplyingPayments, @JsonKey(name: 'convert_payment_currency')  bool convertPaymentCurrency, @JsonKey(name: 'enabled_tax_rates')  int enabledTaxRates, @JsonKey(name: 'enabled_item_tax_rates')  int enabledItemTaxRates, @JsonKey(name: 'enabled_expense_tax_rates')  int enabledExpenseTaxRates, @JsonKey(name: 'calculate_taxes')  bool calculateTaxes, @JsonKey(name: 'tax_data')  TaxConfigApi? taxData, @JsonKey(name: 'track_inventory')  bool trackInventory, @JsonKey(name: 'stock_notification')  bool stockNotification, @JsonKey(name: 'inventory_notification_threshold')  int inventoryNotificationThreshold, @JsonKey(name: 'enable_product_discount')  bool enableProductDiscount, @JsonKey(name: 'enable_product_cost')  bool enableProductCost, @JsonKey(name: 'enable_product_quantity')  bool enableProductQuantity, @JsonKey(name: 'default_quantity')  bool defaultQuantity, @JsonKey(name: 'show_product_details')  bool showProductDetails, @JsonKey(name: 'fill_products')  bool fillProducts, @JsonKey(name: 'update_products')  bool updateProducts, @JsonKey(name: 'convert_products')  bool convertProducts, @JsonKey(name: 'convert_rate_to_client')  bool convertRateToClient, @JsonKey(name: 'stop_on_unpaid_recurring')  bool stopOnUnpaidRecurring, @JsonKey(name: 'use_quote_terms_on_conversion')  bool useQuoteTermsOnConversion, @JsonKey(name: 'auto_start_tasks')  bool autoStartTasks, @JsonKey(name: 'show_task_end_date')  bool showTaskEndDate, @JsonKey(name: 'show_tasks_table')  bool showTasksTable, @JsonKey(name: 'invoice_task_datelog')  bool invoiceTaskDatelog, @JsonKey(name: 'invoice_task_timelog')  bool invoiceTaskTimelog, @JsonKey(name: 'invoice_task_hours')  bool invoiceTaskHours, @JsonKey(name: 'invoice_task_item_description')  bool invoiceTaskItemDescription, @JsonKey(name: 'invoice_task_project')  bool invoiceTaskProject, @JsonKey(name: 'invoice_task_project_header')  bool invoiceTaskProjectHeader, @JsonKey(name: 'invoice_task_lock')  bool invoiceTaskLock, @JsonKey(name: 'invoice_task_documents')  bool invoiceTaskDocuments,  List<DocumentApi> documents, @JsonKey(name: 'updated_at')  int updatedAt, @JsonKey(name: 'archived_at')  int archivedAt)?  $default,) {final _that = this;
switch (_that) {
case _CompanyApi() when $default != null:
return $default(_that.id,_that.displayName,_that.name,_that.companyKey,_that.sizeId,_that.industryId,_that.firstMonthOfYear,_that.firstDayOfWeek,_that.enabledModules,_that.legalEntityId,_that.subdomain,_that.portalDomain,_that.portalMode,_that.customFields,_that.settings,_that.enableApplyingPayments,_that.convertPaymentCurrency,_that.enabledTaxRates,_that.enabledItemTaxRates,_that.enabledExpenseTaxRates,_that.calculateTaxes,_that.taxData,_that.trackInventory,_that.stockNotification,_that.inventoryNotificationThreshold,_that.enableProductDiscount,_that.enableProductCost,_that.enableProductQuantity,_that.defaultQuantity,_that.showProductDetails,_that.fillProducts,_that.updateProducts,_that.convertProducts,_that.convertRateToClient,_that.stopOnUnpaidRecurring,_that.useQuoteTermsOnConversion,_that.autoStartTasks,_that.showTaskEndDate,_that.showTasksTable,_that.invoiceTaskDatelog,_that.invoiceTaskTimelog,_that.invoiceTaskHours,_that.invoiceTaskItemDescription,_that.invoiceTaskProject,_that.invoiceTaskProjectHeader,_that.invoiceTaskLock,_that.invoiceTaskDocuments,_that.documents,_that.updatedAt,_that.archivedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _CompanyApi implements CompanyApi {
  const _CompanyApi({this.id = '', @JsonKey(name: 'display_name') this.displayName = '', this.name = '', @JsonKey(name: 'company_key') this.companyKey = '', @JsonKey(name: 'size_id') this.sizeId = '', @JsonKey(name: 'industry_id') this.industryId = '', @JsonKey(name: 'first_month_of_year') this.firstMonthOfYear = '', @JsonKey(name: 'first_day_of_week') this.firstDayOfWeek = '', @JsonKey(name: 'enabled_modules') this.enabledModules = 0, @JsonKey(name: 'legal_entity_id') this.legalEntityId = 0, @JsonKey(name: 'subdomain') this.subdomain = '', @JsonKey(name: 'portal_domain') this.portalDomain = '', @JsonKey(name: 'portal_mode') this.portalMode = '', @JsonKey(name: 'custom_fields') final  Map<String, String> customFields = const <String, String>{}, final  Map<String, dynamic> settings = const <String, dynamic>{}, @JsonKey(name: 'enable_applying_payments') this.enableApplyingPayments = false, @JsonKey(name: 'convert_payment_currency') this.convertPaymentCurrency = false, @JsonKey(name: 'enabled_tax_rates') this.enabledTaxRates = 0, @JsonKey(name: 'enabled_item_tax_rates') this.enabledItemTaxRates = 0, @JsonKey(name: 'enabled_expense_tax_rates') this.enabledExpenseTaxRates = 0, @JsonKey(name: 'calculate_taxes') this.calculateTaxes = false, @JsonKey(name: 'tax_data') this.taxData, @JsonKey(name: 'track_inventory') this.trackInventory = false, @JsonKey(name: 'stock_notification') this.stockNotification = false, @JsonKey(name: 'inventory_notification_threshold') this.inventoryNotificationThreshold = 0, @JsonKey(name: 'enable_product_discount') this.enableProductDiscount = false, @JsonKey(name: 'enable_product_cost') this.enableProductCost = false, @JsonKey(name: 'enable_product_quantity') this.enableProductQuantity = false, @JsonKey(name: 'default_quantity') this.defaultQuantity = false, @JsonKey(name: 'show_product_details') this.showProductDetails = false, @JsonKey(name: 'fill_products') this.fillProducts = false, @JsonKey(name: 'update_products') this.updateProducts = false, @JsonKey(name: 'convert_products') this.convertProducts = false, @JsonKey(name: 'convert_rate_to_client') this.convertRateToClient = false, @JsonKey(name: 'stop_on_unpaid_recurring') this.stopOnUnpaidRecurring = false, @JsonKey(name: 'use_quote_terms_on_conversion') this.useQuoteTermsOnConversion = false, @JsonKey(name: 'auto_start_tasks') this.autoStartTasks = false, @JsonKey(name: 'show_task_end_date') this.showTaskEndDate = false, @JsonKey(name: 'show_tasks_table') this.showTasksTable = false, @JsonKey(name: 'invoice_task_datelog') this.invoiceTaskDatelog = false, @JsonKey(name: 'invoice_task_timelog') this.invoiceTaskTimelog = false, @JsonKey(name: 'invoice_task_hours') this.invoiceTaskHours = false, @JsonKey(name: 'invoice_task_item_description') this.invoiceTaskItemDescription = false, @JsonKey(name: 'invoice_task_project') this.invoiceTaskProject = false, @JsonKey(name: 'invoice_task_project_header') this.invoiceTaskProjectHeader = false, @JsonKey(name: 'invoice_task_lock') this.invoiceTaskLock = false, @JsonKey(name: 'invoice_task_documents') this.invoiceTaskDocuments = false, final  List<DocumentApi> documents = const <DocumentApi>[], @JsonKey(name: 'updated_at') this.updatedAt = 0, @JsonKey(name: 'archived_at') this.archivedAt = 0}): _customFields = customFields,_settings = settings,_documents = documents;
  factory _CompanyApi.fromJson(Map<String, dynamic> json) => _$CompanyApiFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'company_key') final  String companyKey;
@override@JsonKey(name: 'size_id') final  String sizeId;
@override@JsonKey(name: 'industry_id') final  String industryId;
@override@JsonKey(name: 'first_month_of_year') final  String firstMonthOfYear;
@override@JsonKey(name: 'first_day_of_week') final  String firstDayOfWeek;
@override@JsonKey(name: 'enabled_modules') final  int enabledModules;
@override@JsonKey(name: 'legal_entity_id') final  int legalEntityId;
@override@JsonKey(name: 'subdomain') final  String subdomain;
@override@JsonKey(name: 'portal_domain') final  String portalDomain;
@override@JsonKey(name: 'portal_mode') final  String portalMode;
 final  Map<String, String> _customFields;
@override@JsonKey(name: 'custom_fields') Map<String, String> get customFields {
  if (_customFields is EqualUnmodifiableMapView) return _customFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customFields);
}

 final  Map<String, dynamic> _settings;
@override@JsonKey() Map<String, dynamic> get settings {
  if (_settings is EqualUnmodifiableMapView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_settings);
}

@override@JsonKey(name: 'enable_applying_payments') final  bool enableApplyingPayments;
@override@JsonKey(name: 'convert_payment_currency') final  bool convertPaymentCurrency;
// ── Tax configuration ────────────────────────────────────────────────
// The three count fields, `calculate_taxes` and `tax_data` live at
// company top-level, not in settings — matching the server contract
// and the legacy admin-portal / React clients.
@override@JsonKey(name: 'enabled_tax_rates') final  int enabledTaxRates;
@override@JsonKey(name: 'enabled_item_tax_rates') final  int enabledItemTaxRates;
@override@JsonKey(name: 'enabled_expense_tax_rates') final  int enabledExpenseTaxRates;
@override@JsonKey(name: 'calculate_taxes') final  bool calculateTaxes;
@override@JsonKey(name: 'tax_data') final  TaxConfigApi? taxData;
// ── Product configuration ───────────────────────────────────────────
// Top-level company fields edited by Settings → Product Settings.
// Defaults stay false/0 so a fresh CompanyApi constructor doesn't
// invent values; `Company.fromApi` always overlays whatever the wire
// sent.
@override@JsonKey(name: 'track_inventory') final  bool trackInventory;
@override@JsonKey(name: 'stock_notification') final  bool stockNotification;
@override@JsonKey(name: 'inventory_notification_threshold') final  int inventoryNotificationThreshold;
@override@JsonKey(name: 'enable_product_discount') final  bool enableProductDiscount;
@override@JsonKey(name: 'enable_product_cost') final  bool enableProductCost;
@override@JsonKey(name: 'enable_product_quantity') final  bool enableProductQuantity;
@override@JsonKey(name: 'default_quantity') final  bool defaultQuantity;
@override@JsonKey(name: 'show_product_details') final  bool showProductDetails;
@override@JsonKey(name: 'fill_products') final  bool fillProducts;
@override@JsonKey(name: 'update_products') final  bool updateProducts;
@override@JsonKey(name: 'convert_products') final  bool convertProducts;
@override@JsonKey(name: 'convert_rate_to_client') final  bool convertRateToClient;
// ── Workflow ────────────────────────────────────────────────────────
// Top-level company fields edited by Settings → Workflow Settings.
// Only the company-scope rows on that page; the per-entity workflow
// toggles live under `settings.*` (auto_email_invoice, lock_invoices,
// etc.) on `CompanySettingsApi`.
@override@JsonKey(name: 'stop_on_unpaid_recurring') final  bool stopOnUnpaidRecurring;
@override@JsonKey(name: 'use_quote_terms_on_conversion') final  bool useQuoteTermsOnConversion;
// ── Task configuration ──────────────────────────────────────────────
// Top-level company fields edited by Settings → Task Settings. Per-entity
// task toggles (`default_task_rate`, `task_round_up`, …) live on
// `CompanySettingsApi`. `invoiceTaskProjectHeader`: false = service,
// true = description (parity with legacy admin-portal).
@override@JsonKey(name: 'auto_start_tasks') final  bool autoStartTasks;
@override@JsonKey(name: 'show_task_end_date') final  bool showTaskEndDate;
@override@JsonKey(name: 'show_tasks_table') final  bool showTasksTable;
@override@JsonKey(name: 'invoice_task_datelog') final  bool invoiceTaskDatelog;
@override@JsonKey(name: 'invoice_task_timelog') final  bool invoiceTaskTimelog;
@override@JsonKey(name: 'invoice_task_hours') final  bool invoiceTaskHours;
@override@JsonKey(name: 'invoice_task_item_description') final  bool invoiceTaskItemDescription;
@override@JsonKey(name: 'invoice_task_project') final  bool invoiceTaskProject;
@override@JsonKey(name: 'invoice_task_project_header') final  bool invoiceTaskProjectHeader;
@override@JsonKey(name: 'invoice_task_lock') final  bool invoiceTaskLock;
@override@JsonKey(name: 'invoice_task_documents') final  bool invoiceTaskDocuments;
 final  List<DocumentApi> _documents;
@override@JsonKey() List<DocumentApi> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

@override@JsonKey(name: 'updated_at') final  int updatedAt;
@override@JsonKey(name: 'archived_at') final  int archivedAt;

/// Create a copy of CompanyApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanyApiCopyWith<_CompanyApi> get copyWith => __$CompanyApiCopyWithImpl<_CompanyApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompanyApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompanyApi&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyKey, companyKey) || other.companyKey == companyKey)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.firstMonthOfYear, firstMonthOfYear) || other.firstMonthOfYear == firstMonthOfYear)&&(identical(other.firstDayOfWeek, firstDayOfWeek) || other.firstDayOfWeek == firstDayOfWeek)&&(identical(other.enabledModules, enabledModules) || other.enabledModules == enabledModules)&&(identical(other.legalEntityId, legalEntityId) || other.legalEntityId == legalEntityId)&&(identical(other.subdomain, subdomain) || other.subdomain == subdomain)&&(identical(other.portalDomain, portalDomain) || other.portalDomain == portalDomain)&&(identical(other.portalMode, portalMode) || other.portalMode == portalMode)&&const DeepCollectionEquality().equals(other._customFields, _customFields)&&const DeepCollectionEquality().equals(other._settings, _settings)&&(identical(other.enableApplyingPayments, enableApplyingPayments) || other.enableApplyingPayments == enableApplyingPayments)&&(identical(other.convertPaymentCurrency, convertPaymentCurrency) || other.convertPaymentCurrency == convertPaymentCurrency)&&(identical(other.enabledTaxRates, enabledTaxRates) || other.enabledTaxRates == enabledTaxRates)&&(identical(other.enabledItemTaxRates, enabledItemTaxRates) || other.enabledItemTaxRates == enabledItemTaxRates)&&(identical(other.enabledExpenseTaxRates, enabledExpenseTaxRates) || other.enabledExpenseTaxRates == enabledExpenseTaxRates)&&(identical(other.calculateTaxes, calculateTaxes) || other.calculateTaxes == calculateTaxes)&&(identical(other.taxData, taxData) || other.taxData == taxData)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory)&&(identical(other.stockNotification, stockNotification) || other.stockNotification == stockNotification)&&(identical(other.inventoryNotificationThreshold, inventoryNotificationThreshold) || other.inventoryNotificationThreshold == inventoryNotificationThreshold)&&(identical(other.enableProductDiscount, enableProductDiscount) || other.enableProductDiscount == enableProductDiscount)&&(identical(other.enableProductCost, enableProductCost) || other.enableProductCost == enableProductCost)&&(identical(other.enableProductQuantity, enableProductQuantity) || other.enableProductQuantity == enableProductQuantity)&&(identical(other.defaultQuantity, defaultQuantity) || other.defaultQuantity == defaultQuantity)&&(identical(other.showProductDetails, showProductDetails) || other.showProductDetails == showProductDetails)&&(identical(other.fillProducts, fillProducts) || other.fillProducts == fillProducts)&&(identical(other.updateProducts, updateProducts) || other.updateProducts == updateProducts)&&(identical(other.convertProducts, convertProducts) || other.convertProducts == convertProducts)&&(identical(other.convertRateToClient, convertRateToClient) || other.convertRateToClient == convertRateToClient)&&(identical(other.stopOnUnpaidRecurring, stopOnUnpaidRecurring) || other.stopOnUnpaidRecurring == stopOnUnpaidRecurring)&&(identical(other.useQuoteTermsOnConversion, useQuoteTermsOnConversion) || other.useQuoteTermsOnConversion == useQuoteTermsOnConversion)&&(identical(other.autoStartTasks, autoStartTasks) || other.autoStartTasks == autoStartTasks)&&(identical(other.showTaskEndDate, showTaskEndDate) || other.showTaskEndDate == showTaskEndDate)&&(identical(other.showTasksTable, showTasksTable) || other.showTasksTable == showTasksTable)&&(identical(other.invoiceTaskDatelog, invoiceTaskDatelog) || other.invoiceTaskDatelog == invoiceTaskDatelog)&&(identical(other.invoiceTaskTimelog, invoiceTaskTimelog) || other.invoiceTaskTimelog == invoiceTaskTimelog)&&(identical(other.invoiceTaskHours, invoiceTaskHours) || other.invoiceTaskHours == invoiceTaskHours)&&(identical(other.invoiceTaskItemDescription, invoiceTaskItemDescription) || other.invoiceTaskItemDescription == invoiceTaskItemDescription)&&(identical(other.invoiceTaskProject, invoiceTaskProject) || other.invoiceTaskProject == invoiceTaskProject)&&(identical(other.invoiceTaskProjectHeader, invoiceTaskProjectHeader) || other.invoiceTaskProjectHeader == invoiceTaskProjectHeader)&&(identical(other.invoiceTaskLock, invoiceTaskLock) || other.invoiceTaskLock == invoiceTaskLock)&&(identical(other.invoiceTaskDocuments, invoiceTaskDocuments) || other.invoiceTaskDocuments == invoiceTaskDocuments)&&const DeepCollectionEquality().equals(other._documents, _documents)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,displayName,name,companyKey,sizeId,industryId,firstMonthOfYear,firstDayOfWeek,enabledModules,legalEntityId,subdomain,portalDomain,portalMode,const DeepCollectionEquality().hash(_customFields),const DeepCollectionEquality().hash(_settings),enableApplyingPayments,convertPaymentCurrency,enabledTaxRates,enabledItemTaxRates,enabledExpenseTaxRates,calculateTaxes,taxData,trackInventory,stockNotification,inventoryNotificationThreshold,enableProductDiscount,enableProductCost,enableProductQuantity,defaultQuantity,showProductDetails,fillProducts,updateProducts,convertProducts,convertRateToClient,stopOnUnpaidRecurring,useQuoteTermsOnConversion,autoStartTasks,showTaskEndDate,showTasksTable,invoiceTaskDatelog,invoiceTaskTimelog,invoiceTaskHours,invoiceTaskItemDescription,invoiceTaskProject,invoiceTaskProjectHeader,invoiceTaskLock,invoiceTaskDocuments,const DeepCollectionEquality().hash(_documents),updatedAt,archivedAt]);

@override
String toString() {
  return 'CompanyApi(id: $id, displayName: $displayName, name: $name, companyKey: $companyKey, sizeId: $sizeId, industryId: $industryId, firstMonthOfYear: $firstMonthOfYear, firstDayOfWeek: $firstDayOfWeek, enabledModules: $enabledModules, legalEntityId: $legalEntityId, subdomain: $subdomain, portalDomain: $portalDomain, portalMode: $portalMode, customFields: $customFields, settings: $settings, enableApplyingPayments: $enableApplyingPayments, convertPaymentCurrency: $convertPaymentCurrency, enabledTaxRates: $enabledTaxRates, enabledItemTaxRates: $enabledItemTaxRates, enabledExpenseTaxRates: $enabledExpenseTaxRates, calculateTaxes: $calculateTaxes, taxData: $taxData, trackInventory: $trackInventory, stockNotification: $stockNotification, inventoryNotificationThreshold: $inventoryNotificationThreshold, enableProductDiscount: $enableProductDiscount, enableProductCost: $enableProductCost, enableProductQuantity: $enableProductQuantity, defaultQuantity: $defaultQuantity, showProductDetails: $showProductDetails, fillProducts: $fillProducts, updateProducts: $updateProducts, convertProducts: $convertProducts, convertRateToClient: $convertRateToClient, stopOnUnpaidRecurring: $stopOnUnpaidRecurring, useQuoteTermsOnConversion: $useQuoteTermsOnConversion, autoStartTasks: $autoStartTasks, showTaskEndDate: $showTaskEndDate, showTasksTable: $showTasksTable, invoiceTaskDatelog: $invoiceTaskDatelog, invoiceTaskTimelog: $invoiceTaskTimelog, invoiceTaskHours: $invoiceTaskHours, invoiceTaskItemDescription: $invoiceTaskItemDescription, invoiceTaskProject: $invoiceTaskProject, invoiceTaskProjectHeader: $invoiceTaskProjectHeader, invoiceTaskLock: $invoiceTaskLock, invoiceTaskDocuments: $invoiceTaskDocuments, documents: $documents, updatedAt: $updatedAt, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class _$CompanyApiCopyWith<$Res> implements $CompanyApiCopyWith<$Res> {
  factory _$CompanyApiCopyWith(_CompanyApi value, $Res Function(_CompanyApi) _then) = __$CompanyApiCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'display_name') String displayName, String name,@JsonKey(name: 'company_key') String companyKey,@JsonKey(name: 'size_id') String sizeId,@JsonKey(name: 'industry_id') String industryId,@JsonKey(name: 'first_month_of_year') String firstMonthOfYear,@JsonKey(name: 'first_day_of_week') String firstDayOfWeek,@JsonKey(name: 'enabled_modules') int enabledModules,@JsonKey(name: 'legal_entity_id') int legalEntityId,@JsonKey(name: 'subdomain') String subdomain,@JsonKey(name: 'portal_domain') String portalDomain,@JsonKey(name: 'portal_mode') String portalMode,@JsonKey(name: 'custom_fields') Map<String, String> customFields, Map<String, dynamic> settings,@JsonKey(name: 'enable_applying_payments') bool enableApplyingPayments,@JsonKey(name: 'convert_payment_currency') bool convertPaymentCurrency,@JsonKey(name: 'enabled_tax_rates') int enabledTaxRates,@JsonKey(name: 'enabled_item_tax_rates') int enabledItemTaxRates,@JsonKey(name: 'enabled_expense_tax_rates') int enabledExpenseTaxRates,@JsonKey(name: 'calculate_taxes') bool calculateTaxes,@JsonKey(name: 'tax_data') TaxConfigApi? taxData,@JsonKey(name: 'track_inventory') bool trackInventory,@JsonKey(name: 'stock_notification') bool stockNotification,@JsonKey(name: 'inventory_notification_threshold') int inventoryNotificationThreshold,@JsonKey(name: 'enable_product_discount') bool enableProductDiscount,@JsonKey(name: 'enable_product_cost') bool enableProductCost,@JsonKey(name: 'enable_product_quantity') bool enableProductQuantity,@JsonKey(name: 'default_quantity') bool defaultQuantity,@JsonKey(name: 'show_product_details') bool showProductDetails,@JsonKey(name: 'fill_products') bool fillProducts,@JsonKey(name: 'update_products') bool updateProducts,@JsonKey(name: 'convert_products') bool convertProducts,@JsonKey(name: 'convert_rate_to_client') bool convertRateToClient,@JsonKey(name: 'stop_on_unpaid_recurring') bool stopOnUnpaidRecurring,@JsonKey(name: 'use_quote_terms_on_conversion') bool useQuoteTermsOnConversion,@JsonKey(name: 'auto_start_tasks') bool autoStartTasks,@JsonKey(name: 'show_task_end_date') bool showTaskEndDate,@JsonKey(name: 'show_tasks_table') bool showTasksTable,@JsonKey(name: 'invoice_task_datelog') bool invoiceTaskDatelog,@JsonKey(name: 'invoice_task_timelog') bool invoiceTaskTimelog,@JsonKey(name: 'invoice_task_hours') bool invoiceTaskHours,@JsonKey(name: 'invoice_task_item_description') bool invoiceTaskItemDescription,@JsonKey(name: 'invoice_task_project') bool invoiceTaskProject,@JsonKey(name: 'invoice_task_project_header') bool invoiceTaskProjectHeader,@JsonKey(name: 'invoice_task_lock') bool invoiceTaskLock,@JsonKey(name: 'invoice_task_documents') bool invoiceTaskDocuments, List<DocumentApi> documents,@JsonKey(name: 'updated_at') int updatedAt,@JsonKey(name: 'archived_at') int archivedAt
});


@override $TaxConfigApiCopyWith<$Res>? get taxData;

}
/// @nodoc
class __$CompanyApiCopyWithImpl<$Res>
    implements _$CompanyApiCopyWith<$Res> {
  __$CompanyApiCopyWithImpl(this._self, this._then);

  final _CompanyApi _self;
  final $Res Function(_CompanyApi) _then;

/// Create a copy of CompanyApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? name = null,Object? companyKey = null,Object? sizeId = null,Object? industryId = null,Object? firstMonthOfYear = null,Object? firstDayOfWeek = null,Object? enabledModules = null,Object? legalEntityId = null,Object? subdomain = null,Object? portalDomain = null,Object? portalMode = null,Object? customFields = null,Object? settings = null,Object? enableApplyingPayments = null,Object? convertPaymentCurrency = null,Object? enabledTaxRates = null,Object? enabledItemTaxRates = null,Object? enabledExpenseTaxRates = null,Object? calculateTaxes = null,Object? taxData = freezed,Object? trackInventory = null,Object? stockNotification = null,Object? inventoryNotificationThreshold = null,Object? enableProductDiscount = null,Object? enableProductCost = null,Object? enableProductQuantity = null,Object? defaultQuantity = null,Object? showProductDetails = null,Object? fillProducts = null,Object? updateProducts = null,Object? convertProducts = null,Object? convertRateToClient = null,Object? stopOnUnpaidRecurring = null,Object? useQuoteTermsOnConversion = null,Object? autoStartTasks = null,Object? showTaskEndDate = null,Object? showTasksTable = null,Object? invoiceTaskDatelog = null,Object? invoiceTaskTimelog = null,Object? invoiceTaskHours = null,Object? invoiceTaskItemDescription = null,Object? invoiceTaskProject = null,Object? invoiceTaskProjectHeader = null,Object? invoiceTaskLock = null,Object? invoiceTaskDocuments = null,Object? documents = null,Object? updatedAt = null,Object? archivedAt = null,}) {
  return _then(_CompanyApi(
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
as Map<String, String>,settings: null == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,enableApplyingPayments: null == enableApplyingPayments ? _self.enableApplyingPayments : enableApplyingPayments // ignore: cast_nullable_to_non_nullable
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
as bool,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<DocumentApi>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archivedAt: null == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CompanyApi
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


/// @nodoc
mixin _$CompanyItemApi {

 CompanyApi get data;
/// Create a copy of CompanyItemApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanyItemApiCopyWith<CompanyItemApi> get copyWith => _$CompanyItemApiCopyWithImpl<CompanyItemApi>(this as CompanyItemApi, _$identity);

  /// Serializes this CompanyItemApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanyItemApi&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'CompanyItemApi(data: $data)';
}


}

/// @nodoc
abstract mixin class $CompanyItemApiCopyWith<$Res>  {
  factory $CompanyItemApiCopyWith(CompanyItemApi value, $Res Function(CompanyItemApi) _then) = _$CompanyItemApiCopyWithImpl;
@useResult
$Res call({
 CompanyApi data
});


$CompanyApiCopyWith<$Res> get data;

}
/// @nodoc
class _$CompanyItemApiCopyWithImpl<$Res>
    implements $CompanyItemApiCopyWith<$Res> {
  _$CompanyItemApiCopyWithImpl(this._self, this._then);

  final CompanyItemApi _self;
  final $Res Function(CompanyItemApi) _then;

/// Create a copy of CompanyItemApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as CompanyApi,
  ));
}
/// Create a copy of CompanyItemApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompanyApiCopyWith<$Res> get data {
  
  return $CompanyApiCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [CompanyItemApi].
extension CompanyItemApiPatterns on CompanyItemApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompanyItemApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompanyItemApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompanyItemApi value)  $default,){
final _that = this;
switch (_that) {
case _CompanyItemApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompanyItemApi value)?  $default,){
final _that = this;
switch (_that) {
case _CompanyItemApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CompanyApi data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompanyItemApi() when $default != null:
return $default(_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CompanyApi data)  $default,) {final _that = this;
switch (_that) {
case _CompanyItemApi():
return $default(_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CompanyApi data)?  $default,) {final _that = this;
switch (_that) {
case _CompanyItemApi() when $default != null:
return $default(_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompanyItemApi implements CompanyItemApi {
  const _CompanyItemApi({required this.data});
  factory _CompanyItemApi.fromJson(Map<String, dynamic> json) => _$CompanyItemApiFromJson(json);

@override final  CompanyApi data;

/// Create a copy of CompanyItemApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanyItemApiCopyWith<_CompanyItemApi> get copyWith => __$CompanyItemApiCopyWithImpl<_CompanyItemApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompanyItemApiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompanyItemApi&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'CompanyItemApi(data: $data)';
}


}

/// @nodoc
abstract mixin class _$CompanyItemApiCopyWith<$Res> implements $CompanyItemApiCopyWith<$Res> {
  factory _$CompanyItemApiCopyWith(_CompanyItemApi value, $Res Function(_CompanyItemApi) _then) = __$CompanyItemApiCopyWithImpl;
@override @useResult
$Res call({
 CompanyApi data
});


@override $CompanyApiCopyWith<$Res> get data;

}
/// @nodoc
class __$CompanyItemApiCopyWithImpl<$Res>
    implements _$CompanyItemApiCopyWith<$Res> {
  __$CompanyItemApiCopyWithImpl(this._self, this._then);

  final _CompanyItemApi _self;
  final $Res Function(_CompanyItemApi) _then;

/// Create a copy of CompanyItemApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_CompanyItemApi(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as CompanyApi,
  ));
}

/// Create a copy of CompanyItemApi
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompanyApiCopyWith<$Res> get data {
  
  return $CompanyApiCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

// dart format on
