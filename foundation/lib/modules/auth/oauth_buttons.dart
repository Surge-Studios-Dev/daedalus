import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:surge_ui/surge_ui.dart';

/// Provider-branded OAuth buttons (Ladle's shipped implementation, promoted
/// after Ember re-derived them as themed secondary buttons and the user
/// flagged them as non-native). Apple's HIG and Google's brand guidelines
/// fix the button surface, glyph, and text color - these deliberately do
/// NOT theme with the app. A SurgeButton.secondary with Icons.g_mobiledata
/// is the canonical wrong version: it reads as non-native and risks
/// brand/store review. The app's only knob is which providers exist -
/// never how they look.
class OAuthButton extends StatelessWidget {
  const OAuthButton._({
    required this.leading,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.border = false,
  });

  /// Sign in with Apple, per HIG: black surface, white text, and
  /// Material's [Icons.apple] - the actual Apple logo glyph, not a
  /// stylized fruit.
  factory OAuthButton.apple({
    required VoidCallback? onPressed,
    String label = 'Continue with Apple',
  }) =>
      OAuthButton._(
        leading: const Icon(Icons.apple, size: 22, color: Colors.white),
        label: label,
        onPressed: onPressed,
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
      );

  /// Sign in with Google, per brand guidance: white surface in BOTH
  /// modes so the multi-color G stays legible, fixed dark-gray text,
  /// hairline border.
  factory OAuthButton.google({
    required VoidCallback? onPressed,
    String label = 'Continue with Google',
  }) =>
      OAuthButton._(
        leading: const _GoogleGLogo(size: 20),
        label: label,
        onPressed: onPressed,
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color(0xFF1F1F1F),
        border: true,
      );

  final Widget leading;
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  border ? Border.all(color: const Color(0xFFDADCE0)) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: 10),
                // Flexible so wide fonts (test fallback glyphs, AX text
                // scale) shrink the label instead of overflowing the row.
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SurgeText.headline.copyWith(color: foregroundColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Google's brand "G" mark - the canonical multi-color SVG from Google's
/// brand guidelines, rendered inline so no asset file ships.
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 20});

  final double size;

  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">'
      '<path fill="#4285F4" d="M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 5.08-4.39 6.64v5.52h7.11c4.16-3.83 6.56-9.47 6.56-16.17z"/>'
      '<path fill="#34A853" d="M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 2.1-7.45 2.1-5.73 0-10.58-3.87-12.31-9.07H4.34v5.7C7.96 41.07 15.4 46 24 46z"/>'
      '<path fill="#FBBC05" d="M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34C2.85 17.09 2 20.45 2 24c0 3.55.85 6.91 2.34 9.88l7.35-5.7z"/>'
      '<path fill="#EA4335" d="M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 24 2 15.4 2 7.96 6.93 4.34 14.12l7.35 5.7c1.73-5.2 6.58-9.07 12.31-9.07z"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}
