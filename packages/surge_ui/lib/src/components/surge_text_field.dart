import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Catalog:
/// name: SurgeTextField
/// category: inputs
/// summary: Single- or multi-line text input with inset fill and focus/error/warning borders.
/// whenToUse: Any free-text entry. Set obscureText for passwords, multiline for notes.
/// variants: single-line, multiline, obscured
/// tags: input, textfield, form, text, password
///
/// Border precedence is error > warning > focus > none. Pass [onClear] to show a
/// trailing clear affordance when there is text, and [showVisibilityToggle] with
/// [obscureText] for a password reveal eye.
class SurgeTextField extends StatefulWidget {
  const SurgeTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.error = false,
    this.warning = false,
    this.autofocus = false,
    this.multiline = false,
    this.minLines = 3,
    this.maxLines,
    this.onChanged,
    this.onClear,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.onSubmitted,
    this.textInputAction,
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final bool error;
  final bool warning;
  final bool autofocus;
  final bool multiline;
  final int minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Silent hard cap on length (no counter UI).
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool showVisibilityToggle;
  final Iterable<String>? autofillHints;

  @override
  State<SurgeTextField> createState() => _SurgeTextFieldState();
}

class _SurgeTextFieldState extends State<SurgeTextField> {
  final _focus = FocusNode();
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final focused = _focus.hasFocus;
    final borderColor = widget.error
        ? t.dangerBase
        : widget.warning
        ? t.warningBase
        : focused
        ? t.accentBase
        : Colors.transparent;

    return AnimatedContainer(
      duration: t.motionFast,
      curve: t.curveStandard,
      constraints: widget.multiline
          ? null
          : const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: focused ? t.bgBase : t.bgInset,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: widget.textInputAction,
              keyboardType: widget.multiline
                  ? TextInputType.multiline
                  : widget.keyboardType,
              minLines: widget.multiline ? widget.minLines : 1,
              maxLines: widget.multiline ? widget.maxLines : 1,
              obscureText: widget.obscureText && !_revealed,
              autocorrect: !widget.obscureText,
              enableSuggestions: !widget.obscureText,
              autofillHints: widget.autofillHints,
              inputFormatters: [
                if (widget.maxLength != null)
                  LengthLimitingTextInputFormatter(widget.maxLength),
                ...?widget.inputFormatters,
              ],
              style: SurgeText.body.copyWith(color: t.inkPrimary),
              cursorColor: t.accentBase,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: SurgeText.body.copyWith(color: t.inkTertiary),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: widget.multiline ? 12 : 13,
                ),
              ),
            ),
          ),
          if (widget.showVisibilityToggle && widget.obscureText)
            Padding(
              padding: const EdgeInsets.only(right: SurgeSpace.sm),
              child: GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    _revealed ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: t.inkTertiary,
                  ),
                ),
              ),
            ),
          if (widget.onClear != null &&
              (widget.controller?.text.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(right: SurgeSpace.sm),
              child: GestureDetector(
                onTap: widget.onClear,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.lineStrong,
                  ),
                  child: Icon(Icons.close, size: 14, color: t.bgBase),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Catalog:
/// name: SurgeSearchField
/// category: inputs
/// summary: A 44pt search field with a leading magnifier and optional clear.
/// whenToUse: Filtering or searching a list. For general text entry use SurgeTextField.
/// tags: input, search, filter
class SurgeSearchField extends StatelessWidget {
  const SurgeSearchField({
    super.key,
    this.controller,
    this.placeholder = 'Search',
    this.autofocus = false,
    this.onChanged,
    this.onClear,
    this.maxLength = 60,
  });

  final TextEditingController? controller;
  final String placeholder;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.bgInset,
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: t.inkTertiary),
          const SizedBox(width: SurgeSpace.sm),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              inputFormatters: [
                if (maxLength != null)
                  LengthLimitingTextInputFormatter(maxLength),
              ],
              style: SurgeText.body.copyWith(color: t.inkPrimary),
              cursorColor: t.accentBase,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: SurgeText.body.copyWith(color: t.inkTertiary),
              ),
            ),
          ),
          if (onClear != null && (controller?.text.isNotEmpty ?? false))
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close, size: 18, color: t.inkTertiary),
            ),
        ],
      ),
    );
  }
}
