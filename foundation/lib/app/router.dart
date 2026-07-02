import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/notes/notes_screen.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/auth/sign_in_screen.dart';
import '../modules/auth/sign_up_screen.dart';
import '../modules/onboarding/onboarding_controller.dart';
import '../modules/onboarding/onboarding_screen.dart';
import '../modules/paywall/paywall_screen.dart';
import '../modules/settings/account_screen.dart';
import '../modules/settings/legal_screen.dart';
import '../modules/settings/settings_screen.dart';
import '../modules/shell/tab_shell.dart';
import '../modules/telemetry/analytics.dart';
import '../modules/telemetry/screen_observer.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// The app router. Redirects on auth state, hosts the tab shell, and presents
/// auth / paywall / account / legal as root-level routes over the shell.
final routerProvider = Provider<GoRouter>((ref) {
  // Rebuild the router's redirect whenever auth state changes.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.listen(onboardingCompleteProvider, (_, __) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    // Screen views for root-level routes; tab views are logged by TabShell.
    observers: [AnalyticsScreenObserver(ref.read(analyticsProvider))],
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authControllerProvider) != AuthState.signedOut;
      final onboarded = ref.read(onboardingCompleteProvider);
      final loc = state.matchedLocation;
      final authRoute = loc == '/signin' || loc == '/signup';
      final onboardingRoute = loc == '/onboarding';

      // Order: sign in -> onboarding -> app.
      if (!loggedIn) return authRoute ? null : '/signin';
      if (!onboarded) return onboardingRoute ? null : '/onboarding';
      if (authRoute || onboardingRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/signin',
        name: 'signin',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AccountScreen(),
      ),
      // NTS-01, the CRUD reference feature (foundation only, not stamped).
      GoRoute(
        path: '/notes',
        name: 'notes',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const NotesScreen(),
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            PaywallScreen(source: state.uri.queryParameters['source']),
      ),
      GoRoute(
        path: '/legal/:kind',
        name: 'legal',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            LegalScreen(kind: state.pathParameters['kind'] ?? 'privacy'),
      ),
    ],
  );
});
