import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';
import 'surge_pressable.dart';

/// Catalog:
/// name: SurgeFilterChip
/// category: chips
/// summary: A 32pt pill filter chip; selected shows a leading check and accent tint.
/// whenToUse: Toggleable filters. Set stableWidth in multi-select grids so toggling never reflows.
/// tags: chip, filter, toggle, select
class SurgeFilterChip extends StatelessWidget {
  const SurgeFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onPressed,
    this.icon,
    this.stableWidth = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Reserve the leading check slot even when unselected, so toggling selection
  /// never changes the chip's width (avoids reflow in a multi-select Wrap).
  final bool stableWidth;

  // Leading check (16) + trailing gap (6).
  static const double _checkSlot = 22;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.accentBase : t.inkSecondary;
    return SurgePressable(
      onPressed: onPressed,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? t.accentTint : t.bgInset,
          borderRadius: BorderRadius.circular(SurgeRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            if (selected) ...[
              Icon(Icons.check, size: 16, color: fg),
              const SizedBox(width: 6),
            ] else if (stableWidth)
              const SizedBox(width: _checkSlot),
            Text(label, style: SurgeText.subhead.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Catalog:
/// name: SurgeTagChip
/// category: chips
/// summary: A 28pt read-only pill, optionally with a leading icon and a remove affordance.
/// whenToUse: Displaying applied tags/filters. Pass onRemove to make it dismissible.
/// tags: chip, tag, token, removable
class SurgeTagChip extends StatelessWidget {
  const SurgeTagChip({
    super.key,
    required this.label,
    this.onRemove,
    this.icon,
  });

  final String label;
  final VoidCallback? onRemove;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.bgInset,
        borderRadius: BorderRadius.circular(SurgeRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: t.inkSecondary),
            const SizedBox(width: 5),
          ],
          Text(label, style: SurgeText.caption.copyWith(color: t.inkSecondary)),
          if (onRemove != null) ...[
            const SizedBox(width: 5),
            SurgePressable(
              onPressed: onRemove,
              child: Icon(Icons.close, size: 14, color: t.inkSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
