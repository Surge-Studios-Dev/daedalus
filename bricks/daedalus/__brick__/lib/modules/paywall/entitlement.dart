import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Single source of truth for paid access. The RevenueCat entitlement id is
/// `{{entitlement}}`. It is granted identically whether by a subscription or a
/// one-time unlock, so ALL gating goes through [hasPro]. Monetization-model
/// differences live only in the paywall and in TrialWindow, never here.
///
/// VERIFY: confirm these calls against your installed purchases_flutter version.
class Entitlement {
  static const id = '{{entitlement}}';

  static Future<bool> hasPro() async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(id);
  }

  /// Emits whenever entitlement state changes (purchase, restore, expiry).
  static Stream<bool> changes() {
    final controller = StreamController<bool>.broadcast();
    void listener(CustomerInfo info) =>
        controller.add(info.entitlements.active.containsKey(id));
    Purchases.addCustomerInfoUpdateListener(listener);
    controller.onCancel =
        () => Purchases.removeCustomerInfoUpdateListener(listener);
    return controller.stream;
  }
}
