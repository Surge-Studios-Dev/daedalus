import 'package:flutter/material.dart';

/// Sign-in / sign-up for {{name}}.
/// SKELETON: lay out email fields + the enabled social buttons. Sign in with
/// Apple is required to appear whenever any social provider is shown (4.8).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: const Center(child: Text('Auth UI - wire AuthController')),
    );
  }
}
