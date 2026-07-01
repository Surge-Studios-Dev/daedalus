import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'purchase_service.dart';

/// Whether the single paid entitlement (default id `pro`) is unlocked. Derived
/// from the active [PurchaseService], so it reflects the mock in dev/tests and
/// real RevenueCat in a configured build without any change here or downstream.
/// `gate()` and the UI only read this bool.
class EntitlementController extends Notifier<bool> {
  @override
  bool build() {
    final service = ref.watch(purchaseServiceProvider);
    final sub = service.entitlementChanges().listen((v) => state = v);
    ref.onDispose(sub.cancel);
    return service.isUnlocked;
  }
}

final entitlementProvider = NotifierProvider<EntitlementController, bool>(
  EntitlementController.new,
);
