import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeStatTile
/// category: data
/// summary: A glass panel with a small caps label and a display-sized value; SurgeStatRow lays several out 2-up or 3-up.
/// whenToUse: Facts people care about (streaks, counts, totals) as dense tile grids instead of body-text lines (DESIGN.md rules 3-4, the moon-details pattern).
/// tags: stat, tile, metric, number, grid, dashboard, density
class SurgeStatTile extends StatelessWidget {
  const SurgeStatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.sub,
  });

  final String label;
  final String value;

  /// Override for the value - pass the app's display face here.
  final TextStyle? valueStyle;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.bgSubtle.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.lineHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: SurgeText.micro.copyWith(
              color: t.inkTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (valueStyle ?? SurgeText.title1).copyWith(
              color: t.inkPrimary,
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: SurgeText.footnote.copyWith(color: t.inkSecondary),
            ),
        ],
      ),
    );
  }
}

/// Lays [tiles] out as an equal-width row (the 2-up / 3-up grid).
class SurgeStatRow extends StatelessWidget {
  const SurgeStatRow({super.key, required this.tiles, this.gap = 10});

  final List<SurgeStatTile> tiles;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}
