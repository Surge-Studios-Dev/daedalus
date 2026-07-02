import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surge_foundation/app/app.dart';
import 'package:surge_foundation/modules/auth/auth_controller.dart';
import 'package:surge_foundation/modules/auth/auth_service.dart';
import 'package:surge_foundation/modules/onboarding/onboarding_controller.dart';
import 'package:surge_foundation/modules/paywall/purchase_service.dart';
import 'package:surge_foundation/modules/rating/rating.dart';
import 'package:surge_foundation/modules/storage/key_value_store.dart';
import 'package:surge_foundation/modules/telemetry/analytics.dart';
import 'package:surge_rating/surge_rating.dart';

Future<void> _pump(WidgetTester tester, {List<Override> overrides = const []}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const SurgeApp()),
  );
  await tester.pumpAndSettle();
}

/// Most tests want to be past first-run onboarding.
final _seen = onboardingCompleteProvider.overrideWith(_SeenOnboarding.new);

void main() {
  testWidgets('signed-out app lands on the sign-in screen', (tester) async {
    await _pump(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('first run shows onboarding; finishing reveals home', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    // Onboarding is presented before the app.
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Your feature goes here'), findsNothing);

    // Skip completes it and routes into the shell.
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Your feature goes here'), findsOneWidget);
  });

  testWidgets('signing in reveals the home shell', (tester) async {
    await _pump(tester, overrides: [_seen]);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Your feature goes here'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('You tab shows the settings stack', (tester) async {
    await _pump(tester, overrides: [_seen]);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    // The legal group sits below the fold now; ListView builds lazily.
    await tester.scrollUntilVisible(find.text('Privacy policy'), 200);
    expect(find.text('Privacy policy'), findsOneWidget);
  });

  testWidgets('gate presents the paywall when locked', (tester) async {
    await _pump(tester, overrides: [_seen]);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.workspace_premium));
    await tester.pumpAndSettle();
    expect(find.text('Go Pro'), findsOneWidget);
  });

  testWidgets('persisted onboarding flag skips onboarding (no controller override)', (
    tester,
  ) async {
    // Only the key/value store is seeded — the onboarding controller reads it,
    // proving persistence drives the flow.
    await _pump(
      tester,
      overrides: [
        keyValueStoreProvider.overrideWithValue(
          InMemoryKeyValueStore({'onboarding_complete': true}),
        ),
      ],
    );
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsNothing); // onboarding skipped
    expect(find.text('Your feature goes here'), findsOneWidget);
  });

  testWidgets('swapping the AuthService backend drives the app (already signed in)', (
    tester,
  ) async {
    // No AuthController override here — only the backend is swapped, proving the
    // app boots signed-in purely from the service, and surfaces its email.
    await _pump(
      tester,
      overrides: [
        _seen,
        authServiceProvider.overrideWithValue(_FakeSignedInService()),
      ],
    );
    expect(find.text('Welcome back'), findsNothing); // skipped sign-in
    expect(find.text('Your feature goes here'), findsOneWidget);

    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('backend@example.com'), findsOneWidget);
  });

  testWidgets('swapping the PurchaseService (unlocked) lets the gate run', (
    tester,
  ) async {
    // Only the purchases backend is swapped — the gate/entitlement follow it.
    await _pump(
      tester,
      overrides: [
        _seen,
        authControllerProvider.overrideWith(_SignedInAuth.new),
        purchaseServiceProvider.overrideWithValue(_UnlockedPurchases()),
      ],
    );
    await tester.tap(find.byIcon(Icons.workspace_premium));
    await tester.pumpAndSettle();
    expect(find.text('Unlocked action ran.'), findsOneWidget);
    expect(find.text('Go Pro'), findsNothing);
  });

  testWidgets('notes CRUD reference: add and delete through the repository seam', (
    tester,
  ) async {
    await _pump(tester, overrides: [_seen]);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    // The reference feature is reachable from the blank home.
    await tester.tap(find.text('Notes (CRUD reference)'));
    await tester.pumpAndSettle();
    expect(find.text('No notes yet'), findsOneWidget);

    // Add flows through CrudRepository.upsert into the watchAll stream.
    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('No notes yet'), findsNothing);

    // Delete flows through CrudRepository.delete.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsNothing);
    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('rate-this-app row drives the RatingService seam', (
    tester,
  ) async {
    final rating = MockRatingService();
    await _pump(
      tester,
      overrides: [
        _seen,
        ratingServiceProvider.overrideWithValue(rating),
      ],
    );
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rate this app'));
    await tester.pumpAndSettle();
    expect(rating.reviewRequested, isTrue);
  });

  testWidgets('backend sign-in binds the analytics identity (Ladle law)', (
    tester,
  ) async {
    final analytics = _RecordingAnalytics();
    await _pump(
      tester,
      overrides: [
        _seen,
        authServiceProvider.overrideWithValue(_FakeSignedInService()),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    // The auth-state listener identified the already-signed-in backend user.
    expect(analytics.identified, contains('backend'));
    expect(analytics.wasReset, isFalse);
  });

  testWidgets('settings exposes the analytics opt-out and it persists', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore({'onboarding_complete': true});
    await _pump(
      tester,
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();

    expect(find.text('Share analytics'), findsOneWidget);
    await tester.tap(find.text('Share analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Off'), findsOneWidget);
    expect(store.getBool('analytics_enabled'), isFalse);
  });

  testWidgets('purchasing on the paywall unlocks the gated action', (
    tester,
  ) async {
    await _pump(tester, overrides: [_seen]);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    // Locked: the gate presents the paywall.
    await tester.tap(find.byIcon(Icons.workspace_premium));
    await tester.pumpAndSettle();
    expect(find.text('Go Pro'), findsOneWidget);

    // Buy (mock purchase unlocks the entitlement) -> paywall closes.
    await tester.tap(find.text('Start 7-day free trial'));
    await tester.pumpAndSettle();
    expect(find.text('Go Pro'), findsNothing);

    // Now the same gate runs its action instead of gating.
    await tester.tap(find.byIcon(Icons.workspace_premium));
    await tester.pumpAndSettle();
    expect(find.text('Unlocked action ran.'), findsOneWidget);
  });
}

class _SignedInAuth extends AuthController {
  @override
  AuthState build() => AuthState.signedIn;
}

/// A purchases backend that reports the entitlement already unlocked.
class _UnlockedPurchases implements PurchaseService {
  @override
  bool get isUnlocked => true;
  @override
  Stream<bool> entitlementChanges() => const Stream.empty();
  @override
  Future<void> purchase() async {}
  @override
  Future<void> restore() async {}
  @override
  Future<void> setUser(String? userId) async {}
}

class _SeenOnboarding extends OnboardingController {
  @override
  bool build() => true;
}

/// Records identity calls so tests can pin the identify/reset contract.
class _RecordingAnalytics implements Analytics {
  final identified = <String>[];
  bool wasReset = false;

  @override
  void log(String event, [Map<String, Object?> params = const {}]) {}
  @override
  void screen(String name) {}
  @override
  void identify(String userId) => identified.add(userId);
  @override
  void reset() => wasReset = true;
}

/// A stand-in auth backend that reports an already-signed-in user, used to prove
/// the app follows whatever AuthService is bound without any controller changes.
class _FakeSignedInService implements AuthService {
  @override
  AuthUser? get currentUser =>
      const AuthUser(uid: 'backend', email: 'backend@example.com');

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(currentUser);

  @override
  Future<void> signInWithEmail(String email, String password) async {}
  @override
  Future<void> signUpWithEmail(String email, String password) async {}
  @override
  Future<void> signInWithApple() async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
}
