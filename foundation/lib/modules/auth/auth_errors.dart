import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// Auth failures -> honest copy (spec §4.5: state what happened + the
/// next step; never apologize, never blame). The mock never threw, so
/// the stamped screens had no error path - real FirebaseAuth does throw,
/// and an uncaught native config error (Google's GIDSignIn) aborts the
/// whole app. Every sign-in action routes its catch through here.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'Email or password didn\'t match. Try again.',
      'invalid-email' => 'That email doesn\'t look right.',
      'email-already-in-use' =>
        'That email already has an account. Sign in instead.',
      'weak-password' => 'Password needs at least 6 characters.',
      'too-many-requests' => 'Too many tries. Wait a minute, then try again.',
      'network-request-failed' =>
        'You\'re offline. We\'ll be here when you\'re back.',
      _ => 'Sign-in failed (${error.code}). Try again.',
    };
  }
  if (error is MissingPluginException || error is PlatformException) {
    // Unprovisioned providers (Google/Apple before their OAuth config
    // lands) surface as platform errors - name the state, don't crash.
    return 'That sign-in method isn\'t set up yet. Use email for now.';
  }
  return 'Sign-in failed. Try again.';
}
