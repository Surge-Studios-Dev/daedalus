import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Semantic color for a [SurgeBadge].
enum SurgeBadgeKind { accent, success, warning, danger, neutral }

/// Catalog:
/// name: SurgeBadge
/// category: chips
/// summary: A small status pill (optional leading icon) in a semantic tint.
/// whenToUse: Inline status/markers — "New", "Saved", "PRO", counts. For tappable filters use SurgeFilterChip.
/// variants: accent, success, warning, danger, neutral
/// tags: badge, pill, status, label, marker, pro, new
class SurgeBadge extends StatelessWidget {
  const SurgeBadge(
    this.label, {
    super.key,
    this.kind = SurgeBadgeKind.accent,
    this.icon,
  });

  final String label;
  final SurgeBadgeKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg) = switch (kind) {
      SurgeBadgeKind.accent => (t.accentTint, t.accentBase),
      SurgeBadgeKind.success => (t.successTint, t.successBase),
      SurgeBadgeKind.warning => (t.warningTint, t.warningBase),
      SurgeBadgeKind.danger => (t.dangerTint, t.dangerBase),
      SurgeBadgeKind.neutral => (t.bgInset, t.inkSecondary),
    };
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SurgeRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label.toUpperCase(),
            style: SurgeText.micro.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
