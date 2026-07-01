import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeLoadingLabel
/// category: feedback
/// summary: A word followed by three dots that hop in a staggered wave.
/// whenToUse: A friendly full-screen/sheet wait ("Importing", "Analyzing"). For compact loading use SurgeSpinner.
/// tags: loading, label, ellipsis, wait, progress
///
/// Honors reduce-motion by holding the dots still. The dots translate on paint
/// only, so layout and baseline stay put.
class SurgeLoadingLabel extends StatefulWidget {
  const SurgeLoadingLabel(this.text, {super.key, this.style});

  /// The leading word, e.g. "Importing".
  final String text;

  /// Override the text style; defaults to the display style in primary ink.
  final TextStyle? style;

  @override
  State<SurgeLoadingLabel> createState() => _SurgeLoadingLabelState();
}

class _SurgeLoadingLabelState extends State<SurgeLoadingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style =
        widget.style ?? SurgeText.display.copyWith(color: t.inkPrimary);
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(widget.text, style: style),
        for (var i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final phase = (_c.value - i * 0.18) % 1.0;
              final hop = phase < 0.5 ? math.sin(phase * 2 * math.pi) : 0.0;
              return Transform.translate(
                offset: Offset(0, reduce ? 0 : -5 * hop),
                child: child,
              );
            },
            child: Text('.', style: style),
          ),
      ],
    );
  }
}
