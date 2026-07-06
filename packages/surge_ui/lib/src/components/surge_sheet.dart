import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';
import 'surge_badge.dart';
import 'surge_button.dart';
import 'surge_pressable.dart';

/// How tall a [SurgeSheet] sizes.
enum SurgeSheetDetent { auto, half, tall }

/// Catalog:
/// name: SurgeSheet
/// category: overlays
/// summary: A bottom-sheet shell with a grabber, optional title + Done, scrollable body, and fixed foot.
/// whenToUse: Modal content from the bottom. Present it with showSurgeSheet so it rides above the keyboard.
/// variants: auto, half, tall
/// tags: sheet, bottom sheet, modal, overlay
class SurgeSheet extends StatelessWidget {
  const SurgeSheet({
    super.key,
    this.title,
    this.trailing,
    required this.body,
    this.foot,
    this.detent = SurgeSheetDetent.auto,
    this.noPad = false,
    this.scrollable = true,
  });

  final String? title;
  final Widget? trailing;
  final Widget body;
  final Widget? foot;
  final SurgeSheetDetent detent;
  final bool noPad;

  /// When true (default) the body is wrapped in a scroll view. Set false when
  /// the body provides its own scrolling region (e.g. an Expanded ListView).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final screenHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    final height = switch (detent) {
      SurgeSheetDetent.tall => screenHeight * 0.92,
      SurgeSheetDetent.half => screenHeight * 0.60,
      SurgeSheetDetent.auto => null,
    };

    return Container(
      height: height,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      decoration: BoxDecoration(
        color: t.bgBase,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(t.radiusXl),
        ),
        boxShadow: t.shadowLift,
      ),
      child: Column(
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: t.lineStrong,
              borderRadius: BorderRadius.circular(SurgeRadii.pill),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: SurgeText.title2.copyWith(color: t.inkPrimary),
                    ),
                  ),
                  trailing ??
                      SurgeButton.ghost(
                        'Done',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                ],
              ),
            ),
          Flexible(
            fit: height == null ? FlexFit.loose : FlexFit.tight,
            child: scrollable
                ? SingleChildScrollView(
                    padding: noPad
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: 16),
                    child: body,
                  )
                : Padding(
                    padding: noPad
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: 16),
                    child: body,
                  ),
          ),
          if (foot != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: foot,
            ),
        ],
      ),
    );
  }
}

/// Presents a [SurgeSheet] with a scrim, riding above the keyboard. Uses the
/// root navigator so the sheet sits above any floating tab bar.
Future<T?> showSurgeSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    useSafeArea: true,
    // Plain Padding (not AnimatedPadding): track the keyboard inset 1:1 so the
    // sheet height and padding stay in sync as it opens.
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: builder(sheetContext),
    ),
  );
}

/// A centered confirm dialog. Set [destructive] to fill the confirm with the
/// danger color. Returns true if confirmed.
Future<bool> showSurgeConfirm(
  BuildContext context, {
  required String title,
  String? body,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final t = context.tokens;
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0x66000000),
    transitionDuration: t.motionBase,
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.2, 0, 0, 1),
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (dialogContext, _, __) => Center(
      child: Container(
        width: 320,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: t.bgBase,
          borderRadius: BorderRadius.circular(t.radiusLg),
          boxShadow: t.shadowLift,
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SurgeText.headline.copyWith(color: t.inkPrimary),
              ),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(
                  body,
                  style: SurgeText.subhead.copyWith(color: t.inkSecondary),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ModalButton(
                      label: cancelLabel,
                      background: t.bgInset,
                      foreground: t.inkPrimary,
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModalButton(
                      label: confirmLabel,
                      background: destructive ? t.dangerBase : t.accentBase,
                      foreground: t.accentOn,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// One row in a [showSurgeActionMenu].
class SurgeActionMenuItem {
  const SurgeActionMenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
    this.badge,
    this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool danger;

  /// Optional trailing badge label (e.g. "PRO").
  final String? badge;
  final VoidCallback? onSelected;
}

/// Catalog:
/// name: showSurgeActionMenu
/// category: overlays
/// summary: A context menu presented as a sheet of icon+label rows with a cancel foot.
/// whenToUse: A "more actions" (...) menu. Each item runs its onSelected after the sheet closes.
/// tags: menu, actions, context menu, sheet, more
Future<void> showSurgeActionMenu(
  BuildContext context, {
  required String title,
  required List<SurgeActionMenuItem> items,
  String cancelLabel = 'Cancel',
}) {
  return showSurgeSheet<void>(
    context,
    builder: (sheetContext) {
      final t = sheetContext.tokens;
      return SurgeSheet(
        title: title,
        trailing: const SizedBox.shrink(),
        noPad: true,
        body: Column(
          children: [
            for (final item in items)
              SurgePressable.row(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  item.onSelected?.call();
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: item.danger ? t.dangerBase : t.inkSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: SurgeText.body.copyWith(
                            color: item.danger ? t.dangerBase : t.inkPrimary,
                          ),
                        ),
                      ),
                      if (item.badge != null) SurgeBadge(item.badge!),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
        foot: _ModalButton(
          label: cancelLabel,
          background: t.bgInset,
          foreground: t.inkPrimary,
          onPressed: () => Navigator.of(sheetContext).pop(),
        ),
      );
    },
  );
}

class _ModalButton extends StatelessWidget {
  const _ModalButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SurgePressable(
      onPressed: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(context.tokens.radiusMd),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: SurgeText.headline.copyWith(color: foreground),
        ),
      ),
    );
  }
}
