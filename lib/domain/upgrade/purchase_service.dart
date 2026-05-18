import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/api_client.dart';

/// App Store / Play product identifiers for the hosted plans. Mirrors
/// admin-portal's `kProductPlans` (legacy `lib/constants.dart`). The server
/// maps the productID back to a plan slug (`-` → `_`).
const String kProductProPlanMonth = 'pro_plan';
const String kProductProPlanYear = 'pro_plan_annual';
const String kProductEnterprisePlanMonth = 'enterprise_plan';
const String kProductEnterprisePlanMonth5 = 'enterprise_plan_5';
const String kProductEnterprisePlanMonth10 = 'enterprise_plan_10';
const String kProductEnterprisePlanMonth20 = 'enterprise_plan_20';
const String kProductEnterprisePlanYear = 'enterprise_plan_annual';
const String kProductEnterprisePlanYear5 = 'enterprise_plan_annual_5';
const String kProductEnterprisePlanYear10 = 'enterprise_plan_annual_10';
const String kProductEnterprisePlanYear20 = 'enterprise_plan_annual_20';

const Set<String> kProductPlans = {
  kProductProPlanMonth,
  kProductProPlanYear,
  kProductEnterprisePlanMonth,
  kProductEnterprisePlanMonth5,
  kProductEnterprisePlanMonth10,
  kProductEnterprisePlanMonth20,
  kProductEnterprisePlanYear,
  kProductEnterprisePlanYear5,
  kProductEnterprisePlanYear10,
  kProductEnterprisePlanYear20,
};

/// Drives the App Store / Play in-app-purchase flow for hosted plan
/// upgrades. Lifecycle is owned by the upgrade sheet (created on open,
/// disposed on close) so we don't hold a global purchase-stream subscription.
///
/// Port of admin-portal's `UpgradeDialog` purchase plumbing: query products,
/// `buyNonConsumable`, listen to `purchaseStream`, POST the receipt to
/// `/api/admin/subscription`, then `auth.refresh()` so the new plan lands in
/// the session (and every `PlanGateBanner` auto-clears).
///
/// NOTE: requires App Store Connect / Play Console product configuration
/// (the `kProductPlans` IDs) and sandbox testing — that store-side setup is
/// outside the Flutter codebase and cannot be exercised in CI.
class PurchaseService {
  PurchaseService({required ApiClient apiClient, required AuthRepository auth})
    : _apiClient = apiClient,
      _auth = auth;

  final ApiClient _apiClient;
  final AuthRepository _auth;
  final InAppPurchase _iap = InAppPurchase.instance;
  final _log = Logger('PurchaseService');

  StreamSubscription<List<PurchaseDetails>>? _sub;
  final ValueNotifier<List<ProductDetails>> products = ValueNotifier(const []);
  final ValueNotifier<bool> busy = ValueNotifier(false);

  /// True only on store platforms with a reachable billing backend.
  Future<bool> get isAvailable => _iap.isAvailable();

  Future<void> init() async {
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) => _log.warning('purchaseStream error: $e'),
    );
    await _queryProducts();
  }

  Future<void> _queryProducts() async {
    busy.value = true;
    try {
      final resp = await _iap.queryProductDetails(kProductPlans);
      if (resp.error != null) {
        _log.warning('queryProductDetails: ${resp.error}');
      }
      products.value = resp.productDetails;
    } finally {
      busy.value = false;
    }
  }

  Future<void> buy(ProductDetails product) async {
    busy.value = true;
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.status == PurchaseStatus.pending) {
        busy.value = true;
        continue;
      }
      if (p.status == PurchaseStatus.error) {
        busy.value = false;
        _log.warning('purchase error: ${p.error}');
      } else if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await _deliver(p);
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  /// POST the receipt to the hosted admin endpoint, then refresh the session
  /// so the upgraded plan (and the cleared gates) take effect.
  Future<void> _deliver(PurchaseDetails p) async {
    busy.value = true;
    try {
      var purchaseId = p.purchaseID;
      if (p is AppStorePurchaseDetails) {
        final original = p.skPaymentTransaction.originalTransaction;
        if (original != null) purchaseId = original.transactionIdentifier;
      }
      await _apiClient.postJson(
        '/api/admin/subscription',
        body: {
          'inapp_transaction_id': purchaseId,
          'key': _auth.session.value?.accountId ?? '',
          'plan': p.productID.replaceAll('-', '_'),
        },
      );
      // Full session snapshot — flips the plan slug everywhere.
      await _auth.refresh();
    } catch (e) {
      _log.warning('subscription deliver failed: $e');
    } finally {
      busy.value = false;
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    products.dispose();
    busy.dispose();
  }
}
