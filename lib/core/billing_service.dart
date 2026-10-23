// billing_service.dart (PRODUCTION SAFE)

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'subscription_guard.dart';

class BillingPlan {
  final String productId;
  final String basePlanId;
  final String offerToken;
  final ProductDetails productDetails;
  final String price;
  final String title;
  final String description;

  const BillingPlan({
    required this.productId,
    required this.basePlanId,
    required this.offerToken,
    required this.productDetails,
    required this.price,
    required this.title,
    required this.description,
  });
}

class BillingService {
  BillingService._internal();

  static final BillingService _instance = BillingService._internal();

  factory BillingService() => _instance;

  final InAppPurchase _iap = InAppPurchase.instance;

  static const String subscriptionId = 'musclemind_premium_monthly';

  static const String monthlyBasePlanId = 'monthly';
  static const String threeMonthsBasePlanId = '3months';
  static const String sixMonthsBasePlanId = '6months';
  static const String yearlyBasePlanId = 'yearly';

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  List<ProductDetails> products = [];
  List<BillingPlan> plans = [];

  bool isAvailable = false;
  bool isInitialized = false;
  bool purchasePending = false;

  Future<void> init() async {
    if (isInitialized) return;

    try {
      isAvailable = await _iap.isAvailable();

      if (!isAvailable) {
        await SubscriptionGuard.deactivatePremium();
        debugPrint('Billing not available. Premium locked.');
        isInitialized = true;
        return;
      }

      _listenToPurchases();

      await loadProducts();

      // Lock first, then unlock only if Google Play returns a valid purchase.
      await refreshSubscriptionStatus();

      isInitialized = true;

      debugPrint('Billing initialized');
    } catch (e) {
      purchasePending = false;
      await SubscriptionGuard.deactivatePremium();
      debugPrint('Billing init error: $e');
    }
  }

  Future<void> loadProducts() async {
    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails({subscriptionId});

      if (response.error != null) {
        debugPrint('Product query error: ${response.error}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Product IDs not found: ${response.notFoundIDs}');
      }

      products = response.productDetails;
      plans = _extractPlans(products);

      debugPrint('Loaded ${plans.length} billing plans');

      for (final plan in plans) {
        debugPrint(
          'Plan loaded: ${plan.basePlanId} | ${plan.price} | token=${plan.offerToken.isNotEmpty}',
        );
      }
    } catch (e) {
      products = [];
      plans = [];
      debugPrint('loadProducts error: $e');
    }
  }

  List<BillingPlan> _extractPlans(List<ProductDetails> list) {
    final List<BillingPlan> extracted = [];

    for (final ProductDetails product in list) {
      if (product.id != subscriptionId) continue;

      if (defaultTargetPlatform == TargetPlatform.android &&
          product is GooglePlayProductDetails) {
        final offers = product.productDetails.subscriptionOfferDetails;

        if (offers == null || offers.isEmpty) {
          debugPrint('No subscription offers found for ${product.id}');
          continue;
        }

        for (final offer in offers) {
  final pricingPhases = offer.pricingPhases;

  final String formattedPrice = pricingPhases.isNotEmpty
      ? pricingPhases.first.formattedPrice
      : product.price;

  extracted.add(
    BillingPlan(
      productId: product.id,
      basePlanId: offer.basePlanId,
      offerToken: offer.offerIdToken,
      productDetails: product,
      price: formattedPrice,
      title: product.title,
      description: product.description,
    ),
  );
}
      } else {
        extracted.add(
          BillingPlan(
            productId: product.id,
            basePlanId: subscriptionId,
            offerToken: '',
            productDetails: product,
            price: product.price,
            title: product.title,
            description: product.description,
          ),
        );
      }
    }

    return extracted;
  }

  BillingPlan? getPlanByBasePlanId(String basePlanId) {
    try {
      return plans.firstWhere((BillingPlan p) => p.basePlanId == basePlanId);
    } catch (_) {
      return null;
    }
  }

  bool get hasPlans => plans.isNotEmpty;

  void _listenToPurchases() {
    _purchaseSubscription?.cancel();

    _purchaseSubscription = _iap.purchaseStream.listen(
      (List<PurchaseDetails> purchases) async {
        bool hasValidSubscription = false;

        for (final PurchaseDetails purchase in purchases) {
          final bool valid = await _handlePurchase(purchase);

          if (valid) {
            hasValidSubscription = true;
          }
        }

        if (purchases.isNotEmpty && !hasValidSubscription) {
          await SubscriptionGuard.deactivatePremium();
          debugPrint('No valid active subscription found. Premium locked.');
        }
      },
      onError: (Object e) async {
        purchasePending = false;
        debugPrint('Purchase stream error: $e');
      },
    );
  }

  Future<bool> _handlePurchase(PurchaseDetails purchase) async {
    debugPrint(
      'Purchase update: ${purchase.productID} | ${purchase.status}',
    );

    bool validSubscription = false;

    switch (purchase.status) {
      case PurchaseStatus.pending:
        purchasePending = true;
        break;

      case PurchaseStatus.error:
        purchasePending = false;
        debugPrint('Purchase error: ${purchase.error}');
        break;

      case PurchaseStatus.canceled:
        purchasePending = false;
        await SubscriptionGuard.deactivatePremium();
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        purchasePending = false;

        validSubscription = await _verifyPurchase(purchase);

        if (validSubscription) {
          await SubscriptionGuard.activatePremium();
          debugPrint('Premium unlocked');
        } else {
          await SubscriptionGuard.deactivatePremium();
          debugPrint('Invalid or inactive purchase. Premium locked.');
        }
        break;
    }

    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
      } catch (e) {
        debugPrint('completePurchase error: $e');
      }
    }

    return validSubscription;
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    if (purchase.productID != subscriptionId) {
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.android &&
        purchase is GooglePlayPurchaseDetails) {
      final billingPurchase = purchase.billingClientPurchase;

      final String purchaseState =
          billingPurchase.purchaseState.name.toLowerCase();

      final bool isPurchased = purchaseState == 'purchased';

      if (!isPurchased) {
        debugPrint('Android purchase not active. State: $purchaseState');
        return false;
      }

      return true;
    }

    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  Future<void> buySubscriptionByBasePlanId(String basePlanId) async {
    if (!isAvailable || purchasePending) return;

    if (plans.isEmpty) {
      await loadProducts();
    }

    final BillingPlan? plan = getPlanByBasePlanId(basePlanId);

    if (plan == null) {
      debugPrint('Plan not found: $basePlanId');
      return;
    }

    purchasePending = true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android &&
          plan.productDetails is GooglePlayProductDetails) {
        final GooglePlayPurchaseParam param = GooglePlayPurchaseParam(
          productDetails: plan.productDetails,
          offerToken: plan.offerToken,
        );

        await _iap.buyNonConsumable(purchaseParam: param);
      } else {
        final PurchaseParam param = PurchaseParam(
          productDetails: plan.productDetails,
        );

        await _iap.buyNonConsumable(purchaseParam: param);
      }
    } catch (e) {
      purchasePending = false;
      debugPrint('Purchase error: $e');
    }
  }

  Future<void> restorePurchases() async {
    if (!isAvailable) {
      await SubscriptionGuard.deactivatePremium();
      return;
    }

    try {
      await SubscriptionGuard.deactivatePremium();

      await _iap.restorePurchases();

      debugPrint('Restore triggered');
    } catch (e) {
      purchasePending = false;
      debugPrint('restorePurchases error: $e');
    }
  }

  Future<void> refreshSubscriptionStatus() async {
    if (!isAvailable) {
      await SubscriptionGuard.deactivatePremium();
      return;
    }

    await restorePurchases();
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }
}