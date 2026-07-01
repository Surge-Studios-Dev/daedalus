import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:surge_ui/surge_ui.dart';

import 'appearance_controller.dart';

/// SET-01 · Settings ("You" tab). Grouped rows composed entirely from surge_ui.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider.notifier);
    ref.watch(appearanceProvider); // rebuild on change to refresh the label

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          SurgeGroupSection(
            header: 'Account',
            children: [
              SurgeGroupRow(
                title: 'Account',
                icon: Icons.person,
                chevron: true,
                onPressed: () => context.push('/account'),
              ),
              SurgeGroupRow(
                title: 'Manage subscription',
                icon: Icons.workspace_premium,
                chevron: true,
                onPressed: () => context.push('/paywall?source=settings'),
              ),
            ],
          ),
          SurgeGroupSection(
            header: 'Preferences',
            children: [
              SurgeGroupRow(
                title: 'Appearance',
                icon: Icons.brightness_6,
                value: appearance.label,
                onPressed: appearance.cycle,
              ),
            ],
          ),
          const SurgeGroupSection(
            header: 'Support',
            children: [
              SurgeGroupRow(
                title: 'Contact support',
                icon: Icons.mail_outline,
                chevron: true,
              ),
              SurgeGroupRow(
                title: 'FAQ',
                icon: Icons.help_outline,
                chevron: true,
              ),
            ],
          ),
          SurgeGroupSection(
            header: 'Legal',
            children: [
              SurgeGroupRow(
                title: 'Privacy policy',
                icon: Icons.lock_outline,
                chevron: true,
                onPressed: () => context.push('/legal/privacy'),
              ),
              SurgeGroupRow(
                title: 'Terms of service',
                icon: Icons.description_outlined,
                chevron: true,
                onPressed: () => context.push('/legal/terms'),
              ),
            ],
          ),
          const SurgeGroupSection(
            footer: 'Surge Foundation · v0.1.0 (1)',
            children: [
              SurgeGroupRow(title: 'Version', value: '0.1.0'),
            ],
          ),
        ],
      ),
    );
  }
}
