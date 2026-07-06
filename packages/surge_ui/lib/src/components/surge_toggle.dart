import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeToggle
/// category: selection
/// summary: A 51x31 on/off switch with a sliding knob and selection haptic.
/// whenToUse: Boolean settings. Inside a grouped settings row, SurgeGroupRow already renders one.
/// tags: toggle, switch, boolean, setting
class SurgeToggle extends StatelessWidget {
  const SurgeToggle({super.key, required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      toggled: on,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!on);
        },
        child: AnimatedContainer(
          duration: t.motionFast,
          width: 51,
          height: 31,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: on ? t.accentBase : t.lineStrong,
            borderRadius: BorderRadius.circular(SurgeRadii.pill),
          ),
          child: AnimatedAlign(
            duration: t.motionFast,
            curve: t.curveStandard,
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 27,
              height: 27,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Color(0x40000000),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
