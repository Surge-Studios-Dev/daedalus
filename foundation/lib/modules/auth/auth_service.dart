import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The minimal user identity the app needs. Backend-agnostic.
class AuthUser {
  const AuthUser({required this.uid, this.email});

  final String uid;
  final String? email;
}

/// The auth boundary the app depends on. The rest of the app talks to this, not
/// to Firebase directly, so the backend is a swappable implementation:
/// [MockAuthService] for dev/tests, `FirebaseAuthService` in a configured build.
abstract interface class AuthService {
  /// Emits on sign-in / sign-out. null means signed out.
  Stream<AuthUser?> authStateChanges();

  /// The current user, or null. Read synchronously at startup.
  AuthUser? get currentUser;

  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);
  Future<void> signInWithApple();
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> deleteAccount();
}

/// In-memory auth for development and tests: every sign-in "succeeds" with a
/// fake user. The default binding until Firebase is configured (see bootstrap).
class MockAuthService implements AuthService {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  void _set(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<void> signInWithEmail(String email, String password) async =>
      _set(AuthUser(uid: 'mock-user', email: email));

  @override
  Future<void> signUpWithEmail(String email, String password) async =>
      _set(AuthUser(uid: 'mock-user', email: email));

  @override
  Future<void> signInWithApple() async =>
      _set(const AuthUser(uid: 'mock-apple', email: 'you@privaterelay.appleid.com'));

  @override
  Future<void> signInWithGoogle() async =>
      _set(const AuthUser(uid: 'mock-google', email: 'you@gmail.com'));

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<void> deleteAccount() async => _set(null);

  void dispose() => _controller.close();
}

/// The active auth backend. Defaults to the mock; bootstrap overrides it with a
/// FirebaseAuthService once Firebase is configured. Nothing else in the app
/// changes when the binding is swapped.
final authServiceProvider = Provider<AuthService>((ref) {
  final service = MockAuthService();
  ref.onDispose(service.dispose);
  return service;
});
