import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeMagicCta
/// category: buttons
/// summary: An animated "magic/auto" pill — a breathing accent glow with twinkles around the icon.
/// whenToUse: The AI/automatic option on a screen, to set it apart from ordinary buttons without shouting.
/// tags: cta, ai, magic, auto, animated, sparkle
class SurgeMagicCta extends StatefulWidget {
  const SurgeMagicCta({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.auto_awesome,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  State<SurgeMagicCta> createState() => _SurgeMagicCtaState();
}

class _SurgeMagicCtaState extends State<SurgeMagicCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Triangle wave 0->1->0 over one cycle, phase-shifted by [phase] (0..1).
  double _twinkle(double phase) {
    final v = (_ctrl.value + phase) % 1.0;
    return v < 0.5 ? v * 2 : (1 - v) * 2;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final breath = math.sin(_ctrl.value * math.pi * 2) * 0.5 + 0.5;
        final glow = 0.10 + 0.12 * breath;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(SurgeRadii.pill),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: t.accentTint,
                borderRadius: BorderRadius.circular(SurgeRadii.pill),
                border: Border.all(color: t.accentBase.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: t.accentBase.withValues(alpha: glow),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(widget.icon, size: 18, color: t.accentBase),
                        _Twinkle(
                          opacity: _twinkle(0.00),
                          dx: -10,
                          dy: -8,
                          color: t.accentBase,
                        ),
                        _Twinkle(
                          opacity: _twinkle(0.33),
                          dx: 11,
                          dy: -6,
                          color: t.accentBase,
                        ),
                        _Twinkle(
                          opacity: _twinkle(0.66),
                          dx: -7,
                          dy: 10,
                          color: t.accentBase,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SurgeText.bodyStrong.copyWith(color: t.accentBase),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Twinkle extends StatelessWidget {
  const _Twinkle({
    required this.opacity,
    required this.dx,
    required this.dy,
    required this.color,
  });

  final double opacity;
  final double dx;
  final double dy;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 11 + dx - 1.5,
      top: 11 + dy - 1.5,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
