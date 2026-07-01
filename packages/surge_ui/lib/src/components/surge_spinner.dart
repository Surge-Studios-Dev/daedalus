import 'package:flutter/material.dart';

import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeSpinner
/// category: feedback
/// summary: A 2px-stroke circular activity indicator in the accent color.
/// whenToUse: Inline loading. Buttons already show one internally via loading:.
/// tags: spinner, loading, activity, progress
class SurgeSpinner extends StatelessWidget {
  const SurgeSpinner({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? context.tokens.accentBase,
      ),
    );
  }
}
