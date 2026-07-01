import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_service.dart';

/// The real auth backend, backed by FirebaseAuth. Selected in bootstrap when
/// Firebase is configured. Email/password, sign-out, deletion, and the auth
/// stream are wired; Apple/Google need their own packages + platform setup and
/// are left as clearly-marked seams.
class FirebaseAuthService implements AuthService {
  final _auth = fb.FirebaseAuth.instance;

  AuthUser? _map(fb.User? u) =>
      u == null ? null : AuthUser(uid: u.uid, email: u.email);

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.sendEmailVerification();
  }

  @override
  Future<void> signInWithApple() async {
    // Requires the "Sign in with Apple" capability (Xcode) and the provider
    // enabled in the Firebase console.
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final credential = fb.OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      accessToken: apple.authorizationCode,
    );
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signInWithGoogle() async {
    // Requires the Google OAuth client set up (google-services.json /
    // GoogleService-Info.plist from flutterfire configure).
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async => _auth.currentUser?.delete();
}
