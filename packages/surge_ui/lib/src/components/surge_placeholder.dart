import 'package:flutter/material.dart';

import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgePlaceholder
/// category: media
/// summary: A diagonally-hatched image placeholder with a small monospace label.
/// whenToUse: A deliberate stand-in for a missing image/thumbnail. For loading shimmer use SurgeSkeleton.
/// tags: placeholder, image, thumbnail, media, missing
class SurgePlaceholder extends StatelessWidget {
  const SurgePlaceholder({super.key, required this.label, this.big = false});

  final String label;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // ClipRect: the hatching is drawn corner to corner and overshoots the box
    // by design, so it must be clipped to its own bounds.
    return ClipRect(
      child: CustomPaint(
        painter: _StripePainter(background: t.bgInset, stripe: t.lineHairline),
        child: Center(
          child: Text(
            label.toLowerCase(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: big ? 13 : 10,
              color: t.inkTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter({required this.background, required this.stripe});

  final Color background;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 6;
    const gap = 14.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) =>
      old.background != background || old.stripe != stripe;
}
