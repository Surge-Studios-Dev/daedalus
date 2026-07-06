import 'package:flutter/material.dart';

import '../tokens/ladle_text.dart';
import '../tokens/ladle_tokens.dart';

/// meter.imports - "N of CAP free imports left this week" + dot row.
/// [bonus] is referral-earned banked imports (never expire, spend after
/// the weekly 5); shown as a suffix so the weekly rhythm stays the story.
class ImportMeter extends StatelessWidget {
  const ImportMeter({
    super.key,
    required this.used,
    required this.cap,
    this.bonus = 0,
  });

  final int used;
  final int cap;
  final int bonus;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final left = (cap - used).clamp(0, cap);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bonus > 0
              ? '$left of $cap free imports left this week · +$bonus bonus'
              : '$left of $cap free imports left this week',
          style: LadleText.footnote.tnum.copyWith(color: t.inkSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < cap; i++)
              Padding(
                padding: EdgeInsets.only(right: i < cap - 1 ? 6 : 0),
                child: Container(
                  width: 18,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < left ? t.accentBase : t.bgInset,
                    borderRadius: BorderRadius.circular(LadleRadii.pill),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
