import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:surge_ui/surge_ui.dart';

/// The signed-in shell: an indexed-stack of tab branches with a bottom bar.
/// Tapping the active tab pops that branch to its root (spec convention).
///
/// SEAM: the tab set is generated from `navigation.tabs` in the manifest; this
/// is the default Home + You layout.
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
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
