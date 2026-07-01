import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:surge_ui/surge_ui.dart';

import 'auth_controller.dart';

/// AUTH-02 · Create account.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final auth = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
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
                  Text('Create your account', style: SurgeText.title1),
                  const SizedBox(height: SurgeSpace.xs),
                  Text(
                    'It only takes a moment.',
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
                    placeholder: 'Choose a password',
                    obscureText: true,
                    showVisibilityToggle: true,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: SurgeSpace.lg),
                  SurgeButton.primary(
                    'Create account',
                    full: true,
                    loading: _busy,
                    onPressed: () async {
                      setState(() => _busy = true);
                      await auth.signUpWithEmail(_email.text, _password.text);
                      if (mounted) setState(() => _busy = false);
                    },
                  ),
                  const SizedBox(height: SurgeSpace.sm),
                  SurgeButton.ghost(
                    'I already have an account',
                    onPressed: () => context.pop(),
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
