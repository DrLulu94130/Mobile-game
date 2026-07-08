import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/locale_controller.dart';
import '../controllers/theme_controller.dart';

/// App settings: theme, language, packs, premium and account actions.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          _SectionHeader(l.appearance),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (m) =>
                ref.read(themeControllerProvider.notifier).set(m!),
            title: Text(l.matchSystem),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (m) =>
                ref.read(themeControllerProvider.notifier).set(m!),
            title: Text(l.light),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (m) =>
                ref.read(themeControllerProvider.notifier).set(m!),
            title: Text(l.dark),
          ),
          const Divider(),
          _SectionHeader(l.language),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.language),
            trailing: DropdownButton<Locale?>(
              value: locale,
              underline: const SizedBox.shrink(),
              onChanged: (value) =>
                  ref.read(localeControllerProvider.notifier).set(value),
              items: [
                DropdownMenuItem(value: null, child: Text(l.systemDefault)),
                const DropdownMenuItem(
                  value: Locale('en'),
                  child: Text('English'),
                ),
                const DropdownMenuItem(
                  value: Locale('fr'),
                  child: Text('Français'),
                ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(l.content),
          ListTile(
            leading: const Icon(Icons.pets_outlined),
            title: Text(l.characterPacks),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.packs),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l.premiumTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.premium),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(l.achievements),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.badges),
          ),
          const Divider(),
          _SectionHeader(l.account),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(l.signOut),
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
