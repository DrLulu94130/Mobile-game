import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';

/// App settings: theme, packs, premium and account actions.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (m) =>
                ref.read(themeControllerProvider.notifier).set(m!),
            title: const Text('Match system'),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (m) =>
                ref.read(themeControllerProvider.notifier).set(m!),
            title: const Text('Light'),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (m) =>
                ref.read(themeControllerProvider.notifier).set(m!),
            title: const Text('Dark'),
          ),
          const Divider(),
          const _SectionHeader('Content'),
          ListTile(
            leading: const Icon(Icons.pets_outlined),
            title: const Text('Character packs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.packs),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Inkognito Premium'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.premium),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Achievements'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.badges),
          ),
          const Divider(),
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sign out'),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go(Routes.signIn);
            },
          ),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Inkognito v1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
