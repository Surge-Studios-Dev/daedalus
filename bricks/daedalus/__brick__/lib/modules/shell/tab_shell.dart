import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:surge_ui/surge_ui.dart';

import '../../app/nav_config.dart';
import '../telemetry/analytics.dart';

/// The signed-in shell: an indexed-stack of tab branches with a bottom bar,
/// built from [navTabs] (generated from the manifest). Tapping the active tab
/// pops that branch to its root. Tab switches log a screen view here - the
/// root navigator observer cannot see branch switches (IndexedStack swaps,
/// not pushes).
class TabShell extends ConsumerWidget {
  const TabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (index != navigationShell.currentIndex) {
            ref.read(analyticsProvider).screen(navTabs[index].id);
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
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
