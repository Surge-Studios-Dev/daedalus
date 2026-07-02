import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The purchases boundary the app depends on. The rest of the app talks to this,
/// not to RevenueCat directly, so the store is a swappable implementation:
/// [MockPurchaseService] for dev/tests, `RevenueCatPurchaseService` in a
/// configured build. Model-agnostic: subscription vs one-time is a store
/// concern; the app only cares whether the single entitlement is unlocked.
abstract interface class PurchaseService {
  /// Emits whenever the entitlement's unlocked status changes.
  Stream<bool> entitlementChanges();

  /// Whether the paid entitlement is currently active.
  bool get isUnlocked;

  /// Present/complete a purchase of the default product.
  Future<void> purchase();

  /// Restore prior purchases (mandatory in every app).
  Future<void> restore();

  /// Bind purchases to the signed-in user (RevenueCat logIn/logOut); null on
  /// sign-out. Called by the auth controller at the SAME moment as
  /// [Analytics.identify]/reset, so revenue events share the user's distinct
  /// id and monetization funnels stay whole.
  Future<void> setUser(String? userId);
}

/// In-memory purchases for development and tests: [purchase] unlocks, [restore]
/// finds nothing. The default binding until RevenueCat is configured.
class MockPurchaseService implements PurchaseService {
  final _controller = StreamController<bool>.broadcast();
  bool _unlocked = false;

  @override
  bool get isUnlocked => _unlocked;

  @override
  Stream<bool> entitlementChanges() => _controller.stream;

  void _set(bool value) {
    if (_unlocked == value) return;
    _unlocked = value;
    _controller.add(value);
  }

  @override
  Future<void> purchase() async => _set(true);

  @override
  Future<void> restore() async {
    // Nothing to restore in the mock.
  }

  @override
  Future<void> setUser(String? userId) async {
    // The mock has no per-user account state.
  }

  void dispose() => _controller.close();
}

/// The active purchases backend. Defaults to the mock; bootstrap overrides it
/// with a RevenueCatPurchaseService once configured. Nothing else in the app
/// changes when the binding is swapped.
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = MockPurchaseService();
  ref.onDispose(service.dispose);
  return service;
});
