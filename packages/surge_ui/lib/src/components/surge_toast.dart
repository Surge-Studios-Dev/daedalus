import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Semantic kind of a [SurgeToast].
enum SurgeToastKind { neutral, success, error }

/// Catalog:
/// name: SurgeToast
/// category: overlays
/// summary: A bottom-anchored pill toast, branded per kind (neutral outline, success/error fills).
/// whenToUse: Transient confirmation/errors. Call showSurgeToast; it coalesces so a new message replaces the old.
/// variants: neutral, success, error
/// tags: toast, snackbar, notification, transient, feedback
class SurgeToast extends StatelessWidget {
  const SurgeToast({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.kind = SurgeToastKind.success,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final SurgeToastKind kind;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isNeutral = kind == SurgeToastKind.neutral;
    final (IconData icon, Color bgColor, Color borderColor, Color fgColor,
        Color iconColor) = switch (kind) {
      SurgeToastKind.success => (
        Icons.check,
        t.accentBase,
        Colors.transparent,
        t.accentOn,
        t.accentOn,
      ),
      SurgeToastKind.error => (
        Icons.error_outline,
        t.dangerBase,
        Colors.transparent,
        Colors.white,
        Colors.white,
      ),
      SurgeToastKind.neutral => (
        Icons.info_outline,
        t.accentTint,
        t.accentBase,
        t.inkPrimary,
        t.accentBase,
      ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SurgeRadii.pill),
        border: isNeutral
            ? Border.all(color: borderColor.withValues(alpha: 0.32), width: 1.2)
            : null,
        boxShadow: t.shadowLift,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isNeutral
                  ? t.accentBase.withValues(alpha: 0.14)
                  : fgColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SurgeText.subhead.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isNeutral ? t.accentBase : fgColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(SurgeRadii.pill),
                ),
                child: Text(
                  actionLabel!,
                  style: SurgeText.footnote.copyWith(
                    color: isNeutral ? t.accentOn : fgColor,
                    fontWeight: FontWeight.w700,
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

OverlayEntry? _currentToast;

/// Immediately remove any toast on screen. Call from a route observer so
/// navigation never leaves a stale toast hovering over a new screen.
void dismissCurrentSurgeToast() {
  _currentToast?.remove();
  _currentToast = null;
}

/// Shows a [SurgeToast] near the bottom for ~2.6s (240ms slide+fade). Anchored
/// to the root overlay so it floats above page content. Pass [bottomOffset] to
/// lift it above a bottom-pinned input/nav. Coalesces: a new toast replaces any
/// current one instead of stacking.
void showSurgeToast(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  SurgeToastKind kind = SurgeToastKind.success,
  Duration? duration,
  double bottomOffset = 0,
}) {
  _currentToast?.remove();
  _currentToast = null;
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _ToastHost(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      kind: kind,
      duration: duration ?? const Duration(milliseconds: 2600),
      bottomOffset: bottomOffset,
      onDone: () {
        if (identical(_currentToast, entry)) _currentToast = null;
        entry.remove();
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.message,
    required this.onDone,
    required this.kind,
    required this.duration,
    required this.bottomOffset,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final SurgeToastKind kind;
  final Duration duration;
  final double bottomOffset;
  final VoidCallback onDone;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  // Created once and disposed with the controller so a downstream rebuild can't
  // hand a transition a stale animation after dispose.
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: const Cubic(0.2, 0, 0, 1),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.4),
    end: Offset.zero,
  ).animate(_curved);
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    await _controller.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPad + 90 + widget.bottomOffset,
      child: FadeTransition(
        opacity: _curved,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: _dismiss,
                child: SurgeToast(
                  message: widget.message,
                  actionLabel: widget.actionLabel,
                  kind: widget.kind,
                  onAction: () {
                    widget.onAction?.call();
                    _dismiss();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
