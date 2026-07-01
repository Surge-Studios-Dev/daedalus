import 'package:flutter/material.dart';

/// Shared press feedback. Buttons scale down slightly on tap; rows dim instead.
/// Every tappable surface in the library goes through this so press behavior is
/// identical everywhere.
class SurgePressable extends StatefulWidget {
  const SurgePressable({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.scaleTo = 0.98,
    this.opacityTo = 1.0,
    this.enabled = true,
  });

  /// Row/list variant: no scale, dims to 0.6 opacity while pressed.
  const SurgePressable.row({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.enabled = true,
  }) : scaleTo = 1.0,
       opacityTo = 0.6;

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double scaleTo;
  final double opacityTo;
  final bool enabled;

  @override
  State<SurgePressable> createState() => _SurgePressableState();
}

class _SurgePressableState extends State<SurgePressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final active = _down && widget.enabled && widget.onPressed != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.enabled ? widget.onPressed : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: active ? widget.scaleTo : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          opacity: active ? widget.opacityTo : 1.0,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}
