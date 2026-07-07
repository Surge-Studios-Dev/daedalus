import 'package:flutter/material.dart';

import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeGlowOrb
/// category: feedback
/// summary: A protagonist treatment - a circular tinted stage with a soft radial glow behind an emoji, icon, or short text.
/// whenToUse: The screen's ONE focal element (DESIGN.md rule 2): streak flames, empty-state marks, hero icons. Never more than one glowing protagonist per screen.
/// tags: hero, glow, orb, protagonist, focal, halo, empty
class SurgeGlowOrb extends StatelessWidget {
  const SurgeGlowOrb({
    super.key,
    this.emoji,
    this.icon,
    this.size = 112,
    this.dim = false,
  }) : assert(emoji != null || icon != null, 'give the orb a face');

  final String? emoji;
  final IconData? icon;
  final double size;

  /// Dimmed variant (a banked ember, a broken streak): glow off,
  /// content desaturated - the protagonist at rest.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.accentTint,
        boxShadow: dim
            ? null
            : [
                BoxShadow(
                  color: t.accentBase.withValues(alpha: 0.30),
                  blurRadius: size * 0.55,
                  spreadRadius: size * 0.06,
                ),
              ],
      ),
      child: emoji != null
          ? Text(
              emoji!,
              style: TextStyle(
                fontSize: size * 0.42,
                color: dim ? t.inkTertiary : null,
              ),
            )
          : Icon(
              icon,
              size: size * 0.42,
              color: dim ? t.inkTertiary : t.accentBase,
            ),
    );
  }
}
