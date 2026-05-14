import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/company_gateway_api_model.dart';
import 'package:admin/data/models/api/expense_category_api_model.dart';
import 'package:admin/data/models/api/payment_term_api_model.dart';
import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/models/api/tax_config_api_model.dart';
import 'package:admin/data/models/api/tax_rate_api_model.dart';

part 'login_response_api_model.freezed.dart';
part 'login_response_api_model.g.dart';

/// Shape of `/api/v1/login` and `/api/v1/refresh`.
///
/// Mirrors `admin-portal/lib/data/models/entities.dart:594` (LoginResponse).
/// `data` is the array of companies this user has access to. `static` is the
/// global reference-data blob (currencies, countries, etc.) — kept as a raw
/// map; `StaticsRepository` parses it lazily.
@freezed
abstract class LoginResponseApi with _$LoginResponseApi {
  const factory LoginResponseApi({
    @Default(<UserCompanyApi>[]) List<UserCompanyApi> data,
    @JsonKey(name: 'static')
    @Default(<String, dynamic>{})
    Map<String, dynamic> staticData,
  }) = _LoginResponseApi;

  factory LoginResponseApi.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseApiFromJson(json);
}

/// One per company this user has access to. The token is per-company.
@freezed
abstract class UserCompanyApi with _$UserCompanyApi {
  const factory UserCompanyApi({
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    @JsonKey(name: 'is_owner') @Default(false) bool isOwner,
    @Default('') String permissions,
    @JsonKey(name: 'permissions_updated_at')
    @Default(0)
    int permissionsUpdatedAt,
    required CompanyEnvelopeApi company,
    required TokenApi token,
    required AccountEnvelopeApi account,
    @Default(<String, dynamic>{}) Map<String, dynamic> settings,
    @JsonKey(name: 'user') @Default(UserSummaryApi()) UserSummaryApi user,
  }) = _UserCompanyApi;

  factory UserCompanyApi.fromJson(Map<String, dynamic> json) =>
      _$UserCompanyApiFromJson(json);
}

/// The authenticated user's record, decoded from `data[N].user` in the
/// `/api/v1/login` and `/api/v1/refresh` response. Carries everything the
/// Settings > User Details screen needs to render (and save through the
/// outbox), so the app never has to round-trip `/api/v1/users/{id}` — that
/// route is password-protected (412), and `/refresh` is not.
@freezed
abstract class UserSummaryApi with _$UserSummaryApi {
  const factory UserSummaryApi({
    @Default('') String id,
    @JsonKey(name: 'first_name') @Default('') String firstName,
    @JsonKey(name: 'last_name') @Default('') String lastName,
    @JsonKey(name: 'email') @Default('') String email,
    @JsonKey(name: 'phone') @Default('') String phone,
    @JsonKey(name: 'signature') @Default('') String signature,
    @JsonKey(name: 'language_id') @Default('') String languageId,
    @JsonKey(name: 'custom_value1') @Default('') String customValue1,
    @JsonKey(name: 'custom_value2') @Default('') String customValue2,
    @JsonKey(name: 'custom_value3') @Default('') String customValue3,
    @JsonKey(name: 'custom_value4') @Default('') String customValue4,
    @JsonKey(name: 'oauth_provider_id') @Default('') String oauthProviderId,
    // Server sends a truthy string ("true"/"1") OR a bool depending on the
    // endpoint, so the JSON converter normalizes to a plain bool.
    @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)
    @Default(false)
    bool google2faSecret,
    @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)
    @Default(false)
    bool verifiedPhoneNumber,
  }) = _UserSummaryApi;

  factory UserSummaryApi.fromJson(Map<String, dynamic> json) =>
      _$UserSummaryApiFromJson(json);
}

bool _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1';
  }
  return false;
}

@freezed
abstract class CompanyEnvelopeApi with _$CompanyEnvelopeApi {
  const factory CompanyEnvelopeApi({
    @Default('') String id,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @Default('') String name,
    @JsonKey(name: 'company_key') @Default('') String companyKey,
    @JsonKey(name: 'custom_fields')
    @Default(<String, String>{})
    Map<String, String> customFields,
    @JsonKey(name: 'size_id') @Default('') String sizeId,
    @JsonKey(name: 'industry_id') @Default('') String industryId,
    @JsonKey(name: 'legal_entity_id') @Default(0) int legalEntityId,
    @JsonKey(name: 'enabled_modules') @Default(0) int enabledModules,
    // `settings` stays as a raw map — every key the server sends is
    // preserved verbatim through the round-trip. Strong-typing here would
    // drop unknown keys at fromJson/toJson, silently corrupting fields
    // we haven't modeled yet. The repository builds the typed view on
    // demand via `CompanySettingsApi.fromJson`.
    @Default(<String, dynamic>{}) Map<String, dynamic> settings,
    // Bundled reference arrays. `/refresh?first_load=true` delivers these
    // alongside the company so the matching repos don't need a separate
    // round-trip on first paint. The pattern matches CLAUDE.md § Data
    // loading — bundled vs per-entity. Add new bundles here as more
    // settings screens come online (tax_rates, designs, …).
    @JsonKey(name: 'task_statuses')
    @Default(<TaskStatusApi>[])
    List<TaskStatusApi> taskStatuses,
    @JsonKey(name: 'company_gateways')
    @Default(<CompanyGatewayApi>[])
    List<CompanyGatewayApi> companyGateways,
    @JsonKey(name: 'payment_terms')
    @Default(<PaymentTermApi>[])
    List<PaymentTermApi> paymentTerms,
    @JsonKey(name: 'tax_rates')
    @Default(<TaxRateApi>[])
    List<TaxRateApi> taxRates,
    @JsonKey(name: 'expense_categories')
    @Default(<ExpenseCategoryApi>[])
    List<ExpenseCategoryApi> expenseCategories,
    // Top-level tax fields on the envelope, mirroring `CompanyApi`. Settings
    // → Tax Settings writes these via `host.updateCompany(...)`.
    @JsonKey(name: 'enabled_tax_rates') @Default(0) int enabledTaxRates,
    @JsonKey(name: 'enabled_item_tax_rates')
    @Default(0)
    int enabledItemTaxRates,
    @JsonKey(name: 'enabled_expense_tax_rates')
    @Default(0)
    int enabledExpenseTaxRates,
    @JsonKey(name: 'calculate_taxes') @Default(false) bool calculateTaxes,
    @JsonKey(name: 'tax_data') TaxConfigApi? taxData,
    // Top-level product configuration on the envelope, mirroring `CompanyApi`.
    // Settings → Product Settings writes these via `vm.updateCompany(...)`;
    // the login envelope persists them straight into the `companies` Drift
    // table so they're available offline before the first refresh.
    @JsonKey(name: 'track_inventory') @Default(false) bool trackInventory,
    @JsonKey(name: 'stock_notification')
    @Default(false)
    bool stockNotification,
    @JsonKey(name: 'inventory_notification_threshold')
    @Default(0)
    int inventoryNotificationThreshold,
    @JsonKey(name: 'enable_product_discount')
    @Default(false)
    bool enableProductDiscount,
    @JsonKey(name: 'enable_product_cost')
    @Default(false)
    bool enableProductCost,
    @JsonKey(name: 'enable_product_quantity')
    @Default(false)
    bool enableProductQuantity,
    @JsonKey(name: 'default_quantity') @Default(false) bool defaultQuantity,
    @JsonKey(name: 'show_product_details')
    @Default(false)
    bool showProductDetails,
    @JsonKey(name: 'fill_products') @Default(false) bool fillProducts,
    @JsonKey(name: 'update_products') @Default(false) bool updateProducts,
    @JsonKey(name: 'convert_products') @Default(false) bool convertProducts,
    @JsonKey(name: 'convert_rate_to_client')
    @Default(false)
    bool convertRateToClient,
    // Top-level workflow configuration on the envelope, mirroring `CompanyApi`.
    // Settings → Workflow Settings edits these via `host.updateCompany(...)`;
    // the login envelope persists them straight into the `companies` Drift
    // table so the page reads correct values offline before the first refresh.
    @JsonKey(name: 'stop_on_unpaid_recurring')
    @Default(false)
    bool stopOnUnpaidRecurring,
    @JsonKey(name: 'use_quote_terms_on_conversion')
    @Default(false)
    bool useQuoteTermsOnConversion,
  }) = _CompanyEnvelopeApi;

  factory CompanyEnvelopeApi.fromJson(Map<String, dynamic> json) =>
      _$CompanyEnvelopeApiFromJson(json);
}

@freezed
abstract class TokenApi with _$TokenApi {
  const factory TokenApi({
    @Default('') String token,
    @Default('') String name,
  }) = _TokenApi;

  factory TokenApi.fromJson(Map<String, dynamic> json) =>
      _$TokenApiFromJson(json);
}

@freezed
abstract class AccountEnvelopeApi with _$AccountEnvelopeApi {
  const factory AccountEnvelopeApi({
    @Default('') String id,
    @JsonKey(name: 'default_company_id') @Default('') String defaultCompanyId,
    @Default('') String plan,
    @JsonKey(name: 'num_trial_days') @Default(0) int numTrialDays,
    @JsonKey(name: 'hosted_client_count') @Default(0) int hostedClientCount,
    @JsonKey(name: 'hosted_company_count') @Default(0) int hostedCompanyCount,
  }) = _AccountEnvelopeApi;

  factory AccountEnvelopeApi.fromJson(Map<String, dynamic> json) =>
      _$AccountEnvelopeApiFromJson(json);
}
