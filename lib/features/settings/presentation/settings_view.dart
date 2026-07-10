import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme Mode'),
            subtitle: const Text('System Default / Dark Mode / Light Mode'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Download Location'),
            subtitle: const Text('/home/user/Downloads/OmniDL'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('Manage Plugins'),
            subtitle: const Text('View and configure download plugins'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About OmniDL'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
