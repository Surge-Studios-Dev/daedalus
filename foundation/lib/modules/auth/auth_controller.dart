import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../paywall/purchase_service.dart';
import '../telemetry/analytics.dart';
import 'auth_service.dart';

/// Coarse auth state the router redirects on.
enum AuthState { signedOut, guest, signedIn }

/// Auth state + actions. Delegates to the injected [AuthService], so it is
/// identical whether that service is the mock or Firebase. Guest is an app-level
/// concept (not an auth account), tracked here.
class AuthController extends Notifier<AuthState> {
  AuthService get _service => ref.read(authServiceProvider);
  Analytics get _analytics => ref.read(analyticsProvider);

  @override
  AuthState build() {
    final service = ref.watch(authServiceProvider);
    // Keep state in sync with the backend (already-signed-in on launch, or a
    // token revoked out from under us). Never knock a guest back to signedOut.
    final sub = service.authStateChanges().listen((user) {
      if (user != null) {
        state = AuthState.signedIn;
        _bindIdentity(user.uid);
      } else if (state != AuthState.guest) {
        state = AuthState.signedOut;
      }
    });
    ref.onDispose(sub.cancel);
    return service.currentUser != null
        ? AuthState.signedIn
        : AuthState.signedOut;
  }

  /// The Ladle law: analytics identity and the purchases account bind
  /// together, in this order, in exactly one place - otherwise subscription
  /// events land on a different distinct id and monetization funnels
  /// fracture. Guests stay anonymous (no identify until an account exists).
  void _bindIdentity(String uid) {
    _analytics.identify(uid);
    unawaited(ref.read(purchaseServiceProvider).setUser(uid));
  }

  void _bindCurrent() {
    final uid = _service.currentUser?.uid;
    if (uid != null) _bindIdentity(uid);
  }

  void _clearIdentity() {
    _analytics.reset();
    unawaited(ref.read(purchaseServiceProvider).setUser(null));
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _service.signInWithEmail(email, password);
    state = AuthState.signedIn;
    _bindCurrent();
    _analytics.log(Ev.login, {'method': 'email'});
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _service.signUpWithEmail(email, password);
    state = AuthState.signedIn;
    _bindCurrent();
    _analytics.log(Ev.signUp, {'method': 'email'});
  }

  Future<void> signInWithApple() async {
    await _service.signInWithApple();
    state = AuthState.signedIn;
    _bindCurrent();
    _analytics.log(Ev.login, {'method': 'apple'});
  }

  Future<void> signInWithGoogle() async {
    await _service.signInWithGoogle();
    state = AuthState.signedIn;
    _bindCurrent();
    _analytics.log(Ev.login, {'method': 'google'});
  }

  void continueAsGuest() {
    state = AuthState.guest;
    _analytics.log(Ev.login, {'method': 'guest'});
  }

  Future<void> signOut() async {
    await _service.signOut();
    _clearIdentity();
    state = AuthState.signedOut;
  }

  Future<void> deleteAccount() async {
    await _service.deleteAccount();
    _clearIdentity();
    state = AuthState.signedOut;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// The signed-in user's email (null for guests / signed out).
final userEmailProvider = Provider<String?>((ref) {
  ref.watch(authControllerProvider); // rebuild when auth changes
  return ref.watch(authServiceProvider).currentUser?.email;
});

/// The signed-in user's uid (null for guests / signed out). Per-user data
/// paths (`users/{uid}/...`, matching firestore.rules) key off this.
final userUidProvider = Provider<String?>((ref) {
  ref.watch(authControllerProvider); // rebuild when auth changes
  return ref.watch(authServiceProvider).currentUser?.uid;
});
