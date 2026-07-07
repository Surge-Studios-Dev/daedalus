import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Rounds [value] to the nearest multiple of [step] in the tap [direction],
/// clamped to [min]..[max]. Off-grid existing values snap toward the direction
/// so a tap always lands on the step grid.
double surgeStepValue(
  double value,
  int direction, {
  double min = 1,
  double max = 99,
  double step = 1,
}) {
  final base = direction > 0
      ? (value / step).floorToDouble() * step
      : (value / step).ceilToDouble() * step;
  final next = base + direction * step;
  return next.clamp(min, max);
}

/// Catalog:
/// name: SurgeStepper
/// category: selection
/// summary: A 36pt -/+ stepper with a tabular value and selection haptics.
/// whenToUse: Adjusting a bounded number (quantity, servings, a goal). Pass step/format to tune.
/// tags: stepper, number, quantity, increment, counter
class SurgeStepper extends StatelessWidget {
  const SurgeStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.step = 1,
    this.format,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  /// Increment per tap. Defaults to 1.
  final double step;

  /// Optional display formatter for the value.
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget control(IconData icon, bool enabled, int direction) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged(
                  surgeStepValue(
                    value,
                    direction,
                    min: min,
                    max: max,
                    step: step,
                  ),
                );
              }
            : null,
        child: SizedBox(
          width: 40,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? t.accentBase : t.inkDisabled,
          ),
        ),
      );
    }

    final label = format?.call(value) ??
        (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: t.bgInset,
        borderRadius: BorderRadius.circular(SurgeRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          control(Icons.remove, value > min, -1),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: SurgeText.bodyStrong.tnum.copyWith(color: t.inkPrimary),
            ),
          ),
          control(Icons.add, value < max, 1),
        ],
      ),
    );
  }
}
