import 'package:firebase_auth/firebase_auth.dart';

/// Auth surface for {{name}}. Providers enabled: email={{auth_email}},
/// apple={{auth_apple}}, google={{auth_google}}, guest={{guest_mode}}.
///
/// SKELETON: method shapes are correct; fill provider wiring and verify against
/// your installed firebase_auth / sign_in_with_apple / google_sign_in versions.
/// On success, call Telemetry.signUp/login with the method name.
class AuthController {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get current => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> registerWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

{{#auth_apple}}  Future<void> signInWithApple() async {/* TODO sign_in_with_apple -> OAuthProvider */}
{{/auth_apple}}{{#auth_google}}  Future<void> signInWithGoogle() async {/* TODO google_sign_in -> credential */}
{{/auth_google}}{{#guest_mode}}  Future<void> continueAsGuest() => _auth.signInAnonymously();
{{/guest_mode}}
  Future<void> signOut() => _auth.signOut();

  /// Account deletion is mandatory (Apple 5.1.1(v)). Deletes the auth user;
  /// also delete the user's Firestore documents in a Function for completeness.
  Future<void> deleteAccount() async => _auth.currentUser?.delete();
}
