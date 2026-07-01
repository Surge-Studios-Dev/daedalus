import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/feature_registry.dart';
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
import 'nav_config.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// The app router. Redirects on auth state, builds one tab branch per entry in
/// [navTabs] (generated from the manifest), and presents auth / paywall /
/// account / legal as root-level routes over the shell. Builtin tabs render the
/// settings stack; feature tabs render their generated screen.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.listen(onboardingCompleteProvider, (_, __) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/${navTabs.first.id}',
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
      if (authRoute || onboardingRoute) return '/${navTabs.first.id}';
      return null;
    },
    routes: [
      GoRoute(
        path: '/signin',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabShell(navigationShell: navigationShell),
        branches: [
          for (final tab in navTabs)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/${tab.id}',
                  builder: (context, state) => tab.builtin
                      ? const SettingsScreen()
                      : featureBuilders[tab.id]!(context),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: '/account',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/paywall',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            PaywallScreen(source: state.uri.queryParameters['source']),
      ),
      GoRoute(
        path: '/legal/:kind',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            LegalScreen(kind: state.pathParameters['kind'] ?? 'privacy'),
      ),
    ],
  );
});
