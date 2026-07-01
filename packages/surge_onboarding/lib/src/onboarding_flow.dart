import 'package:flutter/material.dart';
import 'package:surge_ui/surge_ui.dart';

import 'onboarding_page.dart';

/// Catalog:
/// name: OnboardingFlow
/// category: systems
/// summary: A data-driven, themed onboarding carousel with progress dots, next/done, and optional skip.
/// whenToUse: First-run intro. Give it pages and an onDone; the app owns "seen" persistence and routing.
/// tags: onboarding, intro, carousel, walkthrough, first-run
///
/// A self-contained flow: it manages paging and its own buttons, and calls back
/// out on completion. It holds no persistence and does no navigation — the host
/// decides what "done" means (mark a flag, route home). Built entirely on
/// surge_ui, so it inherits the app's theme.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.pages,
    required this.onDone,
    this.onSkip,
    this.nextLabel = 'Next',
    this.doneLabel = 'Get started',
    this.skipLabel = 'Skip',
  });

  final List<OnboardingPage> pages;

  /// Fired when the user finishes the last page. The host persists + routes.
  final VoidCallback onDone;

  /// If provided, a Skip affordance is shown and calls this.
  final VoidCallback? onSkip;

  final String nextLabel;
  final String doneLabel;
  final String skipLabel;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == widget.pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: widget.onSkip != null && !_isLast
                    ? SurgeButton.ghost(widget.skipLabel, onPressed: widget.onSkip)
                    : null,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: widget.pages.length,
                itemBuilder: (context, i) => _Slide(page: widget.pages[i]),
              ),
            ),
            _Dots(count: widget.pages.length, index: _index, color: t.accentBase, off: t.lineStrong),
            const SizedBox(height: SurgeSpace.xl),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SurgeButton.primary(
                _isLast ? widget.doneLabel : widget.nextLabel,
                full: true,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.page});
  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.accentTint,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 44, color: t.accentBase),
          ),
          const SizedBox(height: SurgeSpace.xl),
          Text(page.title, style: SurgeText.title1, textAlign: TextAlign.center),
          const SizedBox(height: SurgeSpace.md),
          Text(
            page.body,
            style: SurgeText.body.copyWith(color: t.inkSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.color,
    required this.off,
  });

  final int count;
  final int index;
  final Color color;
  final Color off;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? color : off,
              borderRadius: BorderRadius.circular(SurgeRadii.pill),
            ),
          ),
      ],
    );
  }
}
