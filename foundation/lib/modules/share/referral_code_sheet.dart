import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_share/surge_share.dart';
import 'package:surge_ui/surge_ui.dart';

import 'share.dart';

/// SET-04 · "Have a code?" sheet. Manual entry is the fallback when the
/// invite arrived out-of-band (screenshot, spoken); shares carried in-app
/// auto-redeem silently instead. Server rejections come back with codes -
/// map them to friendly copy, never a raw error.
Future<void> showReferralCodeSheet(BuildContext context, WidgetRef ref) {
  return showSurgeSheet<void>(
    context,
    builder: (sheetContext) => const _ReferralCodeSheetBody(),
  );
}

class _ReferralCodeSheetBody extends ConsumerStatefulWidget {
  const _ReferralCodeSheetBody();

  @override
  ConsumerState<_ReferralCodeSheetBody> createState() =>
      _ReferralCodeSheetBodyState();
}

class _ReferralCodeSheetBodyState
    extends ConsumerState<_ReferralCodeSheetBody> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _messages = <String, String>{
    'not-found': "We couldn't find that code.",
    'own-code': "That's your own code. Share it with a friend instead.",
    'already-redeemed': 'This account has already used an invite code.',
    'account-too-old': 'Invite codes are for new accounts.',
  };

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final days = await ref.read(shareServiceProvider).redeem(code);
      ref.invalidate(referralStatusProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSurgeToast(
        context,
        message: days > 0
            ? 'Invite applied. You got $days free days.'
            : 'Invite applied.',
      );
    } on ShareBackendException catch (e) {
      setState(() {
        _busy = false;
        _error = _messages[e.code] ?? "That code didn't work.";
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Something went wrong. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurgeSheet(
      title: 'Enter invite code',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SurgeTextField(
            controller: _controller,
            placeholder: 'ABC-1234',
            autofocus: true,
            error: _error != null,
            onSubmitted: (_) => _redeem(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: SurgeText.footnote.copyWith(
                color: context.tokens.dangerBase,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SurgeButton.primary(
            'Redeem',
            full: true,
            loading: _busy,
            onPressed: _busy ? null : _redeem,
          ),
        ],
      ),
    );
  }
}
