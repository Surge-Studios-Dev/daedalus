import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeSegmented
/// category: selection
/// summary: A 36pt segmented control on an inset track, with a sliding or cross-fading thumb.
/// whenToUse: 2-4 mutually exclusive options. expand:true for equal slices, false to size to labels.
/// variants: expand, hug
/// tags: segmented, control, tabs, switch, toggle
///
/// [expand] true (default): equal-width segments that fill the width, with one
/// thumb that slides. [expand] false: each segment sizes to its own label, so a
/// longer option gets a wider pill; the fill/shadow cross-fades instead.
class SurgeSegmented extends StatelessWidget {
  const SurgeSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.labels,
    this.expand = true,
  }) : assert(
         labels == null || labels.length == options.length,
         'labels must line up 1:1 with options',
       );

  /// The stored values compared against [value] and emitted by [onChanged].
  final List<String> options;

  /// Optional display text (one per option) when the stored value differs from
  /// what should be shown. Falls back to [options].
  final List<String>? labels;

  final String value;
  final ValueChanged<String> onChanged;
  final bool expand;

  String _labelAt(int i) => labels != null ? labels![i] : options[i];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (options.isEmpty) return const SizedBox.shrink();
    return expand ? _expanding(t) : _hugging(t);
  }

  Widget _expanding(SurgeTokens t) {
    final index = options.indexOf(value).clamp(0, options.length - 1);
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.bgInset,
        borderRadius: BorderRadius.circular(SurgeRadii.pill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segWidth = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: t.motionFast,
                curve: t.curveStandard,
                left: index * segWidth,
                width: segWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.bgBase,
                    borderRadius: BorderRadius.circular(SurgeRadii.pill),
                    boxShadow: t.shadowFloat,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(options[i]),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: t.motionFast,
                            style: SurgeText.subhead.copyWith(
                              fontWeight: FontWeight.w600,
                              color: options[i] == value
                                  ? t.inkPrimary
                                  : t.inkSecondary,
                            ),
                            child: Text(_labelAt(i)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hugging(SurgeTokens t) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.bgInset,
        borderRadius: BorderRadius.circular(SurgeRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(options[i]),
              child: AnimatedContainer(
                duration: t.motionFast,
                curve: t.curveStandard,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: options[i] == value ? t.bgBase : Colors.transparent,
                  borderRadius: BorderRadius.circular(SurgeRadii.pill),
                  boxShadow: options[i] == value ? t.shadowFloat : null,
                ),
                child: Text(
                  _labelAt(i),
                  style: SurgeText.subhead.copyWith(
                    fontWeight: FontWeight.w600,
                    color: options[i] == value ? t.inkPrimary : t.inkSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
