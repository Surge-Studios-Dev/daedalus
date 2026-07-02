import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:surge_ui/surge_ui.dart';

import '../telemetry/analytics.dart';

/// The signed-in shell: an indexed-stack of tab branches with a bottom bar.
/// Tapping the active tab pops that branch to its root (spec convention).
/// Tab switches log a screen view here - the root navigator observer cannot
/// see branch switches (they are IndexedStack swaps, not pushes).
///
/// SEAM: the tab set is generated from `navigation.tabs` in the manifest; this
/// is the default Home + You layout.
class TabShell extends ConsumerWidget {
  const TabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabNames = ['home', 'settings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (index != navigationShell.currentIndex) {
            ref.read(analyticsProvider).screen(_tabNames[index]);
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: t.bgBase,
        indicatorColor: t.accentTint,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
