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
    return Scaffold(
      body: navigationShell,
      // Content scrolls beneath the floating bar (soft_depth chrome).
      extendBody: true,
      bottomNavigationBar: SurgeFloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelected: (index) {
          if (index != navigationShell.currentIndex) {
            ref.read(analyticsProvider).screen(navTabs[index].id);
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: [
          for (final tab in navTabs)
            SurgeNavItem(icon: tab.icon, label: tab.label),
        ],
      ),
    );
  }
}
