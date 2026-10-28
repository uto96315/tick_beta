import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tick/services/gateways.dart';

/// Non-consumable App Store product. Entitlement is also copied to Firestore
/// so a signed-in reinstall can restore it before the StoreKit receipt is read.
class StorePurchaseGateway implements PurchaseGateway {
  static const productId = 'tick_premium';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  void Function()? _onPurchased;

  @override
  Future<void> init({required void Function() onPurchased}) async {
    _onPurchased = onPurchased;
    _subscription = _iap.purchaseStream.listen(
      _onEvents,
      onError: (Object error) => debugPrint('purchase stream failed: $error'),
    );
    try {
      if (await _iap.isAvailable()) {
        await _iap.restorePurchases();
      }
    } catch (error) {
      debugPrint('purchase restore skipped: $error');
    }
  }

  Future<void> _onEvents(List<PurchaseDetails> events) async {
    for (final event in events) {
      if (event.productID != productId) continue;
      final owned =
          event.status == PurchaseStatus.purchased || event.status == PurchaseStatus.restored;
      if (owned) _onPurchased?.call();
      if (event.pendingCompletePurchase) {
        await _iap.completePurchase(event);
      }
    }
  }

  @override
  Future<String?> priceLabel() async {
    if (!await _iap.isAvailable()) return null;
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) return null;
    return response.productDetails.first.price;
  }

  @override
  Future<void> buy() async {
    if (!await _iap.isAvailable()) throw AuthFlowException('purchase-unavailable');
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) throw AuthFlowException('purchase-unavailable');
    final started = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: response.productDetails.first),
    );
    if (!started) throw AuthFlowException('purchase-unavailable');
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  Future<void> dispose() => _subscription?.cancel() ?? Future<void>.value();
}
