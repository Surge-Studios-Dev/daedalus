import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:surge_ui/surge_ui.dart';

import 'auth_controller.dart';
import 'oauth_buttons.dart';

/// AUTH-01 · Sign in. Email + social + guest. Sign in with Apple is always
/// offered whenever any social provider is enabled (Guideline 4.8).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final auth = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome back', style: SurgeText.title1),
                  const SizedBox(height: SurgeSpace.xs),
                  Text(
                    'Sign in to continue.',
                    style: SurgeText.body.copyWith(color: t.inkSecondary),
                  ),
                  const SizedBox(height: SurgeSpace.xl),
                  SurgeTextField(
                    controller: _email,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: SurgeSpace.md),
                  SurgeTextField(
                    controller: _password,
                    placeholder: 'Password',
                    obscureText: true,
                    showVisibilityToggle: true,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: SurgeSpace.lg),
                  SurgeButton.primary(
                    'Sign in',
                    full: true,
                    loading: _busy,
                    onPressed: () => _run(
                      () => auth.signInWithEmail(_email.text, _password.text),
                    ),
                  ),
                  const SizedBox(height: SurgeSpace.md),
                  _OrDivider(),
                  const SizedBox(height: SurgeSpace.md),
                  // Provider-branded, never themed (see oauth_buttons.dart):
                  // Apple/Google fix how these buttons look.
                  OAuthButton.apple(
                    onPressed:
                        _busy ? null : () => _run(auth.signInWithApple),
                  ),
                  const SizedBox(height: SurgeSpace.sm),
                  OAuthButton.google(
                    onPressed:
                        _busy ? null : () => _run(auth.signInWithGoogle),
                  ),
                  const SizedBox(height: SurgeSpace.lg),
                  SurgeButton.ghost(
                    'Create an account',
                    onPressed: () => context.push('/signup'),
                  ),
                  SurgeButton.ghost(
                    'Continue as guest',
                    onPressed: auth.continueAsGuest,
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

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Expanded(child: Divider(color: t.lineHairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: SurgeText.footnote.copyWith(color: t.inkTertiary),
          ),
        ),
        Expanded(child: Divider(color: t.lineHairline)),
      ],
    );
  }
}
