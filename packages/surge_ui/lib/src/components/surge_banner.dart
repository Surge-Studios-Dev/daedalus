import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Semantic color for a [SurgeBanner].
enum SurgeBannerKind { accent, neutral, warning, success, danger }

/// Catalog:
/// name: SurgeBanner
/// category: feedback
/// summary: An inline message on a tinted surface, with optional icon, action, and dismiss.
/// whenToUse: Persistent, in-context messages (tips, warnings, status). For transient toasts, use a snackbar.
/// variants: accent, neutral, warning, success, danger
/// tags: banner, message, inline, alert, notice
class SurgeBanner extends StatelessWidget {
  const SurgeBanner({
    super.key,
    required this.message,
    this.kind = SurgeBannerKind.neutral,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final String message;
  final SurgeBannerKind kind;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, iconColor) = switch (kind) {
      SurgeBannerKind.accent => (t.accentTint, t.accentBase),
      SurgeBannerKind.neutral => (t.bgInset, t.inkSecondary),
      SurgeBannerKind.warning => (t.warningTint, t.warningBase),
      SurgeBannerKind.success => (t.successTint, t.successBase),
      SurgeBannerKind.danger => (t.dangerTint, t.dangerBase),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: SurgeText.footnote.copyWith(color: t.inkPrimary),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: SurgeText.footnote.copyWith(
                  color: t.accentBase,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 18, color: t.inkTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
