import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_ui/surge_ui.dart';

import '../auth/auth_controller.dart';

/// SET-02 · Account. Includes in-app account deletion, which is mandatory for
/// App Store approval.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<bool> _confirm(BuildContext context, String title, String message, String confirm) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(userEmailProvider);
    final auth = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          SurgeGroupSection(
            header: 'Sign-in',
            children: [
              SurgeGroupRow(title: 'Email', value: email ?? 'Guest'),
              const SurgeGroupRow(
                title: 'Change password',
                chevron: true,
              ),
            ],
          ),
          SurgeGroupSection(
            children: [
              SurgeGroupRow(
                title: 'Sign out',
                danger: true,
                onPressed: () async {
                  if (await _confirm(
                    context,
                    'Sign out?',
                    'You can sign back in any time.',
                    'Sign out',
                  )) {
                    await auth.signOut();
                  }
                },
              ),
            ],
          ),
          SurgeGroupSection(
            footer: 'Deleting your account removes your data permanently.',
            children: [
              SurgeGroupRow(
                title: 'Delete account',
                danger: true,
                onPressed: () async {
                  if (await _confirm(
                    context,
                    'Delete account?',
                    'This permanently removes your account and data. This cannot be undone.',
                    'Delete',
                  )) {
                    await auth.deleteAccount();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
