import 'package:flutter/material.dart';

import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeAtmosphere
/// category: layout
/// summary: A token-derived background wash - vertical surface gradient plus at most one radial accent glow anchored to the screen's protagonist.
/// whenToUse: Behind hero screens and detail screens (DESIGN.md rule 1 - never a dead flat fill). Wrap the Scaffold body; keep Scaffold backgroundColor transparent or default.
/// tags: background, gradient, glow, atmosphere, hero, wash
class SurgeAtmosphere extends StatelessWidget {
  const SurgeAtmosphere({
    super.key,
    required this.child,
    this.glowAlignment = const Alignment(0, -0.55),
    this.glowStrength = 0.14,
    this.glowRadius = 0.62,
  });

  final Widget child;

  /// Where the radial glow sits - anchor it to the protagonist.
  final Alignment glowAlignment;

  /// 0..0.35 (DESIGN.md caps glow alpha); 0 disables the glow.
  final double glowStrength;

  /// Radial spread - keep the glow a halo, not a wash.
  final double glowRadius;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.bgSubtle, t.bgBase, t.bgBase],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: glowStrength <= 0
          ? child
          : Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: glowAlignment,
                      radius: glowRadius,
                      colors: [
                        t.accentBase.withValues(
                          alpha: glowStrength.clamp(0, 0.35),
                        ),
                        t.accentBase.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                child,
              ],
            ),
    );
  }
}
