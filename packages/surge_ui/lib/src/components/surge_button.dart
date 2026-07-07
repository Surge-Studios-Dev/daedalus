import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';
import 'surge_pressable.dart';

/// Catalog:
/// name: SurgeButton
/// category: buttons
/// summary: The standard text button in five variants.
/// whenToUse: Any tappable action label. Use primary for the main action on a
///   screen, secondary/ghost for supporting actions, destructive for delete.
/// variants: primary, secondary, destructive, ghost, small
/// tags: button, cta, action, submit
enum _Variant { primary, secondary, destructive, ghost, small }

/// A themed button. Construct with the named constructor for the variant you
/// want: [SurgeButton.primary], [SurgeButton.secondary],
/// [SurgeButton.destructive], [SurgeButton.ghost], [SurgeButton.small].
///
/// A null [onPressed] renders the disabled state. [loading] swaps the label for
/// a spinner and blocks taps.
class SurgeButton extends StatelessWidget {
  const SurgeButton.primary(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.iconRight,
    this.full = false,
    this.loading = false,
  }) : _variant = _Variant.primary;

  const SurgeButton.secondary(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.iconRight,
    this.full = false,
    this.loading = false,
  }) : _variant = _Variant.secondary;

  const SurgeButton.destructive(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.iconRight,
    this.full = false,
    this.loading = false,
  }) : _variant = _Variant.destructive;

  const SurgeButton.ghost(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.iconRight,
    this.full = false,
    this.loading = false,
  }) : _variant = _Variant.ghost;

  const SurgeButton.small(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.iconRight,
    this.full = false,
    this.loading = false,
  }) : _variant = _Variant.small;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? iconRight;

  /// Stretch to the parent's full width.
  final bool full;

  /// Show a spinner instead of the label and block taps.
  final bool loading;

  final _Variant _variant;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = onPressed == null;

    final (Color bg, Color fg) = switch (_variant) {
      _ when disabled && _variant == _Variant.primary => (
          t.bgInset,
          t.inkDisabled,
        ),
      _Variant.primary => (t.accentBase, t.accentOn),
      _Variant.secondary || _Variant.small => (t.accentTint, t.accentBase),
      _Variant.destructive => (t.dangerTint, t.dangerBase),
      _Variant.ghost => (Colors.transparent, t.accentBase),
    };

    final double height = switch (_variant) {
      _Variant.ghost => 44,
      _Variant.small => 36,
      _ => 52,
    };
    final double radius = switch (_variant) {
      _Variant.ghost => SurgeRadii.pill,
      _Variant.small => t.radiusSm,
      _ => t.radiusMd,
    };
    final double hpad = switch (_variant) {
      _Variant.small => 14,
      _Variant.ghost => 12,
      _ => 20,
    };
    final textStyle =
        (_variant == _Variant.small ? SurgeText.subhead : SurgeText.headline)
            .copyWith(color: fg, fontWeight: FontWeight.w600);
    final iconSize = _variant == _Variant.small ? 18.0 : 20.0;

    // Tint-filled variants dim when disabled; the primary/ghost variants
    // already recolor above, so a disabled one never looks active.
    final dimmed = disabled &&
        (_variant == _Variant.secondary ||
            _variant == _Variant.destructive ||
            _variant == _Variant.small);

    return SurgePressable(
      onPressed: loading ? null : onPressed,
      enabled: !disabled && !loading,
      scaleTo: 0.98,
      child: Opacity(
        opacity: dimmed ? 0.4 : 1.0,
        child: Container(
          height: height,
          width: full ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: hpad),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: loading
                ? [
                    SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(fg),
                      ),
                    ),
                  ]
                : [
                    if (icon != null) ...[
                      Icon(icon, size: iconSize, color: fg),
                      const SizedBox(width: SurgeSpace.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle,
                      ),
                    ),
                    if (iconRight != null) ...[
                      const SizedBox(width: SurgeSpace.sm),
                      Icon(iconRight, size: iconSize, color: fg),
                    ],
                  ],
          ),
        ),
      ),
    );
  }
}

/// Catalog:
/// name: SurgeIconButton
/// category: buttons
/// summary: A 44pt tappable icon, optionally accent/danger tinted or on a scrim.
/// whenToUse: Icon-only actions in toolbars, cards, or over imagery (scrim).
/// tags: icon, button, toolbar, appbar
///
/// A circular 44pt icon target. Set [scrim] when placed over a photo so it gets
/// a dark backing circle and white glyph.
class SurgeIconButton extends StatelessWidget {
  const SurgeIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24,
    this.accent = false,
    this.danger = false,
    this.scrim = false,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool accent;
  final bool danger;
  final bool scrim;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = scrim
        ? Colors.white
        : danger
            ? t.dangerBase
            : accent
                ? t.accentBase
                : t.inkPrimary;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SurgePressable(
        onPressed: onPressed,
        scaleTo: 0.94,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scrim ? const Color(0x660B0D12) : null,
          ),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
