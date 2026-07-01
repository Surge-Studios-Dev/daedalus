import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:surge_ui/surge_ui.dart';

import '../../app/nav_config.dart';

/// The signed-in shell: an indexed-stack of tab branches with a bottom bar,
/// built from [navTabs] (generated from the manifest). Tapping the active tab
/// pops that branch to its root.
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
        destinations: [
          for (final tab in navTabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
