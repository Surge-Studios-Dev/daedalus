import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';

import 'purchase_service.dart';

/// The real purchases backend, backed by RevenueCat. Selected in bootstrap
/// after `Purchases.configure(...)`. Reads the single entitlement off
/// CustomerInfo, buys the current offering's default package, and restores.
class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService(this.entitlementId);

  /// The single RevenueCat entitlement id that unlocks paid value.
  final String entitlementId;

  final _controller = StreamController<bool>.broadcast();
  bool _unlocked = false;

  /// Begin listening for entitlement changes and seed the initial value. Call
  /// once after Purchases.configure.
  Future<void> start() async {
    Purchases.addCustomerInfoUpdateListener(_apply);
    try {
      _apply(await Purchases.getCustomerInfo());
    } catch (_) {
      // Offline or not yet configured: stay locked until the first update.
    }
  }

  void _apply(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(entitlementId);
    if (active != _unlocked) {
      _unlocked = active;
      _controller.add(active);
    }
  }

  @override
  bool get isUnlocked => _unlocked;

  @override
  Stream<bool> entitlementChanges() => _controller.stream;

  @override
  Future<void> purchase() async {
    final offerings = await Purchases.getOfferings();
    final package = offerings.current?.availablePackages.firstOrNull;
    if (package != null) {
      await Purchases.purchasePackage(package);
    }
    // The customer-info listener flips the entitlement.
  }

  @override
  Future<void> restore() async {
    await Purchases.restorePurchases();
  }

  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_apply);
    _controller.close();
  }
}
