import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeFloatingNavBar
/// category: navigation
/// summary: A detached pill-shaped bottom tab bar that floats above content on a lifted panel.
/// whenToUse: The app shell's bottom navigation in personality packs that float their chrome (soft_depth). Pair with Scaffold(extendBody: true) so content scrolls beneath it.
/// tags: navigation, tabs, bottom bar, floating, pill, shell
class SurgeNavItem {
  const SurgeNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class SurgeFloatingNavBar extends StatelessWidget {
  const SurgeFloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<SurgeNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: t.bgSubtle,
          borderRadius: BorderRadius.circular(SurgeRadii.pill),
          border: Border.all(color: t.lineHairline),
          boxShadow: t.shadowLift,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavCell(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SurgeNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: t.motionFast,
              curve: t.curveStandard,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? t.accentTint : Colors.transparent,
                borderRadius: BorderRadius.circular(SurgeRadii.pill),
              ),
              child: Icon(
                item.icon,
                size: 22,
                color: selected ? t.accentBase : t.inkTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: SurgeText.micro.copyWith(
                color: selected ? t.inkPrimary : t.inkTertiary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
