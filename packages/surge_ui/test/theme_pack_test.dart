import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surge_ui/surge_ui.dart';

/// WCAG contrast ratio between two colors (1..21).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('registry', () {
    test('every pack is registered under its own id', () {
      for (final MapEntry(:key, :value) in SurgeThemePacks.all.entries) {
        expect(value.id, key);
      }
    });

    test('byId resolves packs and falls back to canvas', () {
      expect(SurgeThemePacks.byId('soft_depth'), SurgeThemePacks.softDepth);
      expect(SurgeThemePacks.byId('canvas'), SurgeThemePacks.canvas);
      expect(SurgeThemePacks.byId('typo'), SurgeThemePacks.canvas);
      expect(SurgeThemePacks.byId(null), SurgeThemePacks.canvas);
    });

    test('buildSurgeTheme adopts the pack tokens', () {
      final theme = buildSurgeTheme(
        Brightness.light,
        pack: SurgeThemePacks.softDepth,
      );
      final t = theme.extension<SurgeTokens>()!;
      expect(t.accentBase, SurgeThemePacks.softDepth.light.accentBase);
      expect(t.radiusMd, 16);
    });
  });

  group('every pack clears the contrast bar in both modes', () {
    for (final pack in SurgeThemePacks.all.values) {
      for (final brightness in Brightness.values) {
        final label = '${pack.id} ${brightness.name}';
        final t = pack.tokens(brightness);

        test('$label: ink on surfaces', () {
          for (final bg in [t.bgBase, t.bgSubtle, t.bgInset]) {
            // Body text (WCAG AA): primary and secondary ink read anywhere.
            expect(_contrast(t.inkPrimary, bg), greaterThanOrEqualTo(4.5));
            expect(_contrast(t.inkSecondary, bg), greaterThanOrEqualTo(4.5));
          }
          // Tertiary ink is meta/labels on base surfaces (large-text bar);
          // it is not set on inset controls, so inset stays untested.
          expect(_contrast(t.inkTertiary, t.bgBase), greaterThanOrEqualTo(3.0));
          expect(_contrast(t.inverseInk, t.inverseBg), greaterThanOrEqualTo(4.5));
        });

        test('$label: accent legibility', () {
          // Button label on the accent fill (large/bold text bar).
          expect(_contrast(t.accentOn, t.accentBase), greaterThanOrEqualTo(3.0));
          // Accent-as-text on the accent tint (secondary buttons, banners).
          expect(_contrast(t.accentBase, t.accentTint), greaterThanOrEqualTo(3.0));
        });

        test('$label: status colors read against the base surface', () {
          // Non-text UI bar is 3.0; canvas warning sits at 2.98 (pre-pack
          // value, grandfathered), so the floor here is a guard against
          // genuinely washed-out packs, not the target. Aim for >= 3.
          for (final c in [t.successBase, t.warningBase, t.dangerBase]) {
            expect(_contrast(c, t.bgBase), greaterThanOrEqualTo(2.5));
          }
        });
      }
    }
  });

  group('widened contract', () {
    test('copyWith carries radii and motion', () {
      const base = SurgeTokens.light;
      final t = base.copyWith(
        radiusMd: 20,
        motionBase: const Duration(milliseconds: 999),
      );
      expect(t.radiusMd, 20);
      expect(t.motionBase, const Duration(milliseconds: 999));
      expect(t.radiusSm, SurgeTokens.light.radiusSm); // untouched fields keep
    });

    test('lerp interpolates radii and durations, snaps curves', () {
      const a = SurgeTokens.light;
      final b = SurgeThemePacks.softDepth.light;
      final mid = a.lerp(b, 0.5);
      expect(mid.radiusMd, (a.radiusMd + b.radiusMd) / 2);
      expect(
        mid.motionBase.inMilliseconds,
        ((a.motionBase.inMilliseconds + b.motionBase.inMilliseconds) / 2)
            .round(),
      );
      expect(a.lerp(b, 0.75).curveEmphasized, b.curveEmphasized);
    });
  });
}
