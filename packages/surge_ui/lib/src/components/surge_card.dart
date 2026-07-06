import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';
import 'surge_pressable.dart';
import 'surge_list_row.dart';

/// Catalog:
/// name: SurgeCard
/// category: cards
/// summary: A padded rounded surface with a hairline border and optional float shadow.
/// whenToUse: Grouping arbitrary content into a card. For a tappable option card use SurgeActionCard.
/// tags: card, surface, container, panel
class SurgeCard extends StatelessWidget {
  const SurgeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevated = false,
    this.onPressed,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Adds the float shadow for a lifted look.
  final bool elevated;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.bgSubtle,
        borderRadius: BorderRadius.circular(t.radiusLg),
        border: Border.all(color: t.lineHairline),
        boxShadow: elevated ? t.shadowFloat : null,
      ),
      child: child,
    );
    if (onPressed == null) return card;
    return SurgePressable.row(onPressed: onPressed, child: card);
  }
}

/// Catalog:
/// name: SurgeActionCard
/// category: cards
/// summary: A tappable card with a leading icon tile, title/subtitle, and a selected state (accent border + check).
/// whenToUse: Selectable options, plan/onboarding choices, or navigable feature entries.
/// tags: card, option, select, choice, action
class SurgeActionCard extends StatelessWidget {
  const SurgeActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
    this.selected = false,
    this.chevron = true,
    this.trailing,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final bool selected;
  final bool chevron;
  final Widget? trailing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SurgePressable.row(
      onPressed: onPressed,
      child: Container(
        // Compensate the 1px extra border width when selected so the card does
        // not shift by a pixel on selection.
        padding: EdgeInsets.all(selected ? 15 : 16),
        decoration: BoxDecoration(
          color: selected ? t.accentTint : t.bgSubtle,
          borderRadius: BorderRadius.circular(t.radiusLg),
          border: selected
              ? Border.all(color: t.accentBase, width: 2)
              : Border.all(color: t.lineHairline),
        ),
        child: Row(
          children: [
            SurgeIconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SurgeText.headline.copyWith(color: t.inkPrimary),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style: SurgeText.footnote.copyWith(
                        color: t.inkSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (selected)
              Icon(Icons.check, size: 22, color: t.accentBase)
            else if (chevron)
              Icon(Icons.chevron_right, size: 20, color: t.inkTertiary),
          ],
        ),
      ),
    );
  }
}
