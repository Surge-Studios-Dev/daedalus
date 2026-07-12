import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeFloatingNavBar
/// category: navigation
/// summary: Ladle's floating tab pill - crisp opaque bar, labeled icon tabs, and a raised center action ringed in the surface color.
/// whenToUse: The app shell's bottom navigation. Pair with Scaffold(extendBody: true) so content scrolls beneath the pill. The geometry mirrors Ladle's shipped bar (the studio reference) - do not restyle per app.
/// tags: navigation, tabs, bottom bar, floating, pill, shell
class SurgeNavItem {
  const SurgeNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Screen-level scroll padding that respects the floating bar's nothing
/// zone. An explicit `padding:` on a ListView/SliverPadding DISCARDS the
/// ambient MediaQuery inset - the classic overlap: the screen looks fine
/// until the raised center action sits on its last row. Use this instead
/// of `EdgeInsets.all(...)` on any screen-level scrollable; under
/// Scaffold(extendBody: true) the MediaQuery bottom already includes the
/// bar + raise + clearance, elsewhere it is just the system inset - both
/// correct.
EdgeInsets surgeScrollPadding(
  BuildContext context, {
  double horizontal = 16,
  double top = 16,
  double gap = 16,
}) =>
    EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      MediaQuery.paddingOf(context).bottom + gap,
    );

/// Ladle's toolbar, promoted verbatim (2026-07-08): 64-high opaque bgBase
/// pill (radius 32, hairline, lift shadow), icon-over-caption tabs that
/// tint accentBase when active, and - when [centerAction] is set - a
/// reserved empty middle column with the action floating 18px above the
/// bar. Two glass/wordless redesigns lost to this in situ; the raised
/// ring is what reads "crisp".
class SurgeFloatingNavBar extends StatelessWidget {
  const SurgeFloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    this.centerAction,
  });

  final List<SurgeNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// The raised center button. Size it 60x60 with a 3px bgBase ring
  /// (see SurgeRaisedNavAction) so it overlaps the bar the way Ladle's
  /// Add button does. Null = plain pill.
  final Widget? centerAction;

  /// How far the center action floats above the bar. This raise is INSIDE
  /// the widget's layout box (transparent headroom, not an out-of-bounds
  /// Positioned) so Scaffold's extendBody MediaQuery padding covers the
  /// flame too: any screen that respects bottom insets automatically keeps
  /// its foreground widgets out of the nothing zone, while backgrounds and
  /// scrolling content still pass beneath. Ember lesson (2026-07-08): an
  /// out-of-bounds raise overlapped bottom content on every pushed screen,
  /// because layout machinery can't reserve space it can't see.
  static const double raise = 18;

  /// Breathing room ABOVE the flame tip (or the plain pill), also inside
  /// the layout box. Reserving space only up to the tip left inset-
  /// respecting widgets sitting flush ON it - visually an overlap (Ember,
  /// 2026-07-09: the flame's tip kissed bottom-anchored content on new
  /// screens). The nothing zone is bar + raise + this clearance; fixed
  /// foreground widgets stay out of all of it, while the atmosphere and
  /// scrolling content still pass beneath.
  static const double clearance = 12;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomGap = safeBottom > 8 ? safeBottom : 18.0;
    final cells = <Widget>[
      for (var i = 0; i < items.length; i++)
        _NavCell(
          item: items[i],
          selected: i == currentIndex,
          onTap: () => onSelected(i),
        ),
    ];
    if (centerAction != null) {
      // Reserved column keeps the tabs evenly spaced around the raised
      // button (Ladle's exact trick).
      cells.insert(
        (items.length + 1) ~/ 2,
        const Expanded(child: SizedBox.shrink()),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomGap),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: clearance + (centerAction != null ? raise : 0),
              ),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: t.bgBase,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: t.lineHairline),
                  boxShadow: t.shadowLift,
                ),
                child: Row(children: cells),
              ),
            ),
            if (centerAction != null)
              Positioned(top: clearance, child: centerAction!),
          ],
        ),
      ),
    );
  }
}

/// The raised center action's chrome: a 60px accent circle ringed in
/// bgBase so it visually punches through the bar (Ladle's Add button).
/// Wrap your icon/behavior in this so every app's raised action matches.
class SurgeRaisedNavAction extends StatelessWidget {
  const SurgeRaisedNavAction({
    super.key,
    required this.child,
    required this.label,
    this.onTap,
  });

  final Widget child;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: t.accentBase,
            shape: BoxShape.circle,
            boxShadow: t.shadowLift,
            border: Border.all(color: t.bgBase, width: 3),
          ),
          alignment: Alignment.center,
          child: ExcludeSemantics(child: child),
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
    final color = selected ? t.accentBase : t.inkTertiary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: SurgeText.caption.copyWith(
                  fontSize: 10,
                  height: 1.1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
