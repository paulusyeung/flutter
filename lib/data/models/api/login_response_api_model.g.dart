// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginResponseApi _$LoginResponseApiFromJson(Map<String, dynamic> json) =>
    _LoginResponseApi(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => UserCompanyApi.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <UserCompanyApi>[],
      staticData:
          json['static'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$LoginResponseApiToJson(_LoginResponseApi instance) =>
    <String, dynamic>{'data': instance.data, 'static': instance.staticData};

_UserCompanyApi _$UserCompanyApiFromJson(
  Map<String, dynamic> json,
) => _UserCompanyApi(
  isAdmin: json['is_admin'] as bool? ?? false,
  isOwner: json['is_owner'] as bool? ?? false,
  permissions: json['permissions'] as String? ?? '',
  permissionsUpdatedAt: (json['permissions_updated_at'] as num?)?.toInt() ?? 0,
  company: CompanyEnvelopeApi.fromJson(json['company'] as Map<String, dynamic>),
  token: TokenApi.fromJson(json['token'] as Map<String, dynamic>),
  account: AccountEnvelopeApi.fromJson(json['account'] as Map<String, dynamic>),
  settings:
      json['settings'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  user: json['user'] == null
      ? const UserSummaryApi()
      : UserSummaryApi.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserCompanyApiToJson(_UserCompanyApi instance) =>
    <String, dynamic>{
      'is_admin': instance.isAdmin,
      'is_owner': instance.isOwner,
      'permissions': instance.permissions,
      'permissions_updated_at': instance.permissionsUpdatedAt,
      'company': instance.company,
      'token': instance.token,
      'account': instance.account,
      'settings': instance.settings,
      'user': instance.user,
    };

_UserSummaryApi _$UserSummaryApiFromJson(Map<String, dynamic> json) =>
    _UserSummaryApi(
      id: json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      languageId: json['language_id'] as String? ?? '',
      customValue1: json['custom_value1'] as String? ?? '',
      customValue2: json['custom_value2'] as String? ?? '',
      customValue3: json['custom_value3'] as String? ?? '',
      customValue4: json['custom_value4'] as String? ?? '',
      oauthProviderId: json['oauth_provider_id'] as String? ?? '',
      google2faSecret: json['google_2fa_secret'] == null
          ? false
          : _boolFromJson(json['google_2fa_secret']),
      verifiedPhoneNumber: json['verified_phone_number'] == null
          ? false
          : _boolFromJson(json['verified_phone_number']),
    );

Map<String, dynamic> _$UserSummaryApiToJson(_UserSummaryApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'signature': instance.signature,
      'language_id': instance.languageId,
      'custom_value1': instance.customValue1,
      'custom_value2': instance.customValue2,
      'custom_value3': instance.customValue3,
      'custom_value4': instance.customValue4,
      'oauth_provider_id': instance.oauthProviderId,
      'google_2fa_secret': instance.google2faSecret,
      'verified_phone_number': instance.verifiedPhoneNumber,
    };

_CompanyEnvelopeApi _$CompanyEnvelopeApiFromJson(
  Map<String, dynamic> json,
) => _CompanyEnvelopeApi(
  id: json['id'] as String? ?? '',
  displayName: json['display_name'] as String? ?? '',
  name: json['name'] as String? ?? '',
  companyKey: json['company_key'] as String? ?? '',
  customFields:
      (json['custom_fields'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
  sizeId: json['size_id'] as String? ?? '',
  industryId: json['industry_id'] as String? ?? '',
  legalEntityId: (json['legal_entity_id'] as num?)?.toInt() ?? 0,
  enabledModules: (json['enabled_modules'] as num?)?.toInt() ?? 0,
  settings:
      json['settings'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  taskStatuses:
      (json['task_statuses'] as List<dynamic>?)
          ?.map((e) => TaskStatusApi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TaskStatusApi>[],
  companyGateways:
      (json['company_gateways'] as List<dynamic>?)
          ?.map((e) => CompanyGatewayApi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CompanyGatewayApi>[],
  paymentTerms:
      (json['payment_terms'] as List<dynamic>?)
          ?.map((e) => PaymentTermApi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PaymentTermApi>[],
  taxRates:
      (json['tax_rates'] as List<dynamic>?)
          ?.map((e) => TaxRateApi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TaxRateApi>[],
  expenseCategories:
      (json['expense_categories'] as List<dynamic>?)
          ?.map((e) => ExpenseCategoryApi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ExpenseCategoryApi>[],
  enabledTaxRates: (json['enabled_tax_rates'] as num?)?.toInt() ?? 0,
  enabledItemTaxRates: (json['enabled_item_tax_rates'] as num?)?.toInt() ?? 0,
  enabledExpenseTaxRates:
      (json['enabled_expense_tax_rates'] as num?)?.toInt() ?? 0,
  calculateTaxes: json['calculate_taxes'] as bool? ?? false,
  taxData: json['tax_data'] == null
      ? null
      : TaxConfigApi.fromJson(json['tax_data'] as Map<String, dynamic>),
  trackInventory: json['track_inventory'] as bool? ?? false,
  stockNotification: json['stock_notification'] as bool? ?? false,
  inventoryNotificationThreshold:
      (json['inventory_notification_threshold'] as num?)?.toInt() ?? 0,
  enableProductDiscount: json['enable_product_discount'] as bool? ?? false,
  enableProductCost: json['enable_product_cost'] as bool? ?? false,
  enableProductQuantity: json['enable_product_quantity'] as bool? ?? false,
  defaultQuantity: json['default_quantity'] as bool? ?? false,
  showProductDetails: json['show_product_details'] as bool? ?? false,
  fillProducts: json['fill_products'] as bool? ?? false,
  updateProducts: json['update_products'] as bool? ?? false,
  convertProducts: json['convert_products'] as bool? ?? false,
  convertRateToClient: json['convert_rate_to_client'] as bool? ?? false,
  stopOnUnpaidRecurring: json['stop_on_unpaid_recurring'] as bool? ?? false,
  useQuoteTermsOnConversion:
      json['use_quote_terms_on_conversion'] as bool? ?? false,
);

Map<String, dynamic> _$CompanyEnvelopeApiToJson(
  _CompanyEnvelopeApi instance,
) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
  'name': instance.name,
  'company_key': instance.companyKey,
  'custom_fields': instance.customFields,
  'size_id': instance.sizeId,
  'industry_id': instance.industryId,
  'legal_entity_id': instance.legalEntityId,
  'enabled_modules': instance.enabledModules,
  'settings': instance.settings,
  'task_statuses': instance.taskStatuses,
  'company_gateways': instance.companyGateways,
  'payment_terms': instance.paymentTerms,
  'tax_rates': instance.taxRates,
  'expense_categories': instance.expenseCategories,
  'enabled_tax_rates': instance.enabledTaxRates,
  'enabled_item_tax_rates': instance.enabledItemTaxRates,
  'enabled_expense_tax_rates': instance.enabledExpenseTaxRates,
  'calculate_taxes': instance.calculateTaxes,
  'tax_data': instance.taxData,
  'track_inventory': instance.trackInventory,
  'stock_notification': instance.stockNotification,
  'inventory_notification_threshold': instance.inventoryNotificationThreshold,
  'enable_product_discount': instance.enableProductDiscount,
  'enable_product_cost': instance.enableProductCost,
  'enable_product_quantity': instance.enableProductQuantity,
  'default_quantity': instance.defaultQuantity,
  'show_product_details': instance.showProductDetails,
  'fill_products': instance.fillProducts,
  'update_products': instance.updateProducts,
  'convert_products': instance.convertProducts,
  'convert_rate_to_client': instance.convertRateToClient,
  'stop_on_unpaid_recurring': instance.stopOnUnpaidRecurring,
  'use_quote_terms_on_conversion': instance.useQuoteTermsOnConversion,
};

_TokenApi _$TokenApiFromJson(Map<String, dynamic> json) => _TokenApi(
  token: json['token'] as String? ?? '',
  name: json['name'] as String? ?? '',
);

Map<String, dynamic> _$TokenApiToJson(_TokenApi instance) => <String, dynamic>{
  'token': instance.token,
  'name': instance.name,
};

_AccountEnvelopeApi _$AccountEnvelopeApiFromJson(Map<String, dynamic> json) =>
    _AccountEnvelopeApi(
      id: json['id'] as String? ?? '',
      defaultCompanyId: json['default_company_id'] as String? ?? '',
      plan: json['plan'] as String? ?? '',
      numTrialDays: (json['num_trial_days'] as num?)?.toInt() ?? 0,
      hostedClientCount: (json['hosted_client_count'] as num?)?.toInt() ?? 0,
      hostedCompanyCount: (json['hosted_company_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AccountEnvelopeApiToJson(_AccountEnvelopeApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'default_company_id': instance.defaultCompanyId,
      'plan': instance.plan,
      'num_trial_days': instance.numTrialDays,
      'hosted_client_count': instance.hostedClientCount,
      'hosted_company_count': instance.hostedCompanyCount,
    };
