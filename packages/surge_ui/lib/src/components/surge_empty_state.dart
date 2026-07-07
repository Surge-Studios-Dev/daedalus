import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';
import 'surge_button.dart';
import 'surge_glow_orb.dart';

/// Catalog:
/// name: SurgeEmptyState
/// category: feedback
/// summary: A centered icon circle, title, subtitle, and optional primary/ghost actions.
/// whenToUse: Empty lists, zero-results, or a first-run screen body. Also fits error states with a retry action.
/// tags: empty, state, placeholder, zero, error, retry
class SurgeEmptyState extends StatelessWidget {
  const SurgeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
    this.primaryLabel,
    this.onPrimary,
    this.ghostLabel,
    this.onGhost,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? ghostLabel;
  final VoidCallback? onGhost;

  /// Optional widget rendered centered below the action stack.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Self-centering on BOTH axes: a bare Column sizes to its widest
    // child and sits wherever the parent puts it, so every consumer had
    // to remember Center() - the ones that didn't shipped off-center
    // screens (recurred on Ladle, then Ember's Today empty state). The
    // component owns its centering now; the scroll view keeps it safe at
    // small heights / large text scales.
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First-run is a promise, not an apology (DESIGN.md rule
              // 6): the empty state's mark is a lit protagonist.
              const SizedBox(height: 8),
              SurgeGlowOrb(icon: icon, size: 104),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: SurgeText.title2.copyWith(color: t.inkPrimary),
              ),
              if (sub != null) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    sub!,
                    textAlign: TextAlign.center,
                    style: SurgeText.subhead.copyWith(color: t.inkSecondary),
                  ),
                ),
              ],
              if (primaryLabel != null || ghostLabel != null || extra != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (primaryLabel != null)
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 200),
                          child: SurgeButton.primary(
                            primaryLabel!,
                            onPressed: onPrimary,
                          ),
                        ),
                      if (ghostLabel != null) ...[
                        const SizedBox(height: 6),
                        SurgeButton.ghost(ghostLabel!, onPressed: onGhost),
                      ],
                      if (extra != null) ...[
                        const SizedBox(height: 12),
                        extra!,
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
