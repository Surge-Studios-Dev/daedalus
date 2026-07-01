import 'package:flutter/material.dart';

import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeProgressBar
/// category: feedback
/// summary: A 2px determinate progress fill (0..1), eased.
/// whenToUse: Known progress (steps, upload). For unknown duration use SurgeIndeterminateBar.
/// tags: progress, bar, determinate, meter
class SurgeProgressBar extends StatelessWidget {
  const SurgeProgressBar({super.key, required this.value});

  /// 0..1
  final double value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 2,
        child: Stack(
          children: [
            Container(color: t.bgInset),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 280),
              curve: const Cubic(0.2, 0, 0, 1),
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0, 1),
              child: Container(color: t.accentBase),
            ),
          ],
        ),
      ),
    );
  }
}

/// Catalog:
/// name: SurgeIndeterminateBar
/// category: feedback
/// summary: A 2px accent bar that sweeps continuously for unknown-duration work.
/// whenToUse: Ongoing work with no measurable progress (a running import/request).
/// tags: progress, indeterminate, loading, bar
class SurgeIndeterminateBar extends StatefulWidget {
  const SurgeIndeterminateBar({super.key});

  @override
  State<SurgeIndeterminateBar> createState() => _SurgeIndeterminateBarState();
}

class _SurgeIndeterminateBarState extends State<SurgeIndeterminateBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 2,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final x =
                  -0.4 * w +
                  1.4 * w * Curves.easeInOut.transform(_controller.value);
              return Stack(
                children: [
                  Container(color: t.bgInset),
                  Positioned(
                    left: x,
                    width: w * 0.4,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: t.accentBase,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Catalog:
/// name: SurgeSkeleton
/// category: feedback
/// summary: A shimmering placeholder block for loading content.
/// whenToUse: Content placeholders while data loads, instead of a spinner on lists/cards.
/// tags: skeleton, shimmer, placeholder, loading
class SurgeSkeleton extends StatefulWidget {
  const SurgeSkeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<SurgeSkeleton> createState() => _SurgeSkeletonState();
}

class _SurgeSkeletonState extends State<SurgeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: t.bgInset,
              gradient: LinearGradient(
                begin: Alignment(-3 + 4 * _controller.value, 0),
                end: Alignment(-1 + 4 * _controller.value, 0),
                colors: [
                  t.bgInset,
                  Color.alphaBlend(t.bgBase.withValues(alpha: 0.5), t.bgInset),
                  t.bgInset,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
