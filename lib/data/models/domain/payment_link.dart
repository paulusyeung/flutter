import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/subscription_api_model.dart';
import 'package:admin/data/models/value/money.dart';
import 'package:admin/data/models/value/parsing.dart';
import 'package:admin/domain/recurring_frequency.dart';

part 'payment_link.freezed.dart';

/// Clean domain model for a Payment Link row. Edited via Settings →
/// Advanced → Payment Links.
///
/// Wire-side this is called `subscription` (DTO class is [SubscriptionApi]);
/// internally we use `PaymentLink` to match the user-facing label.
///
/// Numeric money fields use [Decimal] (per CLAUDE.md strict rule). The
/// payload's `plan_map` is internal and not exposed in the UI — it's kept
/// here so round-tripping via the Drift payload blob doesn't drop the
/// field. `isDirty` is overlaid by the repository in `_fromRow`; the
/// `fromApi` factory defaults it to `false`.
@freezed
abstract class PaymentLink with _$PaymentLink {
  const factory PaymentLink({
    required String id,
    required String userId,
    required String assignedUserId,
    required String companyId,
    required String name,
    required Decimal price,
    required String currencyId,
    required String frequencyId,
    required String productIds,
    required String recurringProductIds,
    required String optionalProductIds,
    required String optionalRecurringProductIds,
    required String groupId,
    required String autoBill,
    required int remainingCycles,
    required int refundPeriod,
    required bool trialEnabled,
    required int trialDuration,
    required String promoCode,
    required Decimal promoDiscount,
    required Decimal promoPrice,
    required bool isAmountDiscount,
    required bool allowCancellation,
    required bool allowPlanChanges,
    required bool allowQueryOverrides,
    required bool registrationRequired,
    required bool useInventoryManagement,
    required bool perSeatEnabled,
    required int maxSeatsLimit,
    required PaymentLinkWebhook webhookConfiguration,
    required String steps,
    required String purchasePage,
    required String planMap,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    required bool isDeleted,
    @Default(false) bool isDirty,
  }) = _PaymentLink;

  factory PaymentLink.fromApi(SubscriptionApi a) => PaymentLink(
    id: a.id,
    userId: a.userId,
    assignedUserId: a.assignedUserId,
    companyId: a.companyId,
    name: a.name,
    price: parseMoney(a.price),
    currencyId: a.currencyId,
    frequencyId: a.frequencyId,
    productIds: a.productIds,
    recurringProductIds: a.recurringProductIds,
    optionalProductIds: a.optionalProductIds,
    optionalRecurringProductIds: a.optionalRecurringProductIds,
    groupId: a.groupId,
    autoBill: a.autoBill,
    remainingCycles: a.remainingCycles,
    refundPeriod: a.refundPeriod,
    trialEnabled: a.trialEnabled,
    trialDuration: a.trialDuration,
    promoCode: a.promoCode,
    promoDiscount: parseMoney(a.promoDiscount),
    promoPrice: parseMoney(a.promoPrice),
    isAmountDiscount: a.isAmountDiscount,
    allowCancellation: a.allowCancellation,
    allowPlanChanges: a.allowPlanChanges,
    allowQueryOverrides: a.allowQueryOverrides,
    registrationRequired: a.registrationRequired,
    useInventoryManagement: a.useInventoryManagement,
    perSeatEnabled: a.perSeatEnabled,
    maxSeatsLimit: a.maxSeatsLimit,
    webhookConfiguration: PaymentLinkWebhook.fromApi(a.webhookConfiguration),
    steps: a.steps,
    purchasePage: a.purchasePage,
    planMap: a.planMap,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
    isDeleted: a.isDeleted,
  );
}

/// Nested webhook configuration. Mirrors [WebhookConfigurationApi] but
/// uses a non-nullable `Map<String,String>` so headers always have a
/// stable iteration order in the UI.
@freezed
abstract class PaymentLinkWebhook with _$PaymentLinkWebhook {
  const factory PaymentLinkWebhook({
    required String returnUrl,
    required String postPurchaseUrl,
    required String postPurchaseRestMethod,
    required Map<String, String> postPurchaseHeaders,
    required String postPurchaseBody,
  }) = _PaymentLinkWebhook;

  factory PaymentLinkWebhook.empty() => const PaymentLinkWebhook(
    returnUrl: '',
    postPurchaseUrl: '',
    postPurchaseRestMethod: '',
    postPurchaseHeaders: <String, String>{},
    postPurchaseBody: '',
  );

  factory PaymentLinkWebhook.fromApi(WebhookConfigurationApi a) =>
      PaymentLinkWebhook(
        returnUrl: a.returnUrl,
        postPurchaseUrl: a.postPurchaseUrl,
        postPurchaseRestMethod: a.postPurchaseRestMethod,
        postPurchaseHeaders: Map.unmodifiable(a.postPurchaseHeaders),
        postPurchaseBody: a.postPurchaseBody,
      );
}

/// Step entry returned by `GET /api/v1/subscriptions/steps`. Used by the
/// Steps tab to populate the dropdown options and compute per-row
/// dependency markers without a server round-trip.
class PaymentLinkStep {
  const PaymentLinkStep({
    required this.id,
    required this.label,
    required this.dependencies,
  });

  final String id;
  final String label;
  final List<String> dependencies;

  factory PaymentLinkStep.fromApi(SubscriptionStepApi a) => PaymentLinkStep(
    id: a.id,
    label: a.label,
    dependencies: List.unmodifiable(a.dependencies),
  );
}

extension PaymentLinkPayload on PaymentLink {
  /// Outbox payload (when `preserveTempId == false`) and local-Drift
  /// round-trip payload (when `preserveTempId == true`).
  ///
  /// The outbox path drops `tmp_<uuid>` from `id` and omits the
  /// server-managed identity / timestamp fields (the server treats them
  /// as readonly). The Drift-roundtrip path keeps both so an offline
  /// save → app restart → reload doesn't reset `createdAt` to epoch.
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    return <String, dynamic>{
      if (preserveTempId || !id.startsWith('tmp_')) 'id': id,
      'name': name,
      'price': price.toString(),
      'currency_id': currencyId,
      'frequency_id': frequencyId,
      'product_ids': productIds,
      'recurring_product_ids': recurringProductIds,
      'optional_product_ids': optionalProductIds,
      'optional_recurring_product_ids': optionalRecurringProductIds,
      'group_id': groupId,
      'assigned_user_id': assignedUserId,
      'auto_bill': autoBill,
      'remaining_cycles': remainingCycles,
      'refund_period': refundPeriod,
      'trial_enabled': trialEnabled,
      'trial_duration': trialDuration,
      'promo_code': promoCode,
      'promo_discount': promoDiscount.toString(),
      'promo_price': promoPrice.toString(),
      'is_amount_discount': isAmountDiscount,
      'allow_cancellation': allowCancellation,
      'allow_plan_changes': allowPlanChanges,
      'allow_query_overrides': allowQueryOverrides,
      'registration_required': registrationRequired,
      'use_inventory_management': useInventoryManagement,
      'per_seat_enabled': perSeatEnabled,
      'max_seats_limit': maxSeatsLimit,
      'webhook_configuration': <String, dynamic>{
        'return_url': webhookConfiguration.returnUrl,
        'post_purchase_url': webhookConfiguration.postPurchaseUrl,
        'post_purchase_rest_method':
            webhookConfiguration.postPurchaseRestMethod,
        'post_purchase_headers': webhookConfiguration.postPurchaseHeaders,
        'post_purchase_body': webhookConfiguration.postPurchaseBody,
      },
      'steps': steps,
      'plan_map': planMap,
      if (preserveTempId) ...{
        'user_id': userId,
        'company_id': companyId,
        'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
        'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
        'archived_at': archivedAt == null
            ? 0
            : archivedAt!.millisecondsSinceEpoch ~/ 1000,
        'is_deleted': isDeleted,
      },
    };
  }
}

/// Factory for an empty draft used on the Create form. Defaults mirror
/// admin-portal `subscription_model.dart` so a brand-new payment link
/// matches the legacy behavior end-to-end.
PaymentLink emptyPaymentLink() => PaymentLink(
  id: '',
  userId: '',
  assignedUserId: '',
  companyId: '',
  name: '',
  price: Decimal.zero,
  currencyId: '',
  frequencyId: kRecurringFrequencyMonthly,
  productIds: '',
  recurringProductIds: '',
  optionalProductIds: '',
  optionalRecurringProductIds: '',
  groupId: '',
  autoBill: '',
  remainingCycles: -1,
  refundPeriod: 0,
  trialEnabled: false,
  trialDuration: 0,
  promoCode: '',
  promoDiscount: Decimal.zero,
  promoPrice: Decimal.zero,
  isAmountDiscount: false,
  allowCancellation: false,
  allowPlanChanges: false,
  allowQueryOverrides: false,
  registrationRequired: false,
  useInventoryManagement: false,
  perSeatEnabled: false,
  maxSeatsLimit: 0,
  webhookConfiguration: PaymentLinkWebhook.empty(),
  steps: 'cart,auth.login-or-register',
  purchasePage: '',
  planMap: '',
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
);
