import 'package:flutter/material.dart';
import 'account_screen.dart';

/// The "You" / settings tab. Universal across every Surge app.
/// Rows: Account, Manage Subscription, Notifications{{#notifications}} (on){{/notifications}},
/// Contact ({{support_email}}), FAQ, Privacy, Terms, Appearance, Version.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Account'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),
          const ListTile(title: Text('Manage subscription')),
          const ListTile(title: Text('Contact support')),
          const ListTile(title: Text('FAQ')),
          const ListTile(title: Text('Privacy Policy')),
          const ListTile(title: Text('Terms of Service')),
          const ListTile(title: Text('Appearance')),
          const AboutListTile(applicationName: '{{name}}'),
        ],
      ),
    );
  }
}
