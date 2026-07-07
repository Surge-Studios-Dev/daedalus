import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';
import 'surge_pressable.dart';

/// Catalog:
/// name: SurgeIconTile
/// category: rows
/// summary: A small rounded icon chip (circle or square) on an accent tint.
/// whenToUse: The leading glyph of a list/settings row, or a standalone badge.
/// tags: icon, tile, badge, leading
class SurgeIconTile extends StatelessWidget {
  const SurgeIconTile({
    super.key,
    required this.icon,
    this.square = false,
    this.size = 40,
    this.background,
    this.color,
  });

  final IconData icon;
  final bool square;
  final double size;
  final Color? background;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? t.accentTint,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(t.radiusSm) : null,
      ),
      child: Icon(icon, size: size / 2, color: color ?? t.accentBase),
    );
  }
}

/// Catalog:
/// name: SurgeListRow
/// category: rows
/// summary: A 56pt list row with optional leading icon/tile, title, subtitle, trailing, and chevron.
/// whenToUse: Rows in a scrolling list. For grouped iOS-style settings use SurgeGroupSection + SurgeGroupRow.
/// tags: row, list, tile, cell
class SurgeListRow extends StatelessWidget {
  const SurgeListRow({
    super.key,
    required this.title,
    this.sub,
    this.icon,
    this.iconTile,
    this.trailing,
    this.chevron = false,
    this.danger = false,
    this.accentTitle = false,
    this.onPressed,
  });

  final String title;
  final String? sub;

  /// A plain leading glyph (uses the secondary ink color).
  final IconData? icon;

  /// A leading [SurgeIconTile] glyph (accent-tinted chip). Overrides [icon].
  final IconData? iconTile;
  final Widget? trailing;
  final bool chevron;
  final bool danger;
  final bool accentTitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final titleColor = danger
        ? t.dangerBase
        : accentTitle
            ? t.accentBase
            : t.inkPrimary;

    return SurgePressable.row(
      onPressed: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: t.bgBase,
        child: Row(
          children: [
            if (iconTile != null) ...[
              SurgeIconTile(icon: iconTile!),
              const SizedBox(width: SurgeSpace.md),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 22,
                color: danger ? t.dangerBase : t.inkSecondary,
              ),
              const SizedBox(width: SurgeSpace.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SurgeText.headline.copyWith(color: titleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: SurgeText.footnote.copyWith(color: t.inkSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: SurgeSpace.xs),
              trailing!,
            ],
            if (chevron) ...[
              const SizedBox(width: SurgeSpace.xs),
              Icon(Icons.chevron_right, size: 20, color: t.inkTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Catalog:
/// name: SurgeGroupSection
/// category: rows
/// summary: An iOS-style grouped section — uppercase header, a card of rows with hairline dividers, and a footer.
/// whenToUse: Settings and form screens. Fill with SurgeGroupRow children.
/// tags: settings, group, section, form, list
class SurgeGroupSection extends StatelessWidget {
  const SurgeGroupSection({
    super.key,
    this.header,
    required this.children,
    this.footer,
  });

  final String? header;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: SurgeSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
              child: Text(
                header!.toUpperCase(),
                style: SurgeText.micro.copyWith(color: t.inkTertiary),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: t.bgBase,
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 16),
                      color: t.lineHairline,
                    ),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
              child: Text(
                footer!,
                style: SurgeText.footnote.copyWith(color: t.inkTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Catalog:
/// name: SurgeGroupRow
/// category: rows
/// summary: A row inside a SurgeGroupSection — optional square icon tile, title/subtitle, and a value, toggle, or chevron trailing.
/// whenToUse: Individual settings/preferences rows. Pass toggle for a switch row, value for a read-only value, chevron to drill in.
/// tags: settings, row, preference, toggle, switch
class SurgeGroupRow extends StatelessWidget {
  const SurgeGroupRow({
    super.key,
    required this.title,
    this.sub,
    this.value,
    this.icon,
    this.iconBackground,
    this.toggle,
    this.onToggle,
    this.chevron = false,
    this.danger = false,
    this.onPressed,
  });

  final String title;
  final String? sub;

  /// Read-only trailing value text.
  final String? value;
  final IconData? icon;
  final Color? iconBackground;

  /// When non-null, renders a trailing [Switch] reflecting this value.
  final bool? toggle;
  final ValueChanged<bool>? onToggle;
  final bool chevron;
  final bool danger;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SurgePressable.row(
      onPressed: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: t.bgBase,
        child: Row(
          children: [
            if (icon != null) ...[
              SurgeIconTile(
                icon: icon!,
                square: true,
                size: 30,
                background: iconBackground,
              ),
              const SizedBox(width: SurgeSpace.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SurgeText.body.copyWith(
                      color: danger ? t.dangerBase : t.inkPrimary,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      sub!,
                      style: SurgeText.footnote.copyWith(
                        color: t.inkSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: SurgeText.subhead.copyWith(color: t.inkSecondary),
              ),
            if (toggle != null) ...[
              const SizedBox(width: SurgeSpace.xs),
              Switch(
                value: toggle!,
                onChanged: onToggle,
                activeThumbColor: t.accentOn,
                activeTrackColor: t.accentBase,
              ),
            ],
            if (chevron) ...[
              const SizedBox(width: SurgeSpace.xs),
              Icon(Icons.chevron_right, size: 20, color: t.inkTertiary),
            ],
          ],
        ),
      ),
    );
  }
}
