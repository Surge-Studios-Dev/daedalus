import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      } else if (state != AuthState.guest) {
        state = AuthState.signedOut;
      }
    });
    ref.onDispose(sub.cancel);
    return service.currentUser != null
        ? AuthState.signedIn
        : AuthState.signedOut;
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _service.signInWithEmail(email, password);
    state = AuthState.signedIn;
    _analytics.log(Ev.login, {'method': 'email'});
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _service.signUpWithEmail(email, password);
    state = AuthState.signedIn;
    _analytics.log(Ev.signUp, {'method': 'email'});
  }

  Future<void> signInWithApple() async {
    await _service.signInWithApple();
    state = AuthState.signedIn;
    _analytics.log(Ev.login, {'method': 'apple'});
  }

  Future<void> signInWithGoogle() async {
    await _service.signInWithGoogle();
    state = AuthState.signedIn;
    _analytics.log(Ev.login, {'method': 'google'});
  }

  void continueAsGuest() {
    state = AuthState.guest;
    _analytics.log(Ev.login, {'method': 'guest'});
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = AuthState.signedOut;
  }

  Future<void> deleteAccount() async {
    await _service.deleteAccount();
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
