import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';

/// Account screen. Includes the mandatory in-app account deletion (Apple
/// 5.1.1(v)) with a confirm step.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently removes your account and data. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await AuthController().deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        children: [
          const ListTile(title: Text('Email')),
          const ListTile(title: Text('Change password')),
          ListTile(
            title: const Text('Sign out'),
            onTap: () => AuthController().signOut(),
          ),
          ListTile(
            title: const Text('Delete account',
                style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }
}
